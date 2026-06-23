class Device {
  final String id;
  final String userId;
  final String deviceKey;
  final String name;
  final DateTime? lastSeen;
  final DateTime createdAt;

  bool get isOnline {
    if (lastSeen == null) return false;
    return DateTime.now().difference(lastSeen!).inMinutes < 5;
  }

  Device({
    required this.id,
    required this.userId,
    required this.deviceKey,
    required this.name,
    this.lastSeen,
    required this.createdAt,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'],
      userId: json['user_id'],
      deviceKey: json['device_key'],
      name: json['name'],
      lastSeen: json['last_seen'] != null ? DateTime.parse(json['last_seen']) : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'device_key': deviceKey,
      'name': name,
      'last_seen': lastSeen?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}

