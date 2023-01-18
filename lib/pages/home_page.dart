import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twitter_clone/components/post_cell.dart';
import 'package:twitter_clone/components/profile_image.dart';
import 'package:twitter_clone/constants.dart';
import 'package:twitter_clone/models/app_notification.dart';
import 'package:twitter_clone/models/post.dart';
import 'package:twitter_clone/pages/compose_post_page.dart';
import 'package:twitter_clone/state_notifiers/auth_state_notifier.dart';
import 'package:twitter_clone/state_notifiers/notification_state_notifier.dart';
import 'package:twitter_clone/state_notifiers/posts_state_notifier.dart';

enum HomeTab { timeline, search, notifications }

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  HomeTab _currentTab = HomeTab.timeline;

  Widget _appbarTitle() {
    if (_currentTab == HomeTab.timeline) {
      return Image.asset(
        'assets/logo.png',
        height: 40,
      );
    } else if (_currentTab == HomeTab.search) {
      return const Text('Search');
    } else {
      return const Text('Notifications');
    }
  }

  @override
  Widget build(BuildContext context) {
    final appAuthState = ref.watch(appAuthProvider);
    if (appAuthState is AppAuthProfileLoaded) {
      return Scaffold(
        appBar: AppBar(
          leading: Padding(
            padding: const EdgeInsets.all(12),
            child: ProfileImage(
              user: appAuthState.user,
              size: 56,
            ),
          ),
          centerTitle: _currentTab == HomeTab.timeline,
          title: _appbarTitle(),
        ),
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
          onPressed: () async {
            await Navigator.of(context).push(ComposePostPage.route());
          },
          child: const Icon(FeatherIcons.plus),
        ),
      );
    } else {
      throw UnimplementedError(
          'HomePage displayed with appAuthState: ${appAuthState.runtimeType}');
    }
  }
}

class _TimelineTab extends ConsumerWidget {
  const _TimelineTab();

  Widget _timeline(PostsState state) {
    if (state is PostsLoading) {
      return preloader;
    } else if (state is PostsLoaded) {
      final posts = state.posts;
      if (posts.isEmpty) {
        return const Center(child: Text('No Posts'));
      } else {
        return _Timeline(posts: posts);
      }
    } else {
      throw UnimplementedError();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsState = ref.watch(postsProvider);
    final postsStateNotifier = ref.watch(postsProvider.notifier);

    return RefreshIndicator(
      onRefresh: () async {
        postsStateNotifier.getPosts();
      },
      child: _timeline(postsState),
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

class _NotificationTab extends ConsumerWidget {
  const _NotificationTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsState = ref.watch(notificationsProvider);
    if (notificationsState is NotificationLoading) {
      return preloader;
    } else if (notificationsState is NotificationsLoaded) {
      final notifications = notificationsState.notifications;
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
        itemCount: notifications.length,
      );
    } else {
      throw UnimplementedError(
          'Unknown NotificationState ${notificationsState.runtimeType}');
    }
  }
}
