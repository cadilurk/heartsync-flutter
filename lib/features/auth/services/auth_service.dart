import '../../../core/network/api_client.dart';
import '../models/auth_tokens.dart';
import '../models/email_verify_request.dart';
import '../models/firebase_login_request.dart';
import '../models/forgot_password_request.dart';
import '../models/login_request.dart';
import '../models/register_request.dart';
import '../models/reset_password_request.dart';

class AuthResult {
  final AuthTokens tokens;

  const AuthResult({required this.tokens});

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    return AuthResult(tokens: AuthTokens.fromJson(json));
  }
}

class AuthService {
  final ApiClient _apiClient;

  AuthService(this._apiClient);

  Future<AuthResult> register(RegisterRequest request) {
    return _apiClient.post<AuthResult>(
      '/auth/register',
      request.toJson(),
      (json) => AuthResult.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<AuthResult> login(LoginRequest request) {
    return _apiClient.post<AuthResult>(
      '/auth/login',
      request.toJson(),
      (json) => AuthResult.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<void> logout() async {
    await _apiClient.post<bool>(
      '/auth/logout',
      null,
      (json) => json == true,
    );
  }

  Future<AuthResult> loginWithFirebase({
    required String idToken,
    required FirebaseAuthProviderKind provider,
  }) {
    return _apiClient.post<AuthResult>(
      '/auth/firebase',
      FirebaseLoginRequest(idToken: idToken, provider: provider).toJson(),
      (json) => AuthResult.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<void> sendEmailVerificationCode(String email) async {
    await _apiClient.post<bool>(
      '/auth/email/send-code',
      {'email': email.trim()},
      (json) => json == true,
    );
  }

  Future<AuthResult> verifyEmailCode({required String email, required String code}) {
    return _apiClient.post<AuthResult>(
      '/auth/email/verify',
      EmailVerifyRequest(email: email, code: code).toJson(),
      (json) => AuthResult.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<void> forgotPassword(String email) async {
    await _apiClient.post<bool>(
      '/auth/password/forgot',
      ForgotPasswordRequest(email: email).toJson(),
      (json) => json == true,
    );
  }

  Future<AuthResult> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) {
    return _apiClient.post<AuthResult>(
      '/auth/password/reset',
      ResetPasswordRequest(email: email, code: code, newPassword: newPassword).toJson(),
      (json) => AuthResult.fromJson(json as Map<String, dynamic>),
    );
  }
}
