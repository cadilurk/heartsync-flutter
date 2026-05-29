// ignore_for_file: prefer_initializing_formals

import 'package:flutter/foundation.dart';

import '../../../core/network/api_exception.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/account_service.dart';

class AccountProvider extends ChangeNotifier {
  final AccountService _accountService;
  final AuthProvider _authProvider;

  bool isLoading = false;
  String? errorMessage;

  AccountProvider({
    required AccountService accountService,
    required AuthProvider authProvider,
  })  : _accountService = accountService,
        _authProvider = authProvider;

  Future<void> saveProfile({
    required String displayName,
    String? avatarUrl,
    String? dateOfBirth,
    String? relationshipStartDate,
    String? gender,
    String? bio,
  }) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      final profile = await _accountService.updateProfile(
        displayName: displayName,
        avatarUrl: avatarUrl,
        dateOfBirth: dateOfBirth,
        relationshipStartDate: relationshipStartDate,
        gender: gender,
        bio: bio,
      );
      _authProvider.updateSession(_authProvider.session.copyWith(profile: profile));
    } on ApiException catch (error) {
      errorMessage = error.message;
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
