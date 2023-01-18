import 'package:flutter/material.dart';
import 'package:twitter_clone/components/profile_image.dart';
import 'package:twitter_clone/constants.dart';
import 'package:twitter_clone/models/post.dart';
import 'package:timeago/timeago.dart' as timeago;

class PostCell extends StatelessWidget {
  const PostCell({super.key, required Post post}) : _post = post;

  final Post _post;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.only(top: 12, right: 12, bottom: 0, left: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProfileImage(user: _post.user),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          _post.user.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyText1,
                        ),
                      ),
                      Text(
                        '・${timeago.format(
                          _post.createdAt,
                          locale: 'en_short',
                        )}',
                        style: const TextStyle(
                          fontWeight: FontWeight.normal,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  Text(_post.body),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () async {
                          if (_post.haveLiked) {
                            await supabase
                                .from('likes')
                                .delete()
                                .match({'post_id': _post.id});
                          } else {
                            await supabase
                                .from('likes')
                                .insert({'post_id': _post.id});
                          }
                        },
                        icon: Icon(
                          _post.haveLiked
                              ? Icons.favorite
                              : Icons.favorite_border,
                          size: 16,
                          color: _post.haveLiked ? Colors.pink : null,
                        ),
                        label: Text(
                          _post.likeCount == 0
                              ? ''
                              : _post.likeCount.toString(),
                          style: TextStyle(
                            color: _post.haveLiked ? Colors.pink : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
