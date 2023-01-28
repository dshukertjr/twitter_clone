import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twitter_clone/components/post_cell.dart';
import 'package:twitter_clone/components/profile_image.dart';
import 'package:twitter_clone/constants.dart';
import 'package:twitter_clone/pages/chat_page.dart';
import 'package:twitter_clone/pages/edit_profile_page.dart';
import 'package:twitter_clone/state_notifiers/profile_state_notifier.dart';
import 'package:twitter_clone/state_notifiers/rooms_state_notifier.dart';

class ProfilePage extends ConsumerWidget {
  static Route<void> route(String userId) {
    return MaterialPageRoute(builder: ((context) {
      return ProfilePage(userId: userId);
    }));
  }

  const ProfilePage({
    super.key,
    required String userId,
  }) : _userId = userId;
  final String _userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileWithPosts = ref.watch(profileProvider(_userId));
    final posts = profileWithPosts?.posts;
    final user = profileWithPosts?.user;

    final myUserId = supabase.auth.currentUser!.id;
    final isMyProfile = myUserId == _userId;

    final roomsStateNotifier =
        ref.watch(roomsStateNotifierProvider(myUserId).notifier);
    return Scaffold(
      appBar: AppBar(),
      body: profileWithPosts == null
          ? preloader
          : ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ProfileImage(
                            user: user!,
                            size: 60,
                          ),
                          if (isMyProfile)
                            OutlinedButton(
                              style: ButtonStyle(
                                shape:
                                    MaterialStateProperty.all<OutlinedBorder>(
                                  const RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(20)),
                                  ),
                                ),
                                side: MaterialStateProperty.all<BorderSide>(
                                  const BorderSide(
                                      width: 1, color: Colors.grey),
                                ),
                                foregroundColor: MaterialStateColor.resolveWith(
                                    (states) => Colors.black),
                                padding: MaterialStateProperty.all<
                                    EdgeInsetsGeometry>(
                                  const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 0),
                                ),
                              ),
                              onPressed: () {
                                Navigator.of(context)
                                    .push(EditProfilePage.route());
                              },
                              child: const Text('Edit Profile'),
                            )
                          else
                            OutlinedButton(
                                onPressed: () {
                                  throw UnimplementedError(
                                      'Follow feature is unimplemented');
                                },
                                child: const Text('Follow'))
                        ],
                      ),
                      spacer,
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      spacer,
                      if (user.description != null &&
                          user.description!.isNotEmpty)
                        Text(user.description ?? ''),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: posts!
                      .map((post) => [
                            const Divider(height: 1),
                            PostCell(post: post),
                          ])
                      .expand((widget) => widget)
                      .toList(),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final roomId = await roomsStateNotifier.createRoom(_userId);
          if (context.mounted) {
            Navigator.of(context).push(ChatPage.route(roomId));
          }
        },
        child: const Icon(Icons.email_outlined),
      ),
    );
  }
}
