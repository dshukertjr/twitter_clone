import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:twitter_clone/components/post_cell.dart';
import 'package:twitter_clone/components/profile_image.dart';
import 'package:twitter_clone/constants.dart';
import 'package:twitter_clone/models/app_notification.dart';
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

  List<Post>? _posts;
  bool _isTimelineLoading = true;

  @override
  void initState() {
    super.initState();
    _getPosts();
  }

  Future<void> _getPosts() async {
    final data = await supabase
        .from('posts')
        .select<List<Map<String, dynamic>>>(
            '*, user:users(*), like_count:likes(count), my_like:likes(count)')
        .eq('my_like.user_id', supabase.auth.currentUser!.id)
        .order('created_at')
        .limit(20);
    setState(() {
      _isTimelineLoading = false;
      _posts = data.map(Post.fromJson).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: IndexedStack(
        index: _currentTab.index,
        children: [
          _TimelineTab(
            posts: _posts,
            loading: _isTimelineLoading,
          ),
          const _SearchTab(),
          const _NotificationTab(),
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
        onPressed: () async {
          final post =
              await Navigator.of(context).push(ComposePostPage.route());
          if (post != null) {
            setState(() {
              if (_posts == null) {
                _posts = [post];
              } else {
                _posts!.insert(0, post);
              }
            });
          }
        },
        child: const Icon(FeatherIcons.plus),
      ),
    );
  }
}

class _TimelineTab extends StatelessWidget {
  final List<Post>? _posts;
  final bool _loading;
  const _TimelineTab({
    required List<Post>? posts,
    required bool loading,
  })  : _posts = posts,
        _loading = loading;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {},
      child: _loading || _posts == null
          ? preloader
          : _posts!.isEmpty
              ? const Center(
                  child: Text('No Posts'),
                )
              : _Timeline(posts: _posts),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({
    Key? key,
    required List<Post>? posts,
  })  : _posts = posts,
        super(key: key);

  final List<Post>? _posts;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: _posts!.length,
      itemBuilder: ((context, index) {
        final post = _posts![index];
        return PostCell(post: post);
      }),
      separatorBuilder: (_, __) => const Divider(height: 1),
    );
  }
}

class _SearchTab extends StatefulWidget {
  const _SearchTab();

  @override
  State<_SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<_SearchTab> {
  Future<void> search(String query) async {
    setState(() {
      _loading = true;
    });
    final data = await supabase
        .from('posts')
        .select<List<Map<String, dynamic>>>(
            '*, user:users(*), like_count:likes(count), my_like:likes(count)')
        .eq('my_like.user_id', supabase.auth.currentUser!.id)
        .textSearch('body', query)
        .order('created_at')
        .limit(20);
    setState(() {
      _loading = false;
      _posts = data.map(Post.fromJson).toList();
    });
  }

  List<Post>? _posts;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return preloader;
    }
    if (_posts == null) {
      return const Center(child: Text('Search something'));
    }
    if (_posts!.isEmpty) {
      return const Center(child: Text('We couldn\'t find anything'));
    }
    return _Timeline(posts: _posts);
  }
}

class _NotificationTab extends StatefulWidget {
  const _NotificationTab();

  @override
  State<_NotificationTab> createState() => _NotificationTabState();
}

class _NotificationTabState extends State<_NotificationTab> {
  List<AppNotification>? _notifications;
  bool _loading = true;
  late final RealtimeChannel _realtimeChannel;

  @override
  void initState() {
    super.initState();
    _getNotifications();
    _setupRealtimeListener();
  }

  Future<void> _getNotifications() async {
    final data = await supabase
        .from('notifications_view')
        .select<List<Map<String, dynamic>>>()
        .order('created_at')
        .limit(20);
    setState(() {
      _notifications = data.map(AppNotification.fromJson).toList();
      _loading = false;
    });
  }

  void _setupRealtimeListener() {
    _realtimeChannel = supabase.channel('notification');
    _realtimeChannel.on(
        RealtimeListenTypes.postgresChanges,
        ChannelFilter(
          event: 'INSERT',
          schema: 'public',
          table: 'notifications',
        ), (payload, [ref]) {
      _getNotifications();
    }).subscribe();
  }

  @override
  void dispose() {
    supabase.removeChannel(_realtimeChannel);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return preloader;
    }
    final notifications = _notifications!;
    if (notifications.isEmpty) {
      return const Center(child: Text('There are no notifications.'));
    }
    return ListView.separated(
        itemBuilder: ((context, index) {
          final notification = notifications[index];
          if (notification is LikeNotification) {
            return Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 16),
                    child: Icon(
                      Icons.favorite,
                      color: Colors.pink,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ProfileImage(
                          user: notification.actor,
                          size: 30,
                        ),
                        const SizedBox(height: 4),
                        RichText(
                          text: TextSpan(
                              style: Theme.of(context).textTheme.bodyText1,
                              text: notification.actor.name,
                              children: [
                                TextSpan(
                                  style: Theme.of(context).textTheme.bodyText2,
                                  text: ' liked your Tweet',
                                ),
                              ]),
                        ),
                        Text(
                          notification.post.body,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          } else {
            return const SizedBox();
          }
        }),
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemCount: notifications.length);
  }
}
