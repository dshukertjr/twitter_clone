import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twitter_clone/constants.dart';
import 'package:twitter_clone/models/profile.dart';

final appAuthProvider =
    StateNotifierProvider<AppAuthStateNotifier, AppAuthState>((ref) {
  return AppAuthStateNotifier().._setupAuthListener();
});

abstract class AppAuthState {}

class AppAuthSignedOut extends AppAuthState {}

class AppAuthSignedIn extends AppAuthState {}

class AppAuthProfileLoaded extends AppAuthState {
  final Profile user;

  AppAuthProfileLoaded(this.user);
}

class AppAuthStateNotifier extends StateNotifier<AppAuthState> {
  AppAuthStateNotifier() : super(AppAuthSignedOut());

  Profile? _user;

  void _setupAuthListener() {
    supabase.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      if (session != null) {
        state = AppAuthSignedIn();
        final data = await supabase
            .from('profiles')
            .select()
            .eq('id', session.user.id)
            .single();
        _user = Profile.fromJson(data);
        state = AppAuthProfileLoaded(_user!);
      }
    });
  }

  Future<void> updateProfile({
    required String name,
    required String? description,
    required File? imageFile,
  }) async {
    String? imagePath;
    final myUserId = supabase.auth.currentUser!.id;
    if (imageFile != null) {
      imagePath = '$myUserId/profile.${imageFile.path.split('.').last}';
      await supabase.storage.from('profiles').upload(
            imagePath,
            imageFile,
            // fileOptions: const FileOptions(upsert: true),
          );
    }
    await supabase.from('profiles').update({
      'name': name,
      'description': description,
      if (imageFile != null) 'image_path': imagePath,
    }).eq('id', myUserId);
    String? imageUrl;
    if (imagePath != null) {
      imageUrl = supabase.storage.from('profiles').getPublicUrl(imagePath);
    }
    _user = _user!.copyWith(
      name: name,
      description: description,
      imageUrl: imageUrl,
    );
    state = AppAuthProfileLoaded(_user!);
  }
}
