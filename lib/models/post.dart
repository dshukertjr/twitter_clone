import 'package:twitter_clone/models/user_profile.dart';

class Post {
  final String id;
  final String body;
  final UserProfile user;

  Post({
    required this.id,
    required this.body,
    required this.user,
  });

  Post.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        body = json['body'],
        user = UserProfile.fromJson(json['user']);
}
