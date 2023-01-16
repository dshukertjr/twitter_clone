import 'package:flutter/material.dart';
import 'package:twitter_clone/models/post.dart';

class PostCell extends StatelessWidget {
  const PostCell({super.key, required Post post}) : _post = post;

  final Post _post;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Text(_post.body),
    );
  }
}
