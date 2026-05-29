class PairingCode {
  final String id;
  final String code;
  final String createdByUserId;
  final String status;
  final DateTime? expiredAt;
  final String? usedByUserId;
  final DateTime? usedAt;
  final DateTime? createdAt;

  const PairingCode({
    required this.id,
    required this.code,
    required this.createdByUserId,
    this.status = 'active',
    this.expiredAt,
    this.usedByUserId,
    this.usedAt,
    this.createdAt,
  });

  factory PairingCode.fromJson(Map<String, dynamic> json) {
    return PairingCode(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      createdByUserId: json['createdByUserId']?.toString() ?? '',
      status: json['status']?.toString() ?? 'active',
      expiredAt: DateTime.tryParse(json['expiredAt']?.toString() ?? ''),
      usedByUserId: json['usedByUserId']?.toString(),
      usedAt: DateTime.tryParse(json['usedAt']?.toString() ?? ''),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'createdByUserId': createdByUserId,
        'status': status,
        'expiredAt': expiredAt?.toIso8601String(),
        'usedByUserId': usedByUserId,
        'usedAt': usedAt?.toIso8601String(),
        'createdAt': createdAt?.toIso8601String(),
      };
}
