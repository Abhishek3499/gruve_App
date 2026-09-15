import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gruve_app/features/auth/presentation/controllers/google_sign_in_controller.dart';

/// UI state for the Google Sign-In flow: just the submit-loading flag.
/// Replaces the `_isGoogleLoading` local state that used to live on
/// `SignInScreen`.
class GoogleSignInUiState {
  const GoogleSignInUiState({this.isLoading = false});

  final bool isLoading;
}

/// Owns Google Sign-In's loading state and delegates the actual
/// authentication call to [GoogleAuthController].
class GoogleSignInNotifier extends Notifier<GoogleSignInUiState> {
  late final GoogleAuthController _controller;

  @override
  GoogleSignInUiState build() {
    _controller = GoogleAuthController();
    return const GoogleSignInUiState();
  }

  Future<GoogleSignInResult> signIn() async {
    state = const GoogleSignInUiState(isLoading: true);
    try {
      return await _controller.signIn();
    } finally {
      state = const GoogleSignInUiState(isLoading: false);
    }
  }
}

final googleSignInNotifierProvider =
    NotifierProvider<GoogleSignInNotifier, GoogleSignInUiState>(
      GoogleSignInNotifier.new,
    );
