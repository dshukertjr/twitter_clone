import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twitter_clone/components/post_cell.dart';
import 'package:twitter_clone/components/profile_image.dart';
import 'package:twitter_clone/constants.dart';
import 'package:twitter_clone/state_notifiers/profile_state_notifier.dart';

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
                      Align(
                        alignment: Alignment.centerLeft,
                        child: ProfileImage(
                          user: user!,
                          size: 60,
                        ),
                      ),
                      spacer,
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
    );
  }
}
