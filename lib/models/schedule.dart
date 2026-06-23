// models/schedule.dart
class Schedule {
  final String id;
  final String deviceId;
  final String compartmentId;
  final String dispenseTime; // "HH:mm:ss"
  final List<int> daysOfWeek; // [0..6], 0 = Sunday
  final int pillsPerDose;
  final bool active;
  final DateTime? createdAt;

  Schedule({
    required this.id,
    required this.deviceId,
    required this.compartmentId,
    required this.dispenseTime,
    required this.daysOfWeek,
    required this.pillsPerDose,
    required this.active,
    this.createdAt,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      id: json['id'],
      deviceId: json['device_id'],
      compartmentId: json['compartment_id'],
      dispenseTime: json['dispense_time'],
      daysOfWeek: List<int>.from(json['days_of_week'] ?? []),
      pillsPerDose: json['pills_per_dose'] ?? 1,
      active: json['active'] ?? true,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'device_id': deviceId,
      'compartment_id': compartmentId,
      'dispense_time': dispenseTime,
      'days_of_week': daysOfWeek,
      'pills_per_dose': pillsPerDose,
      'active': active,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

