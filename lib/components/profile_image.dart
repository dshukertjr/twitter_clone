import 'package:flutter/material.dart';
import 'package:twitter_clone/constants.dart';
import 'package:twitter_clone/models/profile.dart';
import 'package:twitter_clone/pages/profile_page.dart';

class ProfileImage extends StatelessWidget {
  final Profile user;
  final int size;

  const ProfileImage({
    super.key,
    required this.user,
    this.size = 40,
  });

  ProfileImage.empty({super.key, this.size = 40})
      : user = Profile(
            id: 'id', name: 'name', imageUrl: null, description: 'description');

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(ProfilePage.route(user.id));
        },
        child: CircleAvatar(
          radius: size / 2,
          foregroundImage:
              user.imageUrl == null ? null : NetworkImage(user.imageUrl!),
          backgroundImage: const NetworkImage(defaultProfileImageUrl),
        ),
      ),
    );
  }
}
