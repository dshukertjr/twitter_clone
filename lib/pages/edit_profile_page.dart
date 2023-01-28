import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:twitter_clone/components/profile_image.dart';
import 'package:twitter_clone/constants.dart';
import 'package:twitter_clone/state_notifiers/auth_state_notifier.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  static Route<void> route() {
    return MaterialPageRoute(builder: (context) => const EditProfilePage());
  }

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  File? _imageFile;

  var _uploading = false;

  @override
  void initState() {
    super.initState();
    final appAuthState = ref.read(appAuthProvider);
    String? name;
    String? description;
    if (appAuthState is AppAuthProfileLoaded) {
      name = appAuthState.user.name;
      description = appAuthState.user.description;
    }
    _nameController = TextEditingController(text: name);
    _descriptionController = TextEditingController(text: description);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(appAuthProvider);
    final authStateNotifier = ref.watch(appAuthProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: () async {
              if (!_formKey.currentState!.validate()) {
                return;
              }
              setState(() {
                _uploading = true;
              });
              final name = _nameController.text;
              final description = _descriptionController.text;
              await authStateNotifier.updateProfile(
                name: name,
                description: description,
                imageFile: _imageFile,
              );
              if (mounted) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: _body(authState),
      ),
    );
  }

  Widget _body(AppAuthState authState) {
    if (_uploading) {
      return preloader;
    }
    if (authState is AppAuthProfileLoaded) {
      final user = authState.user;
      return ListView(
        padding: listPadding,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Stack(
              children: [
                if (_imageFile == null)
                  ProfileImage(
                    user: user,
                    size: 80,
                  )
                else
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: ClipOval(
                      child: Image.file(
                        _imageFile!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                Positioned.fill(
                  child: Material(
                    borderRadius: BorderRadius.circular(100),
                    color: Colors.black38,
                    child: IconButton(
                      color: Colors.white.withOpacity(0.8),
                      iconSize: 40,
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
                      icon: const Icon(Icons.camera_alt_outlined),
                    ),
                  ),
                ),
              ],
            ),
          ),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              label: Text('Name'),
            ),
            validator: (val) {
              if (val == null || val.isEmpty) {
                return 'Please enter something';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              label: Text('Bio'),
            ),
            validator: (val) {
              return null;
            },
          ),
        ],
      );
    }
    return preloader;
  }
}
