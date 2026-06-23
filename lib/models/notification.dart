class DismedNotification {
  final String id;
  final String ownerId;
  final String title;
  final String? body;
  final String category; // 'missed_dose' | 'low_stock' | 'jammed' | 'general'
  final bool read;
  final DateTime? createdAt;

  DismedNotification({
    required this.id,
    required this.ownerId,
    required this.title,
    this.body,
    required this.category,
    required this.read,
    this.createdAt,
  });

  factory DismedNotification.fromJson(Map<String, dynamic> json) {
    return DismedNotification(
      id: json['id'],
      ownerId: json['owner_id'],
      title: json['title'],
      body: json['body'],
      category: json['category'] ?? 'general',
      read: json['read'] ?? false,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'title': title,
      'body': body,
      'category': category,
      'read': read,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
