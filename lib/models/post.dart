import 'package:twitter_clone/constants.dart';
import 'package:twitter_clone/models/profile.dart';

class Post {
  final String id;
  final String body;
  final DateTime createdAt;
  final int likeCount;
  final bool haveLiked;
  final String? imageUrl;
  final Profile profile;

  Post({
    required this.id,
    required this.body,
    required this.createdAt,
    required this.likeCount,
    required this.haveLiked,
    required this.imageUrl,
    required this.profile,
  });

  Post.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        body = json['body'],
        createdAt = DateTime.parse(json['created_at']),
        likeCount = json['like_count'][0]['count'],
        haveLiked = json['my_like'][0]['count'] > 0,
        imageUrl = json['image_path'] == null
            ? null
            : supabase.storage.from('posts').getPublicUrl(json['image_path']),
        profile = Profile.fromJson(json['user']);

  Post.fromSearchResult(dynamic json)
      : id = json['id'],
        body = json['body'],
        createdAt = DateTime.parse(json['created_at']),
        likeCount = json['like_count'],
        haveLiked = json['my_like'] > 0,
        imageUrl = json['image_path'] == null
            ? null
            : supabase.storage.from('posts').getPublicUrl(json['image_path']),
        profile = Profile.fromJson(json['profile']);

  Post like() {
    return Post(
      id: id,
      body: body,
      createdAt: createdAt,
      likeCount: likeCount + 1,
      haveLiked: true,
      imageUrl: imageUrl,
      profile: profile,
    );
  }

  Post unlike() {
    return Post(
      id: id,
      body: body,
      createdAt: createdAt,
      likeCount: likeCount - 1,
      haveLiked: false,
      imageUrl: imageUrl,
      profile: profile,
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
