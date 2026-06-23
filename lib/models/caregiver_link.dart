class CaregiverLink {
  final String id;
  final String patientId;
  final String caregiverId;
  final String role;
  final bool canControl;
  final bool canApprove;
  final String status; // 'pending' | 'accepted' | 'rejected'
  final DateTime? createdAt;

  CaregiverLink({
    required this.id,
    required this.patientId,
    required this.caregiverId,
    required this.role,
    required this.canControl,
    required this.canApprove,
    required this.status,
    this.createdAt,
  });

  factory CaregiverLink.fromJson(Map<String, dynamic> json) {
    return CaregiverLink(
      id: json['id'],
      patientId: json['patient_id'],
      caregiverId: json['caregiver_id'],
      role: json['role'] ?? 'caregiver',
      canControl: json['can_control'] ?? false,
      canApprove: json['can_approve'] ?? false,
      status: json['status'] ?? 'pending',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'caregiver_id': caregiverId,
      'role': role,
      'can_control': canControl,
      'can_approve': canApprove,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
