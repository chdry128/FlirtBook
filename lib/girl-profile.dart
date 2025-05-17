import 'dart:convert';

class GirlProfile {
  final String id;
  final String name;
  final String status;
  final List<String> interests;

  GirlProfile({
    required this.id,
    required this.name,
    required this.status,
    required this.interests,
  });

  String toJson() {
    return jsonEncode({
      'id': id,
      'name': name,
      'status': status,
      'interests': interests,
    });
  }

  factory GirlProfile.fromJson(String json) {
    final map = Map<String, dynamic>.from(
      jsonDecode(json) as Map<dynamic, dynamic>,
    ); // ignore: cast_nullable_to_non_nullable
    return GirlProfile(
      id: map['id'],
      name: map['name'],
      status: map['status'],
      interests: List<String>.from(map['interests']),
    );
  }
}
