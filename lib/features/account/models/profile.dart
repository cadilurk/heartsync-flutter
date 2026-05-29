class Profile {
  final String id;
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? bio;
  final DateTime? relationshipStartDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Profile({
    required this.id,
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    this.dateOfBirth,
    this.gender,
    this.bio,
    this.relationshipStartDate,
    this.createdAt,
    this.updatedAt,
  });

  bool get isCompleted => displayName.trim().isNotEmpty;

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? '',
      avatarUrl: json['avatarUrl']?.toString(),
      dateOfBirth: DateTime.tryParse(json['dateOfBirth']?.toString() ?? ''),
      gender: json['gender']?.toString(),
      bio: json['bio']?.toString(),
      relationshipStartDate:
          DateTime.tryParse(json['relationshipStartDate']?.toString() ?? ''),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'displayName': displayName,
        'avatarUrl': avatarUrl,
        'dateOfBirth': dateOfBirth?.toIso8601String(),
        'gender': gender,
        'bio': bio,
        'relationshipStartDate': relationshipStartDate?.toIso8601String(),
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };
}
