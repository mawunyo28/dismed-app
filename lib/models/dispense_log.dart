class DispenseEvent {
  final String id;
  final String deviceId;
  final String? compartmentId;
  final int? slot;
  final String status; // 'success' | 'missed' | 'jammed' | 'manual'
  final String triggeredBy; // 'schedule' | 'manual'
  final DateTime dispensedAt;
  final String? note;

  DispenseEvent({
    required this.id,
    required this.deviceId,
    this.compartmentId,
    this.slot,
    required this.status,
    required this.triggeredBy,
    required this.dispensedAt,
    this.note,
  });

  factory DispenseEvent.fromJson(Map<String, dynamic> json) {
    return DispenseEvent(
      id: json['id'],
      deviceId: json['device_id'],
      compartmentId: json['compartment_id'],
      slot: json['slot'],
      status: json['status'],
      triggeredBy: json['triggered_by'] ?? 'schedule',
      dispensedAt: DateTime.parse(json['dispensed_at']),
      note: json['note'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'device_id': deviceId,
      'compartment_id': compartmentId,
      'slot': slot,
      'status': status,
      'triggered_by': triggeredBy,
      'dispensed_at': dispensedAt.toIso8601String(),
      'note': note,
    };
  }
}

