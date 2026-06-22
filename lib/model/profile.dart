class Profile {
  final String id;
  final String fullName;
  final String email;
  final DateTime createdAt;

  Profile({required this.id, required this.fullName, required this.email, required this.createdAt});

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'],
      fullName: json["full_name"],
      email: json["email"],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      "full_name": fullName,
      "email": email,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
