import 'package:image_picker/image_picker.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

class ImagePickerService {
  static final ImagePicker _imagePicker = ImagePicker();
  static bool _androidPickerConfigured = false;

  static void _configureAndroidPicker() {
    if (_androidPickerConfigured) return;

    final implementation = ImagePickerPlatform.instance;
    if (implementation is ImagePickerAndroid) {
      implementation.useAndroidPhotoPicker = true;
    }

    _androidPickerConfigured = true;
  }

  static Future<bool> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  static Future<XFile?> pickImageFromCamera() async {
    try {
      // Request camera permission
      final hasPermission = await _requestCameraPermission();
      if (!hasPermission) {
        AppLogger.d('Camera permission denied');
        return null;
      }

      final image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
        maxWidth: 600,
        maxHeight: 600,
      );

      AppLogger.d('Camera image picked: ${image?.path}');
      return image;
    } catch (e) {
      AppLogger.d('Error picking image from camera: $e');
      return null;
    }
  }

  static Future<XFile?> pickMediaFromGallery() async {
    try {
      _configureAndroidPicker();

      final media = await _imagePicker.pickMedia(
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );

      AppLogger.d('Gallery media picked: ${media?.path}');
      return media;
    } catch (e) {
      AppLogger.d('Error picking media from gallery: $e');
      return null;
    }
  }

  static Future<XFile?> pickImageFromGallery() async {
    try {
      _configureAndroidPicker();

      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );

      AppLogger.d('Gallery image picked: ${image?.path}');
      return image;
    } catch (e) {
      AppLogger.d('Error picking image from gallery: $e');
      return null;
    }
  }
}
