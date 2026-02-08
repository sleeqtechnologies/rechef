import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_handler/share_handler.dart';

import 'app/recipe_import/pending_jobs_provider.dart';
import 'core/routing/app_router.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeShareHandler();
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
    final router = ref.read(routerProvider);

    final url = ShareHandlerService.extractUrl(media);
    final imagePath = ShareHandlerService.extractImagePath(media);

    String? targetPath;
    if (url != null) {
      final uri = Uri(path: '/recipes/import', queryParameters: {'url': url});
      targetPath = uri.toString();
    } else if (imagePath != null) {
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
        }
      } catch (e) {
        // Content is not a URL, ignore
      }
    }

    if (targetPath != null) {
      router.go(targetPath);
    }
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
      child: MaterialApp.router(
        title: 'Rechef',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        routerConfig: router,
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ref.read(shareHandlerServiceProvider).dispose();
    super.dispose();
  }
}
