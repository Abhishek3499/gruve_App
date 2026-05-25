import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

enum AuthLoadingKey {
  login,
  signup,
  phoneLogin,
  forgotPassword,
  otp,
  resetPassword,
  completeProfile,
}

class AuthUiProvider extends ChangeNotifier {
  final Set<AuthLoadingKey> _loading = <AuthLoadingKey>{};
  final Map<String, String?> _errors = <String, String?>{};

  bool _useEmail = true;
  bool _genderTouched = false;
  String? _selectedGender;
  XFile? _selectedProfileImage;
  Uint8List? _selectedProfileImageBytes;

  bool isLoading(AuthLoadingKey key) => _loading.contains(key);
  String? error(String key) => _errors[key];

  bool get useEmail => _useEmail;
  bool get genderTouched => _genderTouched;
  String? get selectedGender => _selectedGender;
  XFile? get selectedProfileImage => _selectedProfileImage;
  Uint8List? get selectedProfileImageBytes => _selectedProfileImageBytes;

  bool get isSelectedProfileMediaVideo {
    final path = _selectedProfileImage?.path.toLowerCase() ?? '';
    return path.endsWith('.mp4') || path.endsWith('.mov');
  }

  String? get genderError =>
      _genderTouched && _selectedGender == null ? 'Please select gender' : null;

  void setLoading(AuthLoadingKey key, bool value) {
    final changed = value ? _loading.add(key) : _loading.remove(key);
    if (changed) notifyListeners();
  }

  void setError(String key, String? value) {
    if (_errors[key] == value) return;
    _errors[key] = value;
    notifyListeners();
  }

  void setErrors(Map<String, String?> errors) {
    var changed = false;
    for (final entry in errors.entries) {
      if (_errors[entry.key] != entry.value) {
        _errors[entry.key] = entry.value;
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  void setContactMode(bool useEmail) {
    if (_useEmail == useEmail) return;
    _useEmail = useEmail;
    notifyListeners();
  }

  void touchGender() {
    if (_genderTouched) return;
    _genderTouched = true;
    notifyListeners();
  }

  void setGender(String? gender) {
    if (_selectedGender == gender) return;
    _selectedGender = gender;
    notifyListeners();
  }

  void setProfileImage(XFile image, Uint8List bytes) {
    _selectedProfileImage = image;
    _selectedProfileImageBytes = bytes;
    notifyListeners();
  }

  void resetSignup() {
    _selectedGender = null;
    _genderTouched = false;
    _useEmail = true;
    for (final key in const [
      'signup_name',
      'signup_identifier',
      'signup_password',
      'signup_confirm_password',
    ]) {
      _errors.remove(key);
    }
    notifyListeners();
  }

  void resetLogin() {
    _loading.remove(AuthLoadingKey.login);
    _errors.remove('login_email');
    _errors.remove('login_password');
    notifyListeners();
  }

  void resetForgotPassword() {
    _loading.remove(AuthLoadingKey.forgotPassword);
    _errors.remove('forgot_email');
    notifyListeners();
  }

  void resetPhoneLogin() {
    _loading.remove(AuthLoadingKey.phoneLogin);
    _errors.remove('phone_login_phone');
    notifyListeners();
  }

  void resetCompleteProfile() {
    _loading.remove(AuthLoadingKey.completeProfile);
    _selectedProfileImage = null;
    _selectedProfileImageBytes = null;
    notifyListeners();
  }

  void resetOtp() {
    _loading.remove(AuthLoadingKey.otp);
    notifyListeners();
  }

  void resetResetPassword() {
    _loading.remove(AuthLoadingKey.resetPassword);
    notifyListeners();
  }
}
