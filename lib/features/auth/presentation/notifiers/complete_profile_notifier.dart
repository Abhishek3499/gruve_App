import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gruve_app/features/auth/presentation/controllers/complete_profile_controller.dart';

/// UI state for the Complete Profile screen: submit-loading flag plus the
/// selected profile image. Replaces the Complete-Profile-only slice that
/// used to live in `AuthUiProvider`.
///
/// Username validation is not included here — it was already plain local
/// `setState` in the screen (never routed through `AuthUiProvider`), so it
/// stays there unchanged.
class CompleteProfileUiState {
  const CompleteProfileUiState({
    this.isLoading = false,
    this.selectedImage,
    this.selectedImageBytes,
  });

  final bool isLoading;
  final XFile? selectedImage;
  final Uint8List? selectedImageBytes;
}

/// Owns Complete Profile's loading/image state and delegates the submit
/// call to [CompleteProfileController].
class CompleteProfileNotifier extends Notifier<CompleteProfileUiState> {
  late final CompleteProfileController _controller;

  @override
  CompleteProfileUiState build() {
    _controller = CompleteProfileController();
    return const CompleteProfileUiState();
  }

  void setProfileImage(XFile image, Uint8List bytes) {
    state = CompleteProfileUiState(
      isLoading: state.isLoading,
      selectedImage: image,
      selectedImageBytes: bytes,
    );
  }

  /// Clears Complete Profile's state when the screen mounts, matching the
  /// previous `AuthUiProvider.resetCompleteProfile()`.
  void reset() {
    state = const CompleteProfileUiState();
  }

  Future<CompleteProfileResult> completeProfile({
    required String username,
    String? file,
    XFile? image,
  }) async {
    state = CompleteProfileUiState(
      isLoading: true,
      selectedImage: state.selectedImage,
      selectedImageBytes: state.selectedImageBytes,
    );
    try {
      return await _controller.completeProfile(
        username: username,
        file: file,
        image: image,
      );
    } finally {
      state = CompleteProfileUiState(
        isLoading: false,
        selectedImage: state.selectedImage,
        selectedImageBytes: state.selectedImageBytes,
      );
    }
  }
}

final completeProfileNotifierProvider =
    NotifierProvider<CompleteProfileNotifier, CompleteProfileUiState>(
  CompleteProfileNotifier.new,
);
