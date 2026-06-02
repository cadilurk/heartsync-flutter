import '../providers/alarm_provider.dart';

class Signal {
  final String id;
  final String fromUserId;
  final String toUserId;
  final SignalType signalType;
  final DateTime sentAt;
  final bool deliveredViaSocket;
  final bool fcmSent;
  final DateTime? readAt;
  final String? fromDisplayName;
  final String? fromAvatarUrl;

  const Signal({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.signalType,
    required this.sentAt,
    required this.deliveredViaSocket,
    required this.fcmSent,
    this.readAt,
    this.fromDisplayName,
    this.fromAvatarUrl,
  });

  factory Signal.fromJson(Map<String, dynamic> json) {
    final typeStr = json['signalType']?.toString() ?? 'love';
    final signalType = SignalType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => SignalType.love,
    );

    return Signal(
      id: json['id']?.toString() ?? '',
      fromUserId: json['fromUserId']?.toString() ?? '',
      toUserId: json['toUserId']?.toString() ?? '',
      signalType: signalType,
      sentAt: json['sentAt'] != null
          ? DateTime.tryParse(json['sentAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      deliveredViaSocket: json['deliveredViaSocket'] as bool? ?? false,
      fcmSent: json['fcmSent'] as bool? ?? false,
      readAt: json['readAt'] != null
          ? DateTime.tryParse(json['readAt'].toString())
          : null,
      fromDisplayName: json['fromDisplayName']?.toString(),
      fromAvatarUrl: json['fromAvatarUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fromUserId': fromUserId,
        'toUserId': toUserId,
        'signalType': signalType.name,
        'sentAt': sentAt.toIso8601String(),
        'deliveredViaSocket': deliveredViaSocket,
        'fcmSent': fcmSent,
        'readAt': readAt?.toIso8601String(),
        'fromDisplayName': fromDisplayName,
        'fromAvatarUrl': fromAvatarUrl,
      };
}
