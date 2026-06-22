class Compartment {
  final String id;
  final String deviceId;
  final int slotNumber;
  final String label;
  final int currentCount;
  final int capacity;
  final bool pendingDispense;
  final DateTime createdAt;

  double get fillRatio => currentCount / capacity;
  bool get isLowStock => currentCount < 5;

  Compartment({
    required this.id,
    required this.deviceId,
    required this.slotNumber,
    required this.label,
    required this.currentCount,
    required this.capacity,
    required this.pendingDispense,
    required this.createdAt,
  });

  factory Compartment.fromJson(Map<String, dynamic> json) {
    return Compartment(
      id: json['id'],
      deviceId: json['device_id'],
      slotNumber: json['slot_number'],
      label: json['label'],
      currentCount: json['current_count'],
      capacity: json['capacity'],
      pendingDispense: json['pending_dispense'],
      createdAt: json["createdAt"],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'device_id': deviceId,
      'slot_number': slotNumber,
      'label': label,
      'current_count': currentCount,
      'capacity': capacity,
      'pending_dispense': pendingDispense,
      'createdAt': createdAt,
    };
  }
}
