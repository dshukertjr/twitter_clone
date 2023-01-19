import 'package:twitter_clone/models/user_profile.dart';

class Post {
  final String id;
  final String body;
  final DateTime createdAt;
  final int likeCount;
  final bool haveLiked;
  final UserProfile user;

  Post({
    required this.id,
    required this.body,
    required this.createdAt,
    required this.likeCount,
    required this.haveLiked,
    required this.user,
  });

  Post.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        body = json['body'],
        createdAt = DateTime.parse(json['created_at']),
        likeCount = json['like_count'][0]['count'],
        haveLiked = json['my_like'][0]['count'] > 0,
        user = UserProfile.fromJson(json['user']);

  Post like() {
    return Post(
      id: id,
      body: body,
      createdAt: createdAt,
      likeCount: likeCount + 1,
      haveLiked: true,
      user: user,
    );
  }

  Post unlike() {
    return Post(
      id: id,
      body: body,
      createdAt: createdAt,
      likeCount: likeCount - 1,
      haveLiked: false,
      user: user,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is Post && other.hashCode == hashCode;
  }

  @override
  int get hashCode => id.hashCode;
}
