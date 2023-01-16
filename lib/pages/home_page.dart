import 'package:flutter/material.dart';
import 'package:twitter_clone/components/post_cell.dart';
import 'package:twitter_clone/constants.dart';
import 'package:twitter_clone/models/post.dart';

enum HomeTab { timeline, search, notifications }

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold();
  }
}

class Timeline extends StatefulWidget {
  const Timeline({super.key});

  @override
  State<Timeline> createState() => _TimelineState();
}

class _TimelineState extends State<Timeline> {
  final bool _loading = false;
  List<Post>? _posts;

  @override
  void initState() {
    super.initState();
    _getPosts();
  }

  Future<void> _getPosts() async {
    final data = await supabase
        .from('posts')
        .select<List<Map<String, dynamic>>>('*, users(*)');
    setState(() {
      _posts = data.map(Post.fromJson).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {},
      child: _loading
          ? preloader
          : _posts == null
              ? const Center(child: Text('No Posts'))
              : ListView.separated(
                  itemCount: _posts!.length,
                  itemBuilder: ((context, index) {
                    final post = _posts![index];
                    return PostCell(post: post);
                  }),
                  separatorBuilder: (_, __) => const Divider(),
                ),
    );
  }
}
