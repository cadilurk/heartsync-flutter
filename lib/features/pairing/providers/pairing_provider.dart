// ignore_for_file: prefer_initializing_formals

import 'package:flutter/foundation.dart';

import '../../../core/network/api_exception.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/pairing_code.dart';
import '../services/pairing_service.dart';

enum PairingState { unknown, unpaired, paired, loading, error }

class PairingProvider extends ChangeNotifier {
  final PairingService _pairingService;
  final AuthProvider _authProvider;

  PairingState state = PairingState.unknown;
  PairingCode? activeCode;
  String? errorMessage;

  PairingProvider({
    required PairingService pairingService,
    required AuthProvider authProvider,
  })  : _pairingService = pairingService,
        _authProvider = authProvider;

  Future<void> refreshStatus() async {
    try {
      state = PairingState.loading;
      errorMessage = null;
      notifyListeners();
      final status = await _pairingService.status();
      state = status.isPaired ? PairingState.paired : PairingState.unpaired;
    } on ApiException catch (error) {
      state = PairingState.error;
      errorMessage = error.message;
    }
    notifyListeners();
  }

  Future<PairingCode> generateCode() async {
    if (_authProvider.isPaired) {
      throw const ApiException(
        code: 'USER_ALREADY_PAIRED',
        message: 'Tài khoản của bạn đã được ghép đôi.',
      );
    }

    try {
      state = PairingState.loading;
      errorMessage = null;
      notifyListeners();
      activeCode = await _pairingService.generate();
      state = PairingState.unpaired;
      return activeCode!;
    } on ApiException catch (error) {
      state = PairingState.error;
      errorMessage = error.message;
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  Future<void> connect(String code) async {
    try {
      state = PairingState.loading;
      errorMessage = null;
      notifyListeners();
      final result = await _pairingService.connect(code);
      _authProvider.updateSession(
        _authProvider.session.copyWith(
          relationship: result.relationship,
          partner: result.partner,
        ),
      );
      state = PairingState.paired;
    } on ApiException catch (error) {
      state = PairingState.error;
      errorMessage = error.message;
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    try {
      state = PairingState.loading;
      errorMessage = null;
      notifyListeners();
      await _pairingService.disconnect();
      _authProvider.updateSession(
        _authProvider.session.copyWith(clearRelationship: true, clearPartner: true),
      );
      activeCode = null;
      state = PairingState.unpaired;
    } on ApiException catch (error) {
      state = PairingState.error;
      errorMessage = error.message;
      rethrow;
    } finally {
      notifyListeners();
    }
  }
}
