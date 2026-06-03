class Challenge {
  final String id;
  final String key;
  final String title;
  final String description;
  final int xpReward;
  final int happinessReward;
  final bool isAutoVerifiable;
  final bool isCompleted;
  final String icon;

  const Challenge({
    required this.id,
    required this.key,
    required this.title,
    required this.description,
    required this.xpReward,
    required this.happinessReward,
    required this.isAutoVerifiable,
    this.isCompleted = false,
    required this.icon,
  });

  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: json['id']?.toString() ?? '',
      key: json['key']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      xpReward: json['xpReward'] as int? ?? 10,
      happinessReward: json['happinessReward'] as int? ?? 15,
      isAutoVerifiable: json['isAutoVerifiable'] as bool? ?? false,
      isCompleted: json['isCompleted'] as bool? ?? false,
      icon: json['icon']?.toString() ?? 'star',
    );
  }

  Challenge copyWith({
    String? id,
    String? key,
    String? title,
    String? description,
    int? xpReward,
    int? happinessReward,
    bool? isAutoVerifiable,
    bool? isCompleted,
    String? icon,
  }) {
    return Challenge(
      id: id ?? this.id,
      key: key ?? this.key,
      title: title ?? this.title,
      description: description ?? this.description,
      xpReward: xpReward ?? this.xpReward,
      happinessReward: happinessReward ?? this.happinessReward,
      isAutoVerifiable: isAutoVerifiable ?? this.isAutoVerifiable,
      isCompleted: isCompleted ?? this.isCompleted,
      icon: icon ?? this.icon,
    );
  }
}
