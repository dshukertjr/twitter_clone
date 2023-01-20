import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twitter_clone/components/profile_image.dart';
import 'package:twitter_clone/models/post.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:twitter_clone/state_notifiers/posts_state_notifier.dart';

class PostCell extends ConsumerWidget {
  const PostCell({super.key, required Post post}) : _post = post;

  final Post _post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsStateNotifier = ref.watch(postsProvider.notifier);
    return Padding(
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
                if (_post.imageUrl != null) ...[
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      _post.imageUrl!,
                    ),
                  ),
                ],
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () async {
                        if (_post.haveLiked) {
                          postsStateNotifier.unlikePost(_post.id);
                        } else {
                          postsStateNotifier.likePost(_post.id);
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
                        _post.likeCount == 0 ? '' : _post.likeCount.toString(),
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
    );
  }
}
