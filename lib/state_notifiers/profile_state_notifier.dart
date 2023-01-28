import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twitter_clone/constants.dart';
import 'package:twitter_clone/models/post.dart';
import 'package:twitter_clone/models/profile.dart';
import 'package:twitter_clone/state_notifiers/posts_state_notifier.dart';

final profileProvider =
    Provider.autoDispose.family<ProfileWithPosts?, String>((ref, userId) {
  final sourcePosts = ref.watch(postsProvider);
  final profileWithPosts = ref.watch(_profileStateNotifierProvider(userId));

  if (profileWithPosts == null) {
    return null;
  } else {
    final posts =
        sourcePosts.intersection(profileWithPosts.posts.toSet()).toList();
    posts.sort((a, b) {
      final aIndex =
          profileWithPosts.posts.toList().indexWhere((element) => element == a);
      final bIndex =
          profileWithPosts.posts.toList().indexWhere((element) => element == b);
      return aIndex - bIndex;
    });
    return ProfileWithPosts(user: profileWithPosts.user, posts: posts);
  }
});

final _profileStateNotifierProvider = StateNotifierProvider.autoDispose
    .family<ProfileStateNotifier, ProfileWithPosts?, String>((ref, userId) {
  final postsStateNotifier = ref.watch(postsProvider.notifier);

  return ProfileStateNotifier(postsStateNotifier: postsStateNotifier)
    ..loadProfile(userId);
});

class ProfileWithPosts {
  final Profile user;
  final List<Post> posts;

  ProfileWithPosts({
    required this.user,
    required this.posts,
  });
}

class ProfileStateNotifier extends StateNotifier<ProfileWithPosts?> {
  ProfileStateNotifier({required PostsStateNotifier postsStateNotifier})
      : _postsStateNotifier = postsStateNotifier,
        super(null);

  final PostsStateNotifier _postsStateNotifier;

  Future<void> loadProfile(String userId) async {
    final userData = await supabase
        .from('profiles')
        .select<Map<String, dynamic>>()
        .eq('id', userId)
        .single();
    final user = Profile.fromJson(userData);

    final postsData = await supabase
        .from('posts')
        .select<List<Map<String, dynamic>>>(
            '*, user:profiles(*), like_count:likes(count), my_like:likes(count)')
        .eq('my_like.user_id', supabase.auth.currentUser!.id)
        .eq('user_id', userId)
        .order('created_at')
        .limit(20);
    final posts = postsData.map(Post.fromJson).toList();

    _postsStateNotifier.addPosts(posts.toSet());

    state = ProfileWithPosts(user: user, posts: posts);
  }
}
