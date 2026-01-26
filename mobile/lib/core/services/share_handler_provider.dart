import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'share_handler_service.dart';

final shareHandlerServiceProvider = Provider<ShareHandlerService>((ref) {
  return ShareHandlerService();
});
