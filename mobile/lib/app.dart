import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_handler/share_handler.dart';

import 'core/routing/app_router.dart';
import 'core/services/share_handler_service.dart';
import 'core/services/share_handler_provider.dart';
import 'core/theme/app_theme.dart';

class RechefApp extends ConsumerStatefulWidget {
  const RechefApp({super.key});

  @override
  ConsumerState<RechefApp> createState() => _RechefAppState();
}

class _RechefAppState extends ConsumerState<RechefApp> {
  @override
  void initState() {
    super.initState();
    _initializeShareHandler();
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

    // Extract URL or image from shared content
    final url = ShareHandlerService.extractUrl(media);
    final imagePath = ShareHandlerService.extractImagePath(media);

    // Build URI for navigation
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
    ref.read(shareHandlerServiceProvider).dispose();
    super.dispose();
  }
}
