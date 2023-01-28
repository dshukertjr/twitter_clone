import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart';
import 'package:twitter_clone/components/post_cell.dart';
import 'package:twitter_clone/components/profile_image.dart';
import 'package:twitter_clone/constants.dart';
import 'package:twitter_clone/models/app_notification.dart';
import 'package:twitter_clone/models/post.dart';
import 'package:twitter_clone/pages/chat_page.dart';
import 'package:twitter_clone/pages/compose_post_page.dart';
import 'package:twitter_clone/state_notifiers/auth_state_notifier.dart';
import 'package:twitter_clone/state_notifiers/notification_state_notifier.dart';
import 'package:twitter_clone/state_notifiers/rooms_state_notifier.dart';
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
      return SizedBox(
        width: 999,
        child: Material(
          color: Colors.grey[300],
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
          child: InkWell(
            onTap: () async {
              await showSearch(
                context: context,
                delegate: _CustomSearchDelegate(),
              );
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text('Keyword search'),
            ),
          ),
        ),
      );
    } else if (_currentTab == HomeTab.notifications) {
      return const Text('Notifications');
    } else {
      return const Text('Messages');
    }
  }

  @override
  Widget build(BuildContext context) {
    final appAuthState = ref.watch(appAuthProvider);
    final notificationsState = ref.watch(notificationsProvider);
    final myUserId = supabase.auth.currentUser!.id;
    final roomsState = ref.watch(roomsStateNotifierProvider(myUserId));

    final notificationsStateNotifier =
        ref.watch(notificationsProvider.notifier);
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
          children: [
            const _TimelineTab(),
            const _SearchTab(),
            const _NotificationTab(),
            _MessagesTab(myUserId: appAuthState.user.id),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentTab.index,
          onTap: (value) {
            final newTab = HomeTab.values[value];
            setState(() {
              _currentTab = newTab;
            });
            if (newTab == HomeTab.notifications) {
              notificationsStateNotifier.readNotification();
            }
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
              icon: _IconWithBadge(
                iconData: Icons.notifications_outlined,
                badgeCount: notificationsState is NotificationsLoaded
                    ? notificationsState.newNotificationCount
                    : 0,
              ),
              activeIcon: const Icon(Icons.notifications),
              label: 'Notifications',
            ),
            BottomNavigationBarItem(
              icon: _IconWithBadge(
                iconData: Icons.email_outlined,
                badgeCount:
                    roomsState is RoomsLoaded ? roomsState.unreadCount : 0,
              ),
              activeIcon: const Icon(Icons.email),
              label: 'Messages',
            ),
          ],
        ),
        floatingActionButton: _currentTab == HomeTab.messages
            ? null
            : FloatingActionButton(
                onPressed: () {
                  Navigator.of(context).push(ComposePostPage.route());
                },
                child: const Icon(Icons.add),
              ),
      );
    } else {
      throw UnimplementedError(
          'HomePage displayed with appAuthState: ${appAuthState.runtimeType}');
    }
  }
}

class _IconWithBadge extends StatelessWidget {
  const _IconWithBadge({
    Key? key,
    required this.iconData,
    required this.badgeCount,
  }) : super(key: key);

  final IconData iconData;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(iconData),
        if (badgeCount > 0)
          Positioned(
            right: -6,
            top: -6,
            child: Badge.count(
              count: badgeCount,
              backgroundColor: Theme.of(context).primaryColor,
            ),
          ),
      ],
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
        await postsStateNotifier.getPosts();
      },
      child: _timeline(postsState),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({
    Key? key,
    required List<Post> posts,
  })  : _posts = posts,
        super(key: key);

  final List<Post> _posts;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: _posts.length,
      itemBuilder: ((context, index) {
        final post = _posts[index];
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
    return const Center(child: Text('👆 Search something from the search bar'));
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
                              style: Theme.of(context).textTheme.bodyLarge,
                              text: notification.actor.name,
                              children: [
                                TextSpan(
                                  style: Theme.of(context).textTheme.bodyMedium,
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

class _MessagesTab extends ConsumerWidget {
  const _MessagesTab({
    required this.myUserId,
  });

  final String myUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsState = ref.watch(roomsStateNotifierProvider(myUserId));
    if (roomsState is RoomsLoading) {
      return preloader;
    } else if (roomsState is RoomsError) {
      return Center(child: Text(roomsState.message));
    } else if (roomsState is RoomsEmpty) {
      return const Center(child: Text('There are no messages yet'));
    } else if (roomsState is RoomsLoaded) {
      final rooms = roomsState.rooms;
      return ListView.builder(
        itemCount: rooms.length,
        itemBuilder: (context, index) {
          final room = rooms[index];
          final otherUser = room.otherUser;

          return ListTile(
            onTap: () => Navigator.of(context).push(ChatPage.route(room.id)),
            leading: room.otherUser == null
                ? ProfileImage.empty()
                : ProfileImage(user: room.otherUser!),
            title: Text(otherUser == null ? 'Loading...' : otherUser.name),
            subtitle: room.lastMessage != null
                ? Text(
                    room.lastMessage!.content,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : const Text('Room created'),
            trailing: Text(
              format(
                room.lastMessage?.createdAt ?? room.createdAt,
                locale: 'en_short',
              ),
            ),
          );
        },
      );
    }
    throw UnimplementedError('Unknown roomsState: ${roomsState.runtimeType}');
  }
}

class _CustomSearchDelegate extends SearchDelegate {
  @override
  Widget buildResults(BuildContext context) {
    return _SearchResults(query);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _Suggestions(
      onSuggestionTap: (suggestion) {
        query = suggestion;
        showResults(context);
      },
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.close),
      )
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return null;
  }
}

class _SearchResults extends ConsumerWidget {
  final String query;

  const _SearchResults(this.query);
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchPostsState = ref.watch(searchStateProvider(query));
    if (searchPostsState is SearchLoaded) {
      final posts = searchPostsState.posts;
      return _Timeline(posts: posts);
    } else {
      return preloader;
    }
  }
}

class _Suggestions extends ConsumerWidget {
  final void Function(String query) onSuggestionTap;

  const _Suggestions({required this.onSuggestionTap});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestions = ref.watch(suggestionStateNotifierProvider);
    if (suggestions == null) {
      return preloader;
    } else {
      return ListView.builder(
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          final suggestion = suggestions[index];
          return ListTile(
            onTap: () {
              onSuggestionTap(suggestion);
            },
            title: Text(suggestion),
          );
        },
      );
    }
  }
}
