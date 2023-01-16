import 'package:flutter/material.dart';
import 'package:twitter_clone/constants.dart';

class ComposePostPage extends StatefulWidget {
  static Route<void> route() {
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
              await supabase.from('posts').insert({'body': body});
              if (mounted) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('Tweet'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: listPadding,
        child: TextFormField(
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
