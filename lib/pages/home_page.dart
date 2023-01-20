import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twitter_clone/components/post_cell.dart';
import 'package:twitter_clone/components/profile_image.dart';
import 'package:twitter_clone/constants.dart';
import 'package:twitter_clone/models/app_notification.dart';
import 'package:twitter_clone/models/post.dart';
import 'package:twitter_clone/pages/compose_post_page.dart';
import 'package:twitter_clone/state_notifiers/auth_state_notifier.dart';
import 'package:twitter_clone/state_notifiers/notification_state_notifier.dart';
import 'package:twitter_clone/state_notifiers/search_state_notifier.dart';
import 'package:twitter_clone/state_notifiers/timeline_state_notifier.dart';

enum HomeTab { timeline, search, notifications, messages }

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
    final notificationsState = ref.watch(notificationsProvider);

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
            _MessagesTab(),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentTab.index,
          onTap: (value) {
            setState(() {
              _currentTab = HomeTab.values[value];
            });
          },
          showSelectedLabels: false,
          showUnselectedLabels: false,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.search_outlined),
              activeIcon: Icon(Icons.search),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications_outlined),
                  if (notificationsState is NotificationsLoaded &&
                      notificationsState.newNotificationCount > 0)
                    Positioned(
                      right: -6,
                      top: -6,
                      child: _Badge(
                          label: notificationsState.newNotificationCount
                              .toString()),
                    ),
                ],
              ),
              activeIcon: const Icon(Icons.notifications),
              label: 'Notifications',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.email_outlined),
              activeIcon: Icon(Icons.email),
              label: 'Messages',
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            if (_currentTab == HomeTab.messages) {
// TODO handle composing new messages
            } else {
              Navigator.of(context).push(ComposePostPage.route());
            }
          },
          child: _currentTab == HomeTab.messages
              ? const Icon(Icons.email_outlined)
              : const Icon(Icons.add),
        ),
      );
    } else {
      throw UnimplementedError(
          'HomePage displayed with appAuthState: ${appAuthState.runtimeType}');
    }
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    Key? key,
    required this.label,
  }) : super(key: key);

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(
          Radius.circular(20),
        ),
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: Padding(
        padding: const EdgeInsets.all(1.5),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(
              Radius.circular(20),
            ),
            color: Theme.of(context).primaryColor,
          ),
          child: Padding(
            padding: const EdgeInsets.all(1.5),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: 10,
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 8,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TimelineTab extends ConsumerWidget {
  const _TimelineTab();

  Widget _timeline(TimelineState state) {
    if (state is TimelineLoading) {
      return preloader;
    } else if (state is TimelineLoaded) {
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
    final postsState = ref.watch(timelineStateProvider);
    final postsStateNotifier =
        ref.watch(timelineStateNotifierProvider.notifier);

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

class _SearchTab extends ConsumerWidget {
  const _SearchTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchState = ref.watch(searchNotifierProvider);
    if (searchState is BeforeSearch) {
      return const Center(child: Text('Start searching'));
    } else if (searchState is SearchLoading) {
      return preloader;
    } else if (searchState is SearchResultEmpty) {
      return const Center(child: Text('We couldn\'t find anything'));
    } else if (searchState is SearchLoaded) {
      final posts = searchState.posts;
      return _Timeline(posts: posts);
    }
    throw UnimplementedError('Unknown SearchState: ${searchState.runtimeType}');
  }
}

class _NotificationTab extends ConsumerWidget {
  const _NotificationTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsState = ref.watch(notificationsProvider);
    if (notificationsState is NotificationLoading) {
      return preloader;
    } else if (notificationsState is EmptyNotification) {
      return const Center(child: Text('There are no notifications.'));
    } else if (notificationsState is NotificationsLoaded) {
      final notifications = notificationsState.notifications;
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

class _MessagesTab extends StatelessWidget {
  const _MessagesTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Messages'),
    );
  }
}
