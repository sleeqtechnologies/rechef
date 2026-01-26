import 'dart:async';
import 'package:share_handler/share_handler.dart';

/// Service to handle shared content from other apps (YouTube, TikTok, etc.)
class ShareHandlerService {
  ShareHandlerService() : _handler = ShareHandlerPlatform.instance;

  final ShareHandlerPlatform _handler;
  StreamSubscription<SharedMedia>? _subscription;

  Future<void> initialize({
    required Function(SharedMedia) onSharedContent,
  }) async {
    final initialMedia = await _handler.getInitialSharedMedia();
    if (initialMedia != null) {
      onSharedContent(initialMedia);
    }

    _subscription = _handler.sharedMediaStream.listen((media) {
      onSharedContent(media);
    });
  }

  void dispose() {
    _subscription?.cancel();
  }

  /// Extract URL from shared media
  /// Checks content (text) and attachments for URLs
  static String? extractUrl(SharedMedia media) {
    if (media.content != null) {
      final content = media.content!.trim();
      if (_isUrl(content)) {
        return content;
      }
    }

    if (media.attachments != null) {
      for (final attachment in media.attachments!) {
        if (attachment?.path != null) {
          final path = attachment!.path!;
          if (path.endsWith('.txt') || path.endsWith('.url')) {
            if (_isUrl(path)) {
              return path;
            }
          }
        }
      }
    }

    return null;
  }

  /// Extract image path from shared media
  static String? extractImagePath(SharedMedia media) {
    if (media.attachments != null) {
      for (final attachment in media.attachments!) {
        if (attachment?.type == SharedAttachmentType.image &&
            attachment?.path != null) {
          return attachment!.path;
        }
      }
    }
    return null;
  }

  static bool _isUrl(String text) {
    try {
      final uri = Uri.parse(text);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }
}
