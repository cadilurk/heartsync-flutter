class Milestone {
  final String id;
  final String userId;
  final String? relationshipId;
  final String title;
  final DateTime date;
  final String icon;
  final String type; // 'memory' or 'challenge'
  final bool isCompleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Milestone({
    required this.id,
    required this.userId,
    this.relationshipId,
    required this.title,
    required this.date,
    required this.icon,
    this.type = 'memory',
    this.isCompleted = false,
    this.createdAt,
    this.updatedAt,
  });

  factory Milestone.fromJson(Map<String, dynamic> json) {
    return Milestone(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      relationshipId: json['relationshipId']?.toString(),
      title: json['title']?.toString() ?? '',
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      icon: json['icon']?.toString() ?? '🎉',
      type: json['type']?.toString() ?? 'memory',
      isCompleted: json['isCompleted'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'relationshipId': relationshipId,
        'title': title,
        'date': '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        'icon': icon,
        'type': type,
        'isCompleted': isCompleted,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  Milestone copyWith({
    String? id,
    String? userId,
    String? relationshipId,
    String? title,
    DateTime? date,
    String? icon,
    String? type,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Milestone(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      relationshipId: relationshipId ?? this.relationshipId,
      title: title ?? this.title,
      date: date ?? this.date,
      icon: icon ?? this.icon,
      type: type ?? this.type,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
