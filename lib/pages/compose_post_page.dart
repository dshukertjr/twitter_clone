import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twitter_clone/constants.dart';
import 'package:twitter_clone/pages/home_page.dart';

class ComposePostPage extends ConsumerStatefulWidget {
  /// Returns the inserted post if there are any
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
  ConsumerState<ComposePostPage> createState() => _ComposePostPageState();
}

class _ComposePostPageState extends ConsumerState<ComposePostPage> {
  final _postBodyController = TextEditingController();

  var _loading = false;

  @override
  void initState() {
    super.initState();
    _postBodyController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _postBodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final postsStateNotifier = ref.watch(postsProvider.notifier);
    return Scaffold(
      appBar: AppBar(
        actions: [
          ElevatedButton(
            onPressed: () async {
              final body = _postBodyController.text;
              if (body.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please write something')));
                return;
              }
              setState(() {
                _loading = true;
              });

              await postsStateNotifier.createPost(body);

              if (mounted) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('Tweet'),
          ),
        ],
      ),
      body: _loading
          ? preloader
          : SingleChildScrollView(
              padding: listPadding,
              child: TextFormField(
                maxLength: 280,
                maxLines: null,
                autofocus: true,
                controller: _postBodyController,
                decoration: const InputDecoration(
                  hintText: 'What\'s happening?',
                  border: InputBorder.none,
                ),
              ),
            ),
    );
  }
}
