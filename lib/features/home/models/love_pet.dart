class LovePet {
  final String id;
  final String name;
  final String petType; // 'cat', 'dog', 'bunny'
  final int level;
  final int xp;
  final int xpNeeded;
  final int happiness;
  final String status; // 'active', 'frozen'
  final int streak;
  final int daysLeft;
  final DateTime lastActivityAt;
  final bool isPremium;

  const LovePet({
    required this.id,
    required this.name,
    required this.petType,
    required this.level,
    required this.xp,
    required this.xpNeeded,
    required this.happiness,
    required this.status,
    required this.streak,
    required this.daysLeft,
    required this.lastActivityAt,
    this.isPremium = false,
  });

  factory LovePet.fromJson(Map<String, dynamic> json) {
    return LovePet(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Thú cưng',
      petType: json['petType']?.toString() ?? 'cat',
      level: json['level'] as int? ?? 1,
      xp: json['xp'] as int? ?? 0,
      xpNeeded: json['xpNeeded'] as int? ?? 100,
      happiness: json['happiness'] as int? ?? 100,
      status: json['status']?.toString() ?? 'active',
      streak: json['streak'] as int? ?? 0,
      daysLeft: json['daysLeft'] as int? ?? 7,
      lastActivityAt: DateTime.tryParse(json['lastActivityAt']?.toString() ?? '') ?? DateTime.now(),
      isPremium: json['isPremium'] as bool? ?? false,
    );
  }

  LovePet copyWith({
    String? id,
    String? name,
    String? petType,
    int? level,
    int? xp,
    int? xpNeeded,
    int? happiness,
    String? status,
    int? streak,
    int? daysLeft,
    DateTime? lastActivityAt,
    bool? isPremium,
  }) {
    return LovePet(
      id: id ?? this.id,
      name: name ?? this.name,
      petType: petType ?? this.petType,
      level: level ?? this.level,
      xp: xp ?? this.xp,
      xpNeeded: xpNeeded ?? this.xpNeeded,
      happiness: happiness ?? this.happiness,
      status: status ?? this.status,
      streak: streak ?? this.streak,
      daysLeft: daysLeft ?? this.daysLeft,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      isPremium: isPremium ?? this.isPremium,
    );
  }

  String get petEmoji {
    switch (petType.toLowerCase()) {
      case 'cat':
        return '🐱';
      case 'dog':
        return '🐶';
      case 'bunny':
        return '🐰';
      default:
        return '🐱';
    }
  }

  String get petLabel {
    switch (petType.toLowerCase()) {
      case 'cat':
        return 'Mèo Con';
      case 'dog':
        return 'Cún Con';
      case 'bunny':
        return 'Thỏ Bông';
      default:
        return 'Mèo Con';
    }
  }
}
