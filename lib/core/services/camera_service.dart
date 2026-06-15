import 'package:image_picker/image_picker.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

class CameraService {
  static final ImagePicker _picker = ImagePicker();

  /// Opens the device camera and lets the user take a picture
  /// Returns the file path of the captured image, or null if cancelled
  static Future<String?> openCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        return image.path;
      }
      return null;
    } catch (e) {
      AppLogger.d('Error opening camera: $e');
      return null;
    }
  }
}
