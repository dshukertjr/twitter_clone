import 'package:twitter_clone/models/user_profile.dart';

enum NotificationType {
  like;

  static NotificationType fromString(String string) {
    return NotificationType.values
        .singleWhere((element) => element.name == string);
  }
}

/// Not naming it `Notification`, because `Notification` class already exists in Flutter
class AppNotification {
  final String entityId;

  final DateTime createdAt;
  final bool hasBeenSeen;

  AppNotification({
    required this.entityId,
    required this.createdAt,
    required this.hasBeenSeen,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    if (json['type'] == 'like') {
      return LikeNotification.fromJson(json);
    } else {
      return UnknownNotification(
        entityId: '',
        createdAt: DateTime.now(),
        hasBeenSeen: false,
      );
    }
  }
}

class UnknownNotification extends AppNotification {
  UnknownNotification({
    required super.entityId,
    required super.createdAt,
    required super.hasBeenSeen,
  });
}

class LikeNotification extends AppNotification {
  final UserProfile actor;
  final _NotificationPost post;

  LikeNotification.fromJson(Map<String, dynamic> json)
      : actor = UserProfile.fromJson(json['metadata']['actor']),
        post = _NotificationPost.fromJson(json['metadata']['post']),
        super(
          entityId: json['entity_id'],
          createdAt: DateTime.parse(json['created_at']),
          hasBeenSeen: json['has_been_seen'],
        );
}

class _NotificationPost {
  final String id;
  final String body;

  _NotificationPost({
    required this.id,
    required this.body,
  });

  _NotificationPost.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        body = json['body'];
}
