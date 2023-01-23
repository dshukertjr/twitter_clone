import 'package:twitter_clone/models/profile.dart';

enum NotificationType {
  like;

  static NotificationType fromString(String string) {
    return NotificationType.values
        .singleWhere((element) => element.name == string);
  }
}

/// Not naming it `Notification`, because `Notification` class already exists in Flutter
abstract class AppNotification {
  final String id;
  final String entityId;

  final DateTime createdAt;
  final bool hasBeenSeen;

  AppNotification({
    required this.id,
    required this.entityId,
    required this.createdAt,
    required this.hasBeenSeen,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    if (json['type'] == 'like') {
      return LikeNotification.fromJson(json);
    } else {
      return UnknownNotification(
        id: '',
        entityId: '',
        createdAt: DateTime.now(),
        hasBeenSeen: false,
      );
    }
  }

  AppNotification read();
}

class UnknownNotification extends AppNotification {
  UnknownNotification({
    required super.id,
    required super.entityId,
    required super.createdAt,
    required super.hasBeenSeen,
  });

  @override
  AppNotification read() {
    return this;
  }
}

class LikeNotification extends AppNotification {
  final Profile actor;
  final NotificationPost post;

  LikeNotification({
    required super.id,
    required super.entityId,
    required super.createdAt,
    required super.hasBeenSeen,
    required this.actor,
    required this.post,
  });

  LikeNotification.fromJson(Map<String, dynamic> json)
      : actor = Profile.fromJson(json['metadata']['actor']),
        post = NotificationPost.fromJson(json['metadata']['post']),
        super(
          id: json['id'],
          entityId: json['entity_id'],
          createdAt: DateTime.parse(json['created_at']),
          hasBeenSeen: json['has_been_seen'],
        );

  @override
  LikeNotification read() {
    return LikeNotification(
      id: id,
      entityId: entityId,
      createdAt: createdAt,
      hasBeenSeen: true,
      actor: actor,
      post: post,
    );
  }
}

class NotificationPost {
  final String id;
  final String body;

  NotificationPost({
    required this.id,
    required this.body,
  });

  NotificationPost.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        body = json['body'];
}
