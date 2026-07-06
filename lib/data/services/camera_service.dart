import 'dart:io';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraService extends GetxService {
  final ImagePicker _picker = ImagePicker();

  Future<File?> pickFromCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      Get.snackbar(
        'Permission Required',
        'Camera permission is needed to scan cards.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    }

    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 1200,
      maxHeight: 1200,
    );
    if (image == null) return null;
    return File(image.path);
  }

  /// Pick image from gallery
  Future<File?> pickFromGallery() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
      maxHeight: 1200,
    );
    if (image == null) return null;
    return File(image.path);
  }
}
