class DismedNotification {
  final String id;
  final String userId;
  final String type; // 'missed_dose' | 'low_stock' | 'device_offline'
  final String message;
  final bool isRead;
  final DateTime createdAt;

  DismedNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory DismedNotification.fromJson(Map<String, dynamic> json) {
    return DismedNotification(
      id: json['id'],
      userId: json['user_id'],
      type: json['type'],
      message: json['message'],
      isRead: json['is_read'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'message': message,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
