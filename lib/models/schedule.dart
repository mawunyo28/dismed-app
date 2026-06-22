class Schedule {
  final String id;
  final String medicationId;
  final String compartmentId;
  final String deviceId;
  final String userId;
  final String scheduledTime; // "HH:mm:ss"
  final List<int> daysOfWeek; // [0..6], 0 = Sunday
  final bool isActive;
  final DateTime createdAt;

  Schedule({
    required this.id,
    required this.medicationId,
    required this.compartmentId,
    required this.deviceId,
    required this.userId,
    required this.scheduledTime,
    required this.daysOfWeek,
    required this.isActive,
    required this.createdAt,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      id: json['id'],
      medicationId: json['medication_id'],
      compartmentId: json['compartment_id'],
      deviceId: json['device_id'],
      userId: json['user_id'],
      scheduledTime: json['scheduled_time'],
      daysOfWeek: List<int>.from(json['days_of_week'] ?? []),
      isActive: json['is_active'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'medication_id': medicationId,
      'compartment_id': compartmentId,
      'device_id': deviceId,
      'user_id': userId,
      'scheduled_time': scheduledTime,
      'days_of_week': daysOfWeek,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
