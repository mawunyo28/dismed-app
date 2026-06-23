class Compartment {
  final String id;
  final String deviceId;
  final int slot;
  final String? medicationName;
  final double? dosageMg;
  final int pillCount;
  final int capacity;
  final DateTime? updatedAt;

  Compartment({
    required this.id,
    required this.deviceId,
    required this.slot,
    this.medicationName,
    this.dosageMg,
    required this.pillCount,
    required this.capacity,
    this.updatedAt,
  });

  double get fillRatio => capacity == 0 ? 0 : pillCount / capacity;
  bool get isLowStock => pillCount < 5;
  bool get isEmpty => pillCount == 0;

  factory Compartment.fromJson(Map<String, dynamic> json) {
    return Compartment(
      id: json['id'],
      deviceId: json['device_id'],
      slot: json['slot'],
      medicationName: json['medication_name'],
      dosageMg: json['dosage_mg'] != null ? (json['dosage_mg'] as num).toDouble() : null,
      pillCount: json['pill_count'] ?? 0,
      capacity: json['capacity'] ?? 30,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'device_id': deviceId,
      'slot': slot,
      'medication_name': medicationName,
      'dosage_mg': dosageMg,
      'pill_count': pillCount,
      'capacity': capacity,
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
