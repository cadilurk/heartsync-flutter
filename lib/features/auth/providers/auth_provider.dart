// ignore_for_file: prefer_initializing_formals

import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/notifications/fcm_service.dart';
import '../../../core/storage/token_storage.dart';
import '../../account/services/account_service.dart';
import '../models/current_user_session.dart';
import '../models/login_request.dart';
import '../models/register_request.dart';
import '../services/auth_service.dart';

enum AuthStatus { unknown, unauthenticated, authenticated, loading, error }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final AccountService _accountService;
  final TokenStorage _tokenStorage;
  final ApiClient _apiClient;

  AuthStatus status = AuthStatus.unknown;
  CurrentUserSession session = CurrentUserSession.empty;
  String? errorMessage;

  AuthProvider({
    required AuthService authService,
    required AccountService accountService,
    required TokenStorage tokenStorage,
    required ApiClient apiClient,
  })  : _authService = authService,
        _accountService = accountService,
        _tokenStorage = tokenStorage,
        _apiClient = apiClient;

  bool get isAuthenticated => session.isAuthenticated;
  bool get isPaired => session.isPaired;
  bool get isProfileCompleted => session.isProfileCompleted;

  Future<void> bootstrap() async {
    status = AuthStatus.loading;
    errorMessage = null;
    notifyListeners();

    final tokens = await _tokenStorage.readTokens();
    if (tokens == null) {
      status = AuthStatus.unauthenticated;
      session = CurrentUserSession.empty;
      notifyListeners();
      return;
    }

    await refreshSession();
  }

  Future<void> register({
    required String email,
    required String password,
    String? displayName,
  }) async {
    await _runAuthAction(() async {
      final result = await _authService.register(
        RegisterRequest(email: email, password: password, displayName: displayName),
      );
      await _tokenStorage.saveTokens(result.tokens);
      await refreshSession(notifyLoading: false);
    });
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    await _runAuthAction(() async {
      final result = await _authService.login(LoginRequest(email: email, password: password));
      await _tokenStorage.saveTokens(result.tokens);
      await refreshSession(notifyLoading: false);
    });
  }

  Future<void> logout() async {
    if (!kIsWeb) {
      await FcmService().unregisterToken();
    }
    try {
      await _authService.logout();
    } catch (_) {
      // Local logout must still clear the session even if the server call fails.
    }
    await _tokenStorage.clear();
    session = CurrentUserSession.empty;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> refreshSession({bool notifyLoading = true}) async {
    try {
      if (notifyLoading) {
        status = AuthStatus.loading;
        notifyListeners();
      }
      session = await _accountService.me();
      status = session.isAuthenticated ? AuthStatus.authenticated : AuthStatus.unauthenticated;
      errorMessage = null;

      // Initialize FCM token registration if authenticated
      if (session.isAuthenticated && !kIsWeb) {
        FcmService().initialize(_apiClient);
      }
    } on ApiException catch (error) {
      await _tokenStorage.clear();
      session = CurrentUserSession.empty;
      status = error.code == 'UNAUTHENTICATED' ? AuthStatus.unauthenticated : AuthStatus.error;
      errorMessage = error.message;
    }
    notifyListeners();
  }

  void updateSession(CurrentUserSession value) {
    session = value;
    status = value.isAuthenticated ? AuthStatus.authenticated : AuthStatus.unauthenticated;
    errorMessage = null;
    notifyListeners();
  }

  Future<void> _runAuthAction(Future<void> Function() action) async {
    try {
      status = AuthStatus.loading;
      errorMessage = null;
      notifyListeners();
      await action();
    } on ApiException catch (error) {
      status = AuthStatus.error;
      errorMessage = error.message;
      notifyListeners();
      rethrow;
    }
  }
}
