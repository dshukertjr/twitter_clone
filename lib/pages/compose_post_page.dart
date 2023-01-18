import 'package:flutter/material.dart';
import 'package:twitter_clone/constants.dart';
import 'package:twitter_clone/models/post.dart';

class ComposePostPage extends StatefulWidget {
  /// Returns the inserted post if there are any
  static Route<Post?> route() {
    return MaterialPageRoute(
      fullscreenDialog: true,
      builder: ((context) {
        return const ComposePostPage();
      }),
    );
  }

  const ComposePostPage({super.key});

  @override
  State<ComposePostPage> createState() => _ComposePostPageState();
}

class _ComposePostPageState extends State<ComposePostPage> {
  final _postController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _postController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          ElevatedButton(
            onPressed: () async {
              final body = _postController.text;
              if (body.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please write something')));
                return;
              }
              final insertedData = await supabase
                  .from('posts')
                  .insert({'body': body})
                  .select<Map<String, dynamic>>()
                  .single();
              final data = await supabase
                  .from('posts')
                  .select<Map<String, dynamic>>(
                      '*, user:users(*), like_count:likes(count), my_like:likes(count)')
                  .match({
                'id': insertedData['id'],
                'my_like.user_id': supabase.auth.currentUser!.id,
              }).single();
              final post = Post.fromJson(data);

              /// bring inserting logic to posts state notifier

              if (mounted) {
                Navigator.of(context).pop(post);
              }
            },
            child: const Text('Tweet'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: listPadding,
        child: TextFormField(
          maxLength: 280,
          maxLines: null,
          autofocus: true,
          controller: _postController,
          decoration: const InputDecoration(
            hintText: 'What\'s happening?',
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }
}
