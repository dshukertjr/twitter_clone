import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twitter_clone/constants.dart';
import 'package:twitter_clone/models/post.dart';
import 'package:twitter_clone/state_notifiers/posts_state_notifier.dart';

final searchStateProvider = Provider.family<SearchState, String>((ref, query) {
  final originalPosts = ref.watch(postsProvider);
  final searchPosts = ref.watch(searchNotifierProvider(query));

  if (searchPosts == null) {
    return BeforeSearch();
  } else {
    final posts = originalPosts.intersection(searchPosts).toList();
    posts.sort((a, b) {
      final aIndex = searchPosts.toList().indexWhere((element) => element == a);
      final bIndex = searchPosts.toList().indexWhere((element) => element == b);
      return aIndex - bIndex;
    });
    return SearchLoaded(posts);
  }
});

abstract class SearchState {}

class BeforeSearch extends SearchState {}

class SearchLoading extends SearchState {}

class SearchResultEmpty extends SearchState {}

class SearchLoaded extends SearchState {
  final List<Post> posts;

  SearchLoaded(this.posts);
}

final searchNotifierProvider =
    StateNotifierProvider.family<_SearchStateNotifier, Set<Post>?, String>(
        (ref, query) {
  final postsStateNotifier = ref.watch(postsProvider.notifier);

  return _SearchStateNotifier(postsStateNotifier: postsStateNotifier)
    ..search(query);
});

class _SearchStateNotifier extends StateNotifier<Set<Post>?> {
  _SearchStateNotifier({required PostsStateNotifier postsStateNotifier})
      : _postsStateNotifier = postsStateNotifier,
        super(null);

  final PostsStateNotifier _postsStateNotifier;

  Future<void> search(String query) async {
    state = null;
    final List data =
        await supabase.rpc('search_posts', params: {'query': query});
    final posts = data.map(Post.fromSearchResult).toSet();
    _postsStateNotifier.addPosts(posts);
    state = posts;
    try {
      await supabase.from('suggestions').upsert({
        'query': query,
        'created_at': 'now',
      });
    } catch (_) {
      // ignore error on suggestion insersion
    }
  }
}

final suggestionStateNotifierProvider =
    StateNotifierProvider<SuggestionStateNotifier, List<String>?>(
        (ref) => SuggestionStateNotifier()..loadSuggestions());

class SuggestionStateNotifier extends StateNotifier<List<String>?> {
  SuggestionStateNotifier() : super(null);

  Future<void> loadSuggestions() async {
    final data = await supabase
        .from('suggestions')
        .select<List<Map<String, dynamic>>>()
        .order('created_at');
    state = data.map((row) => row['query'] as String).toList();
  }
}
