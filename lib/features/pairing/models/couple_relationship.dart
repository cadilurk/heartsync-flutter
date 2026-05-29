class CoupleRelationship {
  final String id;
  final String userAId;
  final String userBId;
  final DateTime? relationshipStartDate;
  final String status;
  final DateTime? disconnectedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CoupleRelationship({
    required this.id,
    required this.userAId,
    required this.userBId,
    this.relationshipStartDate,
    this.status = 'active',
    this.disconnectedAt,
    this.createdAt,
    this.updatedAt,
  });

  bool get isActive => status == 'active';

  factory CoupleRelationship.fromJson(Map<String, dynamic> json) {
    return CoupleRelationship(
      id: json['id']?.toString() ?? '',
      userAId: json['userAId']?.toString() ?? '',
      userBId: json['userBId']?.toString() ?? '',
      relationshipStartDate:
          DateTime.tryParse(json['relationshipStartDate']?.toString() ?? ''),
      status: json['status']?.toString() ?? 'active',
      disconnectedAt: DateTime.tryParse(json['disconnectedAt']?.toString() ?? ''),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userAId': userAId,
        'userBId': userBId,
        'relationshipStartDate': relationshipStartDate?.toIso8601String(),
        'status': status,
        'disconnectedAt': disconnectedAt?.toIso8601String(),
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };
}
