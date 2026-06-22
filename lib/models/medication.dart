class Medication {
  final String id;
  final String userId;
  final String compartmentId;
  final String name;
  final String dosage;
  final String? color;
  final String? notes;
  final DateTime createdAt;

  Medication({
    required this.id,
    required this.userId,
    required this.compartmentId,
    required this.name,
    required this.dosage,
    this.color,
    this.notes,
    required this.createdAt,
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: json['id'],
      userId: json['user_id'],
      compartmentId: json['compartment_id'],
      name: json['name'],
      dosage: json['dosage'],
      color: json['color'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'compartment_id': compartmentId,
      'name': name,
      'dosage': dosage,
      'color': color,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
