import 'package:twitter_clone/constants.dart';

class Message {
  Message({
    required this.id,
    required this.roomId,
    required this.userId,
    required this.content,
    required this.createdAt,
  });

  /// ID of the message
  final String id;

  /// ID of the user who posted the message
  final String userId;

  /// ID of the room the message belongs to
  final String roomId;

  /// Text content of the message
  final String content;

  /// Date and time when the message was created
  final DateTime createdAt;

  /// Whether the message is sent by the user or not.
  bool get isMine {
    final myUserId = supabase.auth.currentUser?.id;
    return myUserId == userId;
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'room_id': roomId,
      'content': content,
    };
  }

  Message.fromMap(Map<String, dynamic> map)
      : id = map['id'],
        roomId = map['room_id'],
        userId = map['profile_id'],
        content = map['content'],
        createdAt = DateTime.parse(map['created_at']);

  Message copyWith({
    String? id,
    String? userId,
    String? roomId,
    String? text,
    DateTime? createdAt,
  }) {
    return Message(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      roomId: roomId ?? this.roomId,
      content: text ?? content,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
