import 'dart:io';
import 'package:image_picker/image_picker.dart';

// Note: XFile is from image_picker package

class ImageUtils {
  ImageUtils._();

  static final ImagePicker _picker = ImagePicker();

  static Future<XFile?> pickImageFromGallery() async {
    return await _picker.pickImage(source: ImageSource.gallery);
  }

  static Future<XFile?> takePhoto() async {
    return await _picker.pickImage(source: ImageSource.camera);
  }

  static Future<List<XFile>> pickMultipleImages() async {
    return await _picker.pickMultiImage();
  }

  static File? xFileToFile(XFile xFile) {
    return File(xFile.path);
  }
}
