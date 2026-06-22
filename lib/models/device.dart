class Device {
  final String id;
  final String userId;
  final String deviceId;
  final String name;
  final DateTime? lastSeen;
  final DateTime createdAt;

  Device({
    required this.id,
    required this.userId,
    required this.deviceId,
    required this.name,
    this.lastSeen,
    required this.createdAt,
  });

  bool get isOnline {
    if (lastSeen == null) return false;

    return DateTime.now().difference(lastSeen!).inMinutes < 5;
  }

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'],
      userId: json['user_id'],
      deviceId: json["device_id"],
      name: json['name'],
      createdAt: DateTime.parse(json["created_at"]), // Validate these names
      lastSeen: json['lastSeen'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      "user_id": userId,
      "device_id": deviceId,
      'name': name,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
