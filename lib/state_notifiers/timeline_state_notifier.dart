import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twitter_clone/constants.dart';
import 'package:twitter_clone/models/post.dart';
import 'package:twitter_clone/state_notifiers/posts_state_notifier.dart';
import 'package:uuid/uuid.dart';

/// Provider that returns the timeline state for the UI
final timelineStateProvider = Provider<TimelineState>((ref) {
  final postsStateNotifier = ref.watch(postsProvider);
  final timelineStateNotifier = ref.watch(timelineStateNotifierProvider);

  if (timelineStateNotifier == null) {
    return TimelineLoading();
  } else {
    final posts =
        postsStateNotifier.intersection(timelineStateNotifier).toList();
    posts.sort((a, b) {
      final aIndex =
          timelineStateNotifier.toList().indexWhere((element) => element == a);
      final bIndex =
          timelineStateNotifier.toList().indexWhere((element) => element == b);
      return aIndex - bIndex;
    });
    return TimelineLoaded(posts);
  }
});

/// State notifier that handles anything related to loading the home page timeline
/// The posts from this class should not be displayed on the UI,
/// and it should only be the reference to how the posts are ordered.
/// Instead, when displaying posts, use the `postProvider` to retrieve the posts to display.
final timelineStateNotifierProvider =
    StateNotifierProvider<TimelineStateNotifier, Set<Post>?>((ref) {
  final postsStateNotifier = ref.watch(postsProvider.notifier);

  return TimelineStateNotifier(postsStateNotifier: postsStateNotifier)
    ..getPosts();
});

abstract class TimelineState {}

class TimelineLoading extends TimelineState {}

class TimelineLoaded extends TimelineState {
  final List<Post> posts;

  TimelineLoaded(this.posts);
}

/// class that handles loading timeline posts
///
/// This class will pass any new posts that it loads to the postsStateNotifier
/// which is the single source of truth for any Posts being displayed on the UI
class TimelineStateNotifier extends StateNotifier<Set<Post>?> {
  TimelineStateNotifier({required PostsStateNotifier postsStateNotifier})
      : _postsStateNotifier = postsStateNotifier,
        super(null);

  final PostsStateNotifier _postsStateNotifier;

  var _posts = <Post>{};

  Future<void> getPosts() async {
    final data = await supabase
        .from('posts')
        .select<List<Map<String, dynamic>>>('''
            *, 
            user:profiles(*), 
            like_count:likes(count), 
            my_like:likes(count)
            ''')
        .eq('my_like.user_id', supabase.auth.currentUser!.id)
        .order('created_at')
        .limit(20);
    _posts = data.map(Post.fromJson).toSet();
    state = _posts;

    _postsStateNotifier.addPosts(_posts);
  }

  Future<void> createPost({
    required String body,
    required File? imageFile,
  }) async {
    final postId = const Uuid().v4();
    String? imagePath;
    if (imageFile != null) {
      final myUserId = supabase.auth.currentUser!.id;
      imagePath = '$myUserId/$postId.${imageFile.path.split('.').last}';
      await supabase.storage.from('posts').upload(imagePath, imageFile);
    }
    await supabase.from('posts').insert({
      'id': postId,
      'body': body,
      if (imagePath != null) 'image_path': imagePath,
    });
    final data = await supabase
        .from('posts')
        .select<Map<String, dynamic>>(
            '*, user:profiles(*), like_count:likes(count), my_like:likes(count)')
        .match({
      'id': postId,
      'my_like.user_id': supabase.auth.currentUser!.id,
    }).single();
    final newPost = Post.fromJson(data);

    _posts = {newPost, ..._posts};
    state = _posts;

    _postsStateNotifier.addPosts({newPost});
  }

  Future<void> likePost(String postId) async {
    final target = _posts.singleWhere((post) => post.id == postId);
    final likedPost = target.like();
    _posts = _posts.map((post) => post.id == postId ? likedPost : post).toSet();
    state = _posts;
    _postsStateNotifier.addPosts(_posts);
    await supabase.from('likes').insert({'post_id': postId});
  }

  Future<void> unlikePost(String postId) async {
    final target = _posts.singleWhere((post) => post.id == postId);
    final likedPost = target.unlike();
    _posts = _posts.map((post) => post.id == postId ? likedPost : post).toSet();
    state = _posts;
    _postsStateNotifier.addPosts(_posts);
    await supabase.from('likes').delete().match({'post_id': postId});
  }
}
