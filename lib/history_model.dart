import 'dart:convert';

class MessageHistory {
  final String id;
  final String profileId;
  final String profileName;
  final String message;
  final DateTime timestamp;

  MessageHistory({
    required this.id,
    required this.profileId,
    required this.profileName,
    required this.message,
    required this.timestamp,
  });

  String toJson() {
    return jsonEncode({
      'id': id,
      'profileId': profileId,
      'profileName': profileName,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
    });
  }

  factory MessageHistory.fromJson(String json) {
    final map = Map<String, dynamic>.from(
      jsonDecode(json) as Map<dynamic, dynamic>,
    );
    return MessageHistory(
      id: map['id'],
      profileId: map['profileId'],
      profileName: map['profileName'],
      message: map['message'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}
