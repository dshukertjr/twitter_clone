import 'package:twitter_clone/models/message.dart';
import 'package:twitter_clone/models/profile.dart';

class Room {
  Room({
    required this.id,
    required this.createdAt,
    required this.otherUserId,
    this.otherUser,
    this.lastMessage,
  });

  /// ID of the room
  final String id;

  /// Date and time when the room was created
  final DateTime createdAt;

  /// ID of the user who the user is talking to
  final String otherUserId;

  /// Profile of the other user
  final Profile? otherUser;

  /// Latest message submitted in the room
  final Message? lastMessage;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  /// Creates a room object from room_participants table
  Room.fromRoomParticipants(Map<String, dynamic> map)
      : id = map['room_id'],
        otherUserId = map['user_id'],
        otherUser = null,
        createdAt = DateTime.parse(map['created_at']),
        lastMessage = null;

  Room copyWith({
    String? id,
    DateTime? createdAt,
    String? otherUserId,
    Profile? otherUser,
    Message? lastMessage,
  }) {
    return Room(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      otherUserId: otherUserId ?? this.otherUserId,
      otherUser: otherUser ?? this.otherUser,
      lastMessage: lastMessage ?? this.lastMessage,
    );
  }
}
