// ignore_for_file: prefer_initializing_formals

import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/notifications/fcm_service.dart';
import '../../../core/storage/token_storage.dart';
import '../../account/services/account_service.dart';
import '../models/current_user_session.dart';
import '../models/firebase_login_request.dart';
import '../models/login_request.dart';
import '../models/register_request.dart';
import '../services/auth_service.dart';
import '../services/firebase_auth_gateway.dart';

enum AuthStatus { unknown, unauthenticated, authenticated, loading, error }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final AccountService _accountService;
  final TokenStorage _tokenStorage;
  final ApiClient _apiClient;
  final FirebaseAuthGateway _firebaseAuthGateway;

  AuthStatus status = AuthStatus.unknown;
  CurrentUserSession session = CurrentUserSession.empty;
  String? errorMessage;

  int _retryCount = 0;
  static const int _maxRetries = 3;

  String? _phoneVerificationId;
  int? _phoneForceResendingToken;
  String? _pendingPhoneNumber;
  bool _auxLoading = false;

  AuthProvider({
    required AuthService authService,
    required AccountService accountService,
    required TokenStorage tokenStorage,
    required ApiClient apiClient,
    required FirebaseAuthGateway firebaseAuthGateway,
  })  : _authService = authService,
        _accountService = accountService,
        _tokenStorage = tokenStorage,
        _apiClient = apiClient,
        _firebaseAuthGateway = firebaseAuthGateway;

  bool get isAuthenticated => session.isAuthenticated;
  bool get isPaired => session.isPaired;
  bool get isProfileCompleted => session.isProfileCompleted;
  String? get phoneVerificationId => _phoneVerificationId;
  String? get pendingPhoneNumber => _pendingPhoneNumber;
  bool get isEmailVerified => session.user?.emailVerified ?? true;
  bool get isBusy => status == AuthStatus.loading || _auxLoading;

  Future<void> bootstrap() async {
    // SplashScreen can be re-mounted (e.g. after an OS-level interruption)
    // while the user is already past the initial bootstrap and mid-flow on
    // another screen — re-running this would reset status to `loading` and
    // bounce them out of whatever they were doing. Only the very first,
    // genuine app-startup call (status still `unknown`) should proceed.
    if (status != AuthStatus.unknown) return;

    status = AuthStatus.loading;
    errorMessage = null;
    notifyListeners();

    try {
      final tokens = await _tokenStorage.readTokens();
      if (tokens == null) {
        status = AuthStatus.unauthenticated;
        session = CurrentUserSession.empty;
        notifyListeners();
        return;
      }
      // bootstrap không retry — lỗi mạng khi khởi động → về login ngay
      await refreshSession(notifyLoading: false, withRetry: false);
    } catch (e) {
      session = CurrentUserSession.empty;
      status = AuthStatus.unauthenticated;
      notifyListeners();
    }
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
    _retryCount = 0;
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

  Future<void> refreshSession({
    bool notifyLoading = true,
    bool withRetry = true,
  }) async {
    try {
      if (notifyLoading) {
        status = AuthStatus.loading;
        notifyListeners();
      }
      session = await _accountService.me();
      status = session.isAuthenticated ? AuthStatus.authenticated : AuthStatus.unauthenticated;
      errorMessage = null;
      _retryCount = 0;

      // Initialize FCM token registration if authenticated
      if (session.isAuthenticated && !kIsWeb) {
        FcmService().initialize(_apiClient);
      }
    } on ApiException catch (error) {
      // Auth error (401 etc.) → clear tokens, không retry
      _retryCount = 0;
      await _tokenStorage.clear();
      session = CurrentUserSession.empty;
      status = error.code == 'UNAUTHENTICATED' ? AuthStatus.unauthenticated : AuthStatus.error;
      errorMessage = error.message;
    } catch (_) {
      // Network error (Connection refused, timeout...) → retry với exponential backoff
      if (withRetry && _retryCount < _maxRetries) {
        _retryCount++;
        // Backoff: 2s, 4s, 8s
        await Future.delayed(Duration(seconds: pow(2, _retryCount).toInt()));
        return refreshSession(notifyLoading: false, withRetry: true);
      }
      // Hết retry → về màn login
      _retryCount = 0;
      session = CurrentUserSession.empty;
      status = AuthStatus.unauthenticated;
      errorMessage = null;
    }
    notifyListeners();
  }

  void updateSession(CurrentUserSession value) {
    session = value;
    status = value.isAuthenticated ? AuthStatus.authenticated : AuthStatus.unauthenticated;
    errorMessage = null;
    notifyListeners();
  }

  Future<void> _completeFirebaseLogin(
    String firebaseIdToken,
    FirebaseAuthProviderKind provider,
  ) async {
    final result = await _authService.loginWithFirebase(
      idToken: firebaseIdToken,
      provider: provider,
    );
    await _tokenStorage.saveTokens(result.tokens);
    await refreshSession(notifyLoading: false);
  }

  Future<void> loginWithGoogle() async {
    _auxLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final idToken = await _firebaseAuthGateway.signInWithGoogle();
      await _runAuthAction(
        () => _completeFirebaseLogin(idToken, FirebaseAuthProviderKind.google),
      );
    } on GoogleSignInCanceled catch (_) {
      // silent no-op, user just backed out of the picker
    } on ApiException catch (_) {
      // _runAuthAction already set status/errorMessage before rethrowing — just stop it here.
    } catch (_) {
      errorMessage = 'Đăng nhập Google thất bại. Vui lòng thử lại.';
      status = AuthStatus.error;
      notifyListeners();
    } finally {
      _auxLoading = false;
      notifyListeners();
    }
  }

  Future<void> startPhoneLogin(String phoneNumber) async {
    _auxLoading = true;
    _pendingPhoneNumber = phoneNumber;
    errorMessage = null;
    notifyListeners();
    try {
      final outcome = await _firebaseAuthGateway.sendPhoneCode(
        phoneNumber,
        forceResendingToken: _phoneForceResendingToken,
      );
      if (outcome is PhoneOtpSent) {
        _phoneVerificationId = outcome.verificationId;
        _phoneForceResendingToken = outcome.forceResendingToken;
      } else if (outcome is PhoneAutoVerified) {
        await _runAuthAction(
          () => _completeFirebaseLogin(outcome.firebaseIdToken, FirebaseAuthProviderKind.phone),
        );
      }
    } on ApiException catch (error) {
      errorMessage = error.message;
      status = AuthStatus.error;
    } catch (_) {
      errorMessage = 'Không gửi được mã OTP. Vui lòng thử lại.';
      status = AuthStatus.error;
    } finally {
      _auxLoading = false;
      notifyListeners();
    }
  }

  Future<void> submitPhoneOtp(String smsCode) async {
    final verificationId = _phoneVerificationId;
    if (verificationId == null) return;
    await _runAuthAction(() async {
      final idToken = await _firebaseAuthGateway.confirmPhoneCode(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      await _completeFirebaseLogin(idToken, FirebaseAuthProviderKind.phone);
    });
  }

  Future<void> verifyEmailCode(String code) async {
    final email = session.user?.email;
    if (email == null) return;
    _auxLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final result = await _authService.verifyEmailCode(email: email, code: code);
      await _tokenStorage.saveTokens(result.tokens);
      await refreshSession(notifyLoading: false);
    } on ApiException catch (error) {
      errorMessage = error.message;
    } finally {
      _auxLoading = false;
      notifyListeners();
    }
  }

  Future<void> resendEmailCode() async {
    final email = session.user?.email;
    if (email == null) return;
    _auxLoading = true;
    notifyListeners();
    try {
      await _authService.sendEmailVerificationCode(email);
    } on ApiException catch (error) {
      errorMessage = error.message;
    } finally {
      _auxLoading = false;
      notifyListeners();
    }
  }

  Future<void> forgotPassword(String email) async {
    _auxLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _authService.forgotPassword(email);
    } on ApiException catch (error) {
      errorMessage = error.message;
      rethrow;
    } finally {
      _auxLoading = false;
      notifyListeners();
    }
  }

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    _auxLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final result = await _authService.resetPassword(
        email: email,
        code: code,
        newPassword: newPassword,
      );
      await _tokenStorage.saveTokens(result.tokens);
      await refreshSession(notifyLoading: false);
    } on ApiException catch (error) {
      errorMessage = error.message;
      rethrow;
    } finally {
      _auxLoading = false;
      notifyListeners();
    }
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
