import '../../../core/network/api_client.dart';
import '../models/auth_tokens.dart';
import '../models/login_request.dart';
import '../models/register_request.dart';

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
}
