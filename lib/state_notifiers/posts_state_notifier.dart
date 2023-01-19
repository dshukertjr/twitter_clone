import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twitter_clone/constants.dart';
import 'package:twitter_clone/models/post.dart';

final postsProvider =
    StateNotifierProvider<PostsStateNotifier, Set<Post>>((ref) {
  return PostsStateNotifier();
});

class PostsStateNotifier extends StateNotifier<Set<Post>> {
  PostsStateNotifier() : super({});

  var _posts = <Post>{};

  void addPosts(Set<Post> posts) {
    _posts.addAll(posts);
    state = _posts;
  }

  Future<void> likePost(String postId) async {
    final target = _posts.singleWhere((post) => post.id == postId);
    final likedPost = target.like();
    _posts = _posts.map((post) => post.id == postId ? likedPost : post).toSet();
    state = _posts;
    await supabase.from('likes').insert({'post_id': postId});
  }

  Future<void> unlikePost(String postId) async {
    final target = _posts.singleWhere((post) => post.id == postId);
    final likedPost = target.unlike();
    _posts = _posts.map((post) => post.id == postId ? likedPost : post).toSet();
    state = _posts;
    await supabase.from('likes').delete().match({'post_id': postId});
  }
}
