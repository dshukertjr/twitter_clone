import 'package:flutter/material.dart';
import 'package:twitter_clone/constants.dart';
import 'package:twitter_clone/models/user_profile.dart';

class ProfileImage extends StatelessWidget {
  final UserProfile user;
  final int size;

  const ProfileImage({
    super.key,
    required this.user,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: size / 2,
      foregroundImage:
          user.imageUrl == null ? null : NetworkImage(user.imageUrl!),
      backgroundImage: const NetworkImage(defaultProfileImageUrl),
    );
  }
}
