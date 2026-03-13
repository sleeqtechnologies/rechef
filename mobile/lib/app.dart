import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:share_handler/share_handler.dart';

import 'app/auth/providers/auth_providers.dart';
import 'app/recipe_import/pending_jobs_provider.dart';
import 'app/subscription/subscription_provider.dart';
import 'core/routing/app_router.dart';
import 'core/routing/deep_link_handler.dart';
import 'core/services/firebase_analytics_provider.dart';
import 'core/services/share_handler_service.dart';
import 'core/services/share_handler_provider.dart';
import 'core/theme/app_theme.dart';

class RechefApp extends ConsumerStatefulWidget {
  const RechefApp({super.key});

  @override
  ConsumerState<RechefApp> createState() => _RechefAppState();
}

class _RechefAppState extends ConsumerState<RechefApp>
    with WidgetsBindingObserver {
  AppLinks? _appLinks;
  StreamSubscription<Uri>? _deepLinkSubscription;
  String? _lastDeepLink;
  DateTime? _lastDeepLinkHandledAt;
  String? _lastShareSignature;
  DateTime? _lastShareHandledAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeDeepLinks();
    _initializeShareHandler();
    _syncRevenueCatUser();
  }

  void _initializeDeepLinks() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _appLinks ??= AppLinks();

      try {
        final initialLink = await _appLinks!.getInitialLink();
        await _handleIncomingDeepLink(initialLink);
      } catch (error) {
        debugPrint('[RechefApp] Failed to read initial app link: $error');
      }

      await _deepLinkSubscription?.cancel();
      _deepLinkSubscription = _appLinks!.uriLinkStream.listen(
        (uri) {
          unawaited(_handleIncomingDeepLink(uri));
        },
        onError: (Object error) {
          debugPrint('[RechefApp] App link stream error: $error');
        },
      );
    });
  }

  Future<void> _handleIncomingDeepLink(Uri? uri) async {
    if (!mounted || uri == null || _isDuplicateDeepLink(uri)) {
      return;
    }

    final location = DeepLinkHandler.locationForAppDeepLink(uri);
    if (location == null) {
      return;
    }

    final router = ref.read(routerProvider);
    router.go(location);
  }

  void _syncRevenueCatUser() {
    ref.listenManual(authStateProvider, (previous, next) async {
      final user = next.value;
      final analytics = ref.read(firebaseAnalyticsProvider);

      try {
        if (user != null) {
          await Purchases.logIn(user.uid);
        } else if (previous?.value != null) {
          await Purchases.logOut();
        }
      } catch (e) {
        debugPrint('[RechefApp] RevenueCat user sync error: $e');
      }

      try {
        await analytics.setUserId(id: user?.uid);
      } catch (e) {
        debugPrint('[RechefApp] Analytics user sync error: $e');
      }

      try {
        if (user != null) {
          await Posthog().identify(
            userId: user.uid,
            userProperties: {
              if (user.email != null) 'email': user.email!,
              if (user.displayName != null) 'name': user.displayName!,
              'is_anonymous': user.isAnonymous,
            },
          );
        } else if (previous?.value != null) {
          await Posthog().reset();
        }
      } catch (e) {
        debugPrint('[RechefApp] PostHog user sync error: $e');
      }

      ref.invalidate(subscriptionProvider);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(pendingJobsProvider.notifier).checkJobs();
    }
  }

  void _initializeShareHandler() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final shareService = ref.read(shareHandlerServiceProvider);
      shareService.initialize(
        onSharedContent: (media) {
          _handleSharedContent(media);
        },
      );
    });
  }

  void _handleSharedContent(SharedMedia media) {
    if (_isDuplicateShareEvent(media)) {
      return;
    }

    final router = ref.read(routerProvider);
    final analytics = ref.read(appAnalyticsProvider);

    final url = ShareHandlerService.extractUrl(media);
    final imagePath = ShareHandlerService.extractImagePath(media);

    String? targetPath;
    var contentType = 'unsupported';
    if (url != null) {
      contentType = 'url';
      final uri = Uri(path: '/recipes/import', queryParameters: {'url': url});
      targetPath = uri.toString();
    } else if (imagePath != null) {
      contentType = 'image';
      final uri = Uri(
        path: '/recipes/import',
        queryParameters: {'image': imagePath},
      );
      targetPath = uri.toString();
    } else if (media.content != null) {
      final content = media.content!.trim();
      try {
        final uri = Uri.parse(content);
        if (uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https')) {
          final importUri = Uri(
            path: '/recipes/import',
            queryParameters: {'url': content},
          );
          targetPath = importUri.toString();
          contentType = 'url';
        }
      } catch (_) {
        // Ignore non-URL share text.
      }
    }

    analytics.logShareContentReceived(
      contentType: contentType,
      routedToImport: targetPath != null,
    );

    if (targetPath != null) {
      router.go(targetPath);
    }
  }

  bool _isDuplicateShareEvent(SharedMedia media) {
    final attachments = media.attachments ?? const [];
    final attachmentSignature = attachments
        .map((attachment) => '${attachment?.type}:${attachment?.path}')
        .join('|');
    final signature = '${media.content}|$attachmentSignature';
    final now = DateTime.now();

    final isDuplicate =
        _lastShareSignature == signature &&
        _lastShareHandledAt != null &&
        now.difference(_lastShareHandledAt!) < const Duration(seconds: 2);

    _lastShareSignature = signature;
    _lastShareHandledAt = now;
    return isDuplicate;
  }

  bool _isDuplicateDeepLink(Uri uri) {
    final signature = uri.toString();
    final now = DateTime.now();

    final isDuplicate =
        _lastDeepLink == signature &&
        _lastDeepLinkHandledAt != null &&
        now.difference(_lastDeepLinkHandledAt!) < const Duration(seconds: 2);

    _lastDeepLink = signature;
    _lastDeepLinkHandledAt = now;
    return isDuplicate;
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: PostHogWidget(
          child: MaterialApp.router(
            title: 'Rechef',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            themeMode: ThemeMode.light,
            routerConfig: router,
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _deepLinkSubscription?.cancel();
    ref.read(shareHandlerServiceProvider).dispose();
    super.dispose();
  }
}
