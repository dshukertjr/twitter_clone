// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:twitter_clone/constants.dart';
// import 'package:twitter_clone/models/post.dart';

// final searchNotifierProvider =
//     StateNotifierProvider<SearchStateNotifier, SearchState>((ref) {
//   return SearchStateNotifier();
// });

// abstract class SearchState {}

// class BeforeSearch extends SearchState {}

// class SearchLoading extends SearchState {}

// class SearchResultEmpty extends SearchState {}

// class SearchLoaded extends SearchState {
//   final List<Post> posts;

//   SearchLoaded(this.posts);
// }

// class SearchStateNotifier extends StateNotifier<SearchState> {
//   SearchStateNotifier() : super(BeforeSearch());

//   Future<void> search(String query) async {
//     state = SearchLoading();
//     final data = await supabase.rpc('serach_posts', params: {'query': query});
//     final posts = data.map(Post.fromSearchResult(data)).toList();
//     state = SearchLoaded(posts);
//   }
// }
