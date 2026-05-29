import '../../../core/network/api_client.dart';
import '../../account/models/user.dart';
import '../models/couple_relationship.dart';
import '../models/pairing_code.dart';
import '../models/pairing_status.dart';

class PairingConnectResult {
  final CoupleRelationship relationship;
  final User partner;

  const PairingConnectResult({
    required this.relationship,
    required this.partner,
  });

  factory PairingConnectResult.fromJson(Map<String, dynamic> json) {
    return PairingConnectResult(
      relationship: CoupleRelationship.fromJson(json['relationship'] as Map<String, dynamic>),
      partner: User.fromJson(json['partner'] as Map<String, dynamic>),
    );
  }
}

class PairingService {
  final ApiClient _apiClient;

  PairingService(this._apiClient);

  Future<PairingCode> generate() {
    return _apiClient.post<PairingCode>(
      '/pairing/generate',
      null,
      (json) => PairingCode.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<PairingConnectResult> connect(String code) {
    return _apiClient.post<PairingConnectResult>(
      '/pairing/connect',
      {'code': code.trim().toUpperCase()},
      (json) => PairingConnectResult.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<PairingStatus> status() {
    return _apiClient.get<PairingStatus>(
      '/pairing/status',
      (json) => PairingStatus.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<void> disconnect({String reason = 'user_request'}) async {
    await _apiClient.delete<bool>(
      '/pairing/disconnect',
      {'reason': reason},
      (json) => json == true,
    );
  }
}
