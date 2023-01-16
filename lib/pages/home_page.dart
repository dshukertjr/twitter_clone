import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:twitter_clone/components/post_cell.dart';
import 'package:twitter_clone/constants.dart';
import 'package:twitter_clone/models/post.dart';
import 'package:twitter_clone/pages/compose_post_page.dart';

enum HomeTab { timeline, search, notifications }

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  HomeTab _currentTab = HomeTab.timeline;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: IndexedStack(
        index: _currentTab.index,
        children: const [
          _TimelineTab(),
          _SearchTab(),
          _NotificationTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTab.index,
        onTap: (value) {
          setState(() {
            _currentTab = HomeTab.values[value];
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(FeatherIcons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(FeatherIcons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(FeatherIcons.bell),
            label: 'Notifications',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(ComposePostPage.route());
        },
        child: const Icon(FeatherIcons.plus),
      ),
    );
  }
}

class _TimelineTab extends StatefulWidget {
  const _TimelineTab();

  @override
  State<_TimelineTab> createState() => _TimelineTabState();
}

class _TimelineTabState extends State<_TimelineTab> {
  bool _loading = true;
  List<Post>? _posts;

  @override
  void initState() {
    super.initState();
    _getPosts();
  }

  Future<void> _getPosts() async {
    final data = await supabase
        .from('posts')
        .select<List<Map<String, dynamic>>>('*, user:users(*)');
    setState(() {
      _loading = false;
      _posts = data.map(Post.fromJson).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {},
      child: _loading
          ? preloader
          : _posts!.isEmpty
              ? const Center(
                  child: Text('No Posts'),
                )
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

class _SearchTab extends StatelessWidget {
  const _SearchTab();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('search tab'));
  }
}

class _NotificationTab extends StatelessWidget {
  const _NotificationTab();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('notification tab'));
  }
}
