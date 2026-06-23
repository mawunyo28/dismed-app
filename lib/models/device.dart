// models/device.dart
class Device {
  final String id;
  final String ownerId;
  final String deviceKey;
  final String? label;
  final String? firmware;
  final DateTime? lastSeenAt;
  final bool isOnline;
  final DateTime? createdAt;

  Device({
    required this.id,
    required this.ownerId,
    required this.deviceKey,
    this.label,
    this.firmware,
    this.lastSeenAt,
    required this.isOnline,
    this.createdAt,
  });

  // isOnline comes from the DB column directly
  // but we can also derive it locally as a fallback
  bool get isOnlineDerived {
    if (lastSeenAt == null) return false;
    return DateTime.now().difference(lastSeenAt!).inMinutes < 5;
  }

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'],
      ownerId: json['owner_id'],
      deviceKey: json['device_key'],
      label: json['label'],
      firmware: json['firmware'],
      lastSeenAt: json['last_seen_at'] != null
          ? DateTime.parse(json['last_seen_at'])
          : null,
      isOnline: json['is_online'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'device_key': deviceKey,
      'label': label,
      'firmware': firmware,
      'last_seen_at': lastSeenAt?.toIso8601String(),
      'is_online': isOnline,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
