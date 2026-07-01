import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:gruve_app/core/auth/auth_endpoint_paths.dart';
import 'package:gruve_app/core/config/environment_config.dart';
import 'package:gruve_app/core/network/auth_dio.dart';
import 'package:gruve_app/features/auth/core/auth_api_exception.dart';
import 'package:gruve_app/features/auth/core/auth_api_logger.dart';

import '../models/google_sign_in_model.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

class GoogleAuthService {
  GoogleAuthService({GoogleSignIn? googleSignIn, Dio? dio})
    : _googleSignIn = googleSignIn ?? GoogleSignIn.instance,
      _dio = dio ?? AuthDio.getInstance();

  final GoogleSignIn _googleSignIn;
  final Dio _dio;
  Future<void>? _initializeFuture;

  Future<GoogleSignInResponse?> signIn() async {
    if (_dio.options.baseUrl.trim().isEmpty) {
      throw 'BASE_URL is missing in .env';
    }

    try {
      await _initialize();

      if (!_googleSignIn.supportsAuthenticate()) {
        throw const AuthApiException(
          'Google sign-in is not supported on this platform.',
        );
      }

      final account = await _googleSignIn.authenticate();
      final auth = account.authentication;
      final idToken = auth.idToken;

      if (idToken == null || idToken.trim().isEmpty) {
        throw 'Google did not return an ID token. Please try again.';
      }

      const endpoint = 'auth/google/';
      final requestData = {'token': idToken};

      AuthApiLogger.request(
        'GoogleSignIn',
        dio: _dio,
        endpoint: endpoint,
        method: 'POST',
        body: const {'token': 'present'},
      );

      final response = await _dio.post(
        endpoint,
        data: requestData,
        options: AuthEndpointPaths.skipAuthOptions(),
      );

      AuthApiLogger.response('GoogleSignIn', response);

      return GoogleSignInResponse.fromJson(response.data);
    } on GoogleSignInException catch (e) {
      AppLogger.d('Google sign-in native error: $e');
      throw AuthApiException(_googleSignInExceptionMessage(e));
    } on DioException catch (e) {
      AuthApiLogger.error('GoogleSignIn', e);
      throw AuthApiException.extractMessage(
        e,
        fallback: 'Google sign-in failed. Please try again.',
      );
    } catch (e) {
      AppLogger.d('Google sign-in failed: $e');
      rethrow;
    }
  }

  Future<void> _initialize() {
    return _initializeFuture ??= _googleSignIn.initialize(
      serverClientId: EnvironmentConfig.googleWebClientId,
    );
  }

  String _googleSignInExceptionMessage(GoogleSignInException error) {
    final description = error.description?.trim();
    final detail = description == null || description.isEmpty
        ? error.toString()
        : description;

    switch (error.code) {
      case GoogleSignInExceptionCode.clientConfigurationError:
      case GoogleSignInExceptionCode.providerConfigurationError:
        return 'Google Sign-In is not configured correctly. '
            'GOOGLE_WEB_CLIENT_ID must be the OAuth 2.0 Web application client ID '
            'from the same Google Cloud project as the Android OAuth client for '
            'com.example.gruve_app and SHA-1 '
            '52:25:43:30:38:48:3E:62:1E:F4:4C:22:B0:82:26:17:08:7C:C6:E9. '
            'Google error: $detail';
      case GoogleSignInExceptionCode.canceled:
        return 'Google sign-in was canceled.';
      default:
        return 'Google sign-in failed. Google error: $detail';
    }
  }
}
