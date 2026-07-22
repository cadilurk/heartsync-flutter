// ignore_for_file: prefer_initializing_formals

import 'package:flutter/foundation.dart';

import '../../../core/network/api_exception.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/account_service.dart';

class AccountProvider extends ChangeNotifier {
  final AccountService _accountService;
  final AuthProvider _authProvider;

  bool isLoading = false;
  bool isUploadingAvatar = false;
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

  /// Opens the gallery picker and uploads the chosen image as the user's
  /// avatar. Returns the new avatar URL, or `null` if the user backed out
  /// of the picker (not an error — callers shouldn't show a message then).
  Future<String?> pickAndUploadAvatar() async {
    final file = await _accountService.pickAvatarImage();
    if (file == null) return null;

    try {
      isUploadingAvatar = true;
      errorMessage = null;
      notifyListeners();
      final avatarUrl = await _accountService.uploadAvatar(file);
      return avatarUrl;
    } on ApiException catch (error) {
      errorMessage = error.message;
      rethrow;
    } finally {
      isUploadingAvatar = false;
      notifyListeners();
    }
  }
}
