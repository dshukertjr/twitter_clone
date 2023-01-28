import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:twitter_clone/components/profile_image.dart';
import 'package:twitter_clone/constants.dart';
import 'package:twitter_clone/state_notifiers/auth_state_notifier.dart';
import 'package:twitter_clone/state_notifiers/timeline_state_notifier.dart';

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

  var _uploading = false;

  File? _imageFile;

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
    final timelineStateNotifer =
        ref.watch(timelineStateNotifierProvider.notifier);
    final authState = ref.watch(appAuthProvider);

    return Scaffold(
      appBar: AppBar(
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: ElevatedButton(
              onPressed: _postBodyController.text.isEmpty
                  ? null
                  : () async {
                      final body = _postBodyController.text;
                      if (body.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Please write something')));
                        return;
                      }
                      setState(() {
                        _uploading = true;
                      });

                      await timelineStateNotifer.createPost(
                        body: body,
                        imageFile: _imageFile,
                      );

                      if (mounted) {
                        Navigator.of(context).pop();
                      }
                    },
              child: const Text('Tweet'),
            ),
          ),
        ],
      ),
      body: _uploading
          ? preloader
          : SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: listPadding,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _profileImage(authState),
                          spacer,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextFormField(
                                  maxLength: 280,
                                  maxLines: null,
                                  autofocus: true,
                                  controller: _postBodyController,
                                  decoration: const InputDecoration(
                                    hintText: 'What\'s happening?',
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.all(0),
                                  ),
                                ),
                                if (_imageFile != null) ...[
                                  spacer,
                                  Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: Image.file(_imageFile!),
                                      ),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Material(
                                          color: Colors.black38,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(100),
                                          ),
                                          child: SizedBox(
                                            width: 32,
                                            height: 32,
                                            child: IconButton(
                                              iconSize: 24,
                                              padding: const EdgeInsets.all(0),
                                              color: Colors.white,
                                              onPressed: () {
                                                setState(() {
                                                  _imageFile = null;
                                                });
                                              },
                                              icon: const Icon(Icons.close),
                                            ),
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                ]
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        onPressed: () async {
                          final XFile? image = await ImagePicker()
                              .pickImage(source: ImageSource.gallery);
                          if (image == null) {
                            return;
                          }
                          setState(() {
                            _imageFile = File(image.path);
                          });
                        },
                        icon: const Icon(Icons.image_outlined),
                      ),
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          value: _postBodyController.text.length / 280,
                          backgroundColor: Colors.grey[300],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  ProfileImage _profileImage(AppAuthState authState) {
    if (authState is AppAuthProfileLoaded) {
      final user = authState.user;
      return ProfileImage(
        user: user,
        size: 30,
      );
    } else {
      return ProfileImage.empty(size: 30);
    }
  }
}
