import 'dart:async';

import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

enum AuthLoadingKey {
  login,
  signup,
  phoneLogin,
  forgotPassword,
  otp,
  resendOtp,
  resetPassword,
  completeProfile,
}

class AuthUiProvider extends ChangeNotifier {
  final Set<AuthLoadingKey> _loading = <AuthLoadingKey>{};
  final Map<String, String?> _errors = <String, String?>{};
  final Map<String, Timer> _validationDebounceTimers = <String, Timer>{};
  static const Duration _validationDebounce = Duration(milliseconds: 200);

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

  String? get genderError => _genderTouched && _selectedGender == null
      ? 'Please select your gender'
      : null;

  void setLoading(AuthLoadingKey key, bool value) {
    final changed = value ? _loading.add(key) : _loading.remove(key);
    if (changed) notifyListeners();
  }

  void setError(String key, String? value) {
    if (_errors[key] == value) return;
    _errors[key] = value;
    notifyListeners();
  }

  /// Debounced field validation to avoid rebuilding auth screens on every keystroke.
  void setValidationError(String key, String? value) {
    _validationDebounceTimers[key]?.cancel();
    if (value == null) {
      setError(key, null);
      return;
    }

    _validationDebounceTimers[key] = Timer(_validationDebounce, () {
      setError(key, value);
    });
  }

  void _cancelValidationTimers([Iterable<String>? keys]) {
    if (keys == null) {
      for (final timer in _validationDebounceTimers.values) {
        timer.cancel();
      }
      _validationDebounceTimers.clear();
      return;
    }

    for (final key in keys) {
      _validationDebounceTimers.remove(key)?.cancel();
    }
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

  bool _removeError(String key) {
    final hadKey = _errors.containsKey(key);
    _errors.remove(key);
    return hadKey;
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
    var changed = false;
    changed = _selectedGender != null || changed;
    changed = _genderTouched || changed;
    changed = _useEmail != true || changed;

    _selectedGender = null;
    _genderTouched = false;
    _useEmail = true;
    _cancelValidationTimers(const [
      'signup_name',
      'signup_identifier',
      'signup_password',
      'signup_confirm_password',
    ]);
    for (final key in const [
      'signup_name',
      'signup_identifier',
      'signup_password',
      'signup_confirm_password',
    ]) {
      changed = _removeError(key) || changed;
    }
    if (changed) notifyListeners();
  }

  void resetLogin() {
    var changed = _loading.remove(AuthLoadingKey.login);
    _cancelValidationTimers(const ['login_email', 'login_password']);
    changed = _removeError('login_email') || changed;
    changed = _removeError('login_password') || changed;
    if (changed) notifyListeners();
  }

  void resetForgotPassword() {
    var changed = _loading.remove(AuthLoadingKey.forgotPassword);
    changed = _removeError('forgot_email') || changed;
    if (changed) notifyListeners();
  }

  void resetPhoneLogin() {
    var changed = _loading.remove(AuthLoadingKey.phoneLogin);
    _cancelValidationTimers(const ['phone_login_phone']);
    changed = _removeError('phone_login_phone') || changed;
    if (changed) notifyListeners();
  }

  void resetCompleteProfile() {
    var changed = _loading.remove(AuthLoadingKey.completeProfile);
    changed = _selectedProfileImage != null || changed;
    changed = _selectedProfileImageBytes != null || changed;
    _selectedProfileImage = null;
    _selectedProfileImageBytes = null;
    if (changed) notifyListeners();
  }

  void resetOtp() {
    final changed1 = _loading.remove(AuthLoadingKey.otp);
    final changed2 = _loading.remove(AuthLoadingKey.resendOtp);
    if (changed1 || changed2) notifyListeners();
  }

  void resetResetPassword() {
    final changed = _loading.remove(AuthLoadingKey.resetPassword);
    if (changed) notifyListeners();
  }
}
