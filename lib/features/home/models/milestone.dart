class MilestoneTask {
  final String id;
  final String title;
  final String assignee;
  final bool isDone;

  const MilestoneTask({
    required this.id,
    required this.title,
    required this.assignee,
    this.isDone = false,
  });

  factory MilestoneTask.fromJson(Map<String, dynamic> json) {
    return MilestoneTask(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      assignee: json['assignee']?.toString() ?? '',
      isDone: json['isDone'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'assignee': assignee,
    'isDone': isDone,
  };

  MilestoneTask copyWith({
    String? id,
    String? title,
    String? assignee,
    bool? isDone,
  }) {
    return MilestoneTask(
      id: id ?? this.id,
      title: title ?? this.title,
      assignee: assignee ?? this.assignee,
      isDone: isDone ?? this.isDone,
    );
  }
}

class Milestone {
  final String id;
  final String userId;
  final String? relationshipId;
  final String title;
  final DateTime date;
  final String icon;
  final String type; // 'memory' or 'challenge'
  final bool isCompleted;
  // Dual-confirmation fields
  final String status; // pending | negotiating | completed | declined
  final bool creatorConfirmed;
  final bool partnerConfirmed;
  final String? partnerProposedDate;
  final String? partnerResponse; // accepted | declined | proposed_date
  // Media & mood fields
  final String? coverImageUrl;
  final List<String> coverImageUrls;
  final String? mood; // happy | emotional | excited | romantic | nostalgic
  final String? songTitle;
  final String? songArtist;
  final String? songPreviewUrl;
  final String? songArtworkUrl;
  final List<MilestoneTask> checklist;
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
    this.status = 'pending',
    this.creatorConfirmed = true,
    this.partnerConfirmed = false,
    this.partnerProposedDate,
    this.partnerResponse,
    this.coverImageUrl,
    this.coverImageUrls = const [],
    this.mood,
    this.songTitle,
    this.songArtist,
    this.songPreviewUrl,
    this.songArtworkUrl,
    this.checklist = const [],
    this.createdAt,
    this.updatedAt,
  });

  int get completedTaskCount => checklist.where((task) => task.isDone).length;
  int get totalTaskCount => checklist.length;
  double get progress =>
      totalTaskCount == 0 ? 0 : completedTaskCount / totalTaskCount;

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
      status: json['status']?.toString() ?? 'completed',
      creatorConfirmed: json['creatorConfirmed'] as bool? ?? true,
      partnerConfirmed: json['partnerConfirmed'] as bool? ?? false,
      partnerProposedDate: json['partnerProposedDate']?.toString(),
      partnerResponse: json['partnerResponse']?.toString(),
      coverImageUrl: json['coverImageUrl']?.toString(),
      coverImageUrls:
          (json['coverImageUrls'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      mood: json['mood']?.toString(),
      songTitle: json['songTitle']?.toString(),
      songArtist: json['songArtist']?.toString(),
      songPreviewUrl: json['songPreviewUrl']?.toString(),
      songArtworkUrl: json['songArtworkUrl']?.toString(),
      checklist:
          (json['checklist'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(MilestoneTask.fromJson)
              .toList() ??
          [],
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'relationshipId': relationshipId,
    'title': title,
    'date':
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
    'icon': icon,
    'type': type,
    'isCompleted': isCompleted,
    'status': status,
    'creatorConfirmed': creatorConfirmed,
    'partnerConfirmed': partnerConfirmed,
    'partnerProposedDate': partnerProposedDate,
    'partnerResponse': partnerResponse,
    'coverImageUrl': coverImageUrl,
    'coverImageUrls': coverImageUrls,
    'mood': mood,
    'songTitle': songTitle,
    'songArtist': songArtist,
    'songPreviewUrl': songPreviewUrl,
    'songArtworkUrl': songArtworkUrl,
    'checklist': checklist.map((task) => task.toJson()).toList(),
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
    String? status,
    bool? creatorConfirmed,
    bool? partnerConfirmed,
    String? partnerProposedDate,
    String? partnerResponse,
    String? coverImageUrl,
    List<String>? coverImageUrls,
    String? mood,
    String? songTitle,
    String? songArtist,
    String? songPreviewUrl,
    String? songArtworkUrl,
    List<MilestoneTask>? checklist,
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
      status: status ?? this.status,
      creatorConfirmed: creatorConfirmed ?? this.creatorConfirmed,
      partnerConfirmed: partnerConfirmed ?? this.partnerConfirmed,
      partnerProposedDate: partnerProposedDate ?? this.partnerProposedDate,
      partnerResponse: partnerResponse ?? this.partnerResponse,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      coverImageUrls: coverImageUrls ?? this.coverImageUrls,
      mood: mood ?? this.mood,
      songTitle: songTitle ?? this.songTitle,
      songArtist: songArtist ?? this.songArtist,
      songPreviewUrl: songPreviewUrl ?? this.songPreviewUrl,
      songArtworkUrl: songArtworkUrl ?? this.songArtworkUrl,
      checklist: checklist ?? this.checklist,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
