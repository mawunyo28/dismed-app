class DispenseLog {
  final String id;
  final String? scheduleId; // null if manual
  final String compartmentId;
  final String deviceId;
  final DateTime dispensedAt;
  final String status; // 'success' | 'missed' | 'manual'
  final String triggeredBy; // 'schedule' | 'manual'

  DispenseLog({
    required this.id,
    this.scheduleId,
    required this.compartmentId,
    required this.deviceId,
    required this.dispensedAt,
    required this.status,
    required this.triggeredBy,
  });

  factory DispenseLog.fromJson(Map<String, dynamic> json) {
    return DispenseLog(
      id: json['id'],
      scheduleId: json['schedule_id'],
      compartmentId: json['compartment_id'],
      deviceId: json['device_id'],
      dispensedAt: DateTime.parse(json['dispensed_at']),
      status: json['status'],
      triggeredBy: json['triggered_by'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'schedule_id': scheduleId,
      'compartment_id': compartmentId,
      'device_id': deviceId,
      'dispensed_at': dispensedAt.toIso8601String(),
      'status': status,
      'triggered_by': triggeredBy,
    };
  }
}
