import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twitter_clone/constants.dart';
import 'package:twitter_clone/models/post.dart';

final postsProvider = StateNotifierProvider<PostsNotifier, PostsState>((ref) {
  return PostsNotifier()..getPosts();
});

abstract class PostsState {}

class PostsLoading extends PostsState {}

class PostsLoaded extends PostsState {
  final List<Post> posts;

  PostsLoaded(this.posts);
}

class PostsNotifier extends StateNotifier<PostsState> {
  PostsNotifier() : super(PostsLoading());

  var _posts = <Post>[];

  Future<void> getPosts() async {
    final data = await supabase
        .from('posts')
        .select<List<Map<String, dynamic>>>(
            '*, user:users(*), like_count:likes(count), my_like:likes(count)')
        .eq('my_like.user_id', supabase.auth.currentUser!.id)
        .order('created_at')
        .limit(20);
    _posts = data.map(Post.fromJson).toList();
    state = PostsLoaded(_posts);
  }

  Future<void> createPost(String body) async {
    final insertedData = await supabase
        .from('posts')
        .insert({'body': body})
        .select<Map<String, dynamic>>()
        .single();
    final data = await supabase
        .from('posts')
        .select<Map<String, dynamic>>(
            '*, user:users(*), like_count:likes(count), my_like:likes(count)')
        .match({
      'id': insertedData['id'],
      'my_like.user_id': supabase.auth.currentUser!.id,
    }).single();
    final post = Post.fromJson(data);

    _posts = [post, ..._posts];
    state = PostsLoaded(_posts);
  }
}
