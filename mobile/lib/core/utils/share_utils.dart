import 'package:share_plus/share_plus.dart';

class ShareUtils {
  ShareUtils._();

  static Future<void> shareText(String text, {String? subject}) async {
    await Share.share(text, subject: subject);
  }

  static Future<void> shareFile(String filePath, {String? subject}) async {
    await Share.shareXFiles([XFile(filePath)], subject: subject);
  }

  static Future<void> shareFiles(
    List<String> filePaths, {
    String? subject,
  }) async {
    await Share.shareXFiles(
      filePaths.map((path) => XFile(path)).toList(),
      subject: subject,
    );
  }
}
