import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twitter_clone/constants.dart';
import 'package:twitter_clone/models/post.dart';

final searchNotifierProvider =
    StateNotifierProvider<SearchStateNotifier, SearchState>((ref) {
  return SearchStateNotifier();
});

abstract class SearchState {}

class BeforeSearch extends SearchState {}

class SearchLoading extends SearchState {}

class SearchResultEmpty extends SearchState {}

class SearchLoaded extends SearchState {
  final List<Post> posts;

  SearchLoaded(this.posts);
}

class SearchStateNotifier extends StateNotifier<SearchState> {
  SearchStateNotifier() : super(BeforeSearch());

  Future<void> search(String query) async {
    state = SearchLoading();
    final data = await supabase
        .from('posts')
        .select<List<Map<String, dynamic>>>(
            '*, user:profiles(*), like_count:likes(count), my_like:likes(count)')
        .eq('my_like.user_id', supabase.auth.currentUser!.id)
        .textSearch('body', query)
        .order('created_at')
        .limit(20);
    final posts = data.map(Post.fromJson).toList();
    state = SearchLoaded(posts);
  }
}
