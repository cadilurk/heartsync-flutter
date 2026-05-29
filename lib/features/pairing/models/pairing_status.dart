import '../../account/models/user.dart';

class PairingStatus {
  final String status;
  final String? relationshipId;
  final User? partner;

  const PairingStatus({
    required this.status,
    this.relationshipId,
    this.partner,
  });

  bool get isPaired => status == 'paired';

  factory PairingStatus.fromJson(Map<String, dynamic> json) {
    final partnerJson = json['partner'];
    return PairingStatus(
      status: json['status']?.toString() ?? 'unpaired',
      relationshipId: json['relationshipId']?.toString(),
      partner: partnerJson is Map<String, dynamic> ? User.fromJson(partnerJson) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'status': status,
        'relationshipId': relationshipId,
        'partner': partner?.toJson(),
      };
}
