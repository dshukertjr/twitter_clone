import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twitter_clone/constants.dart';
import 'package:twitter_clone/models/user_profile.dart';

final appAuthProvider =
    StateNotifierProvider<AppAuthStateNotifier, AppAuthState>((ref) {
  return AppAuthStateNotifier().._setupAuthListener();
});

abstract class AppAuthState {}

class AppAuthSignedOut extends AppAuthState {}

class AppAuthSignedIn extends AppAuthState {}

class AppAuthProfileLoaded extends AppAuthState {
  final UserProfile user;

  AppAuthProfileLoaded(this.user);
}

class AppAuthStateNotifier extends StateNotifier<AppAuthState> {
  AppAuthStateNotifier() : super(AppAuthSignedOut());

  UserProfile? _user;

  void _setupAuthListener() {
    supabase.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      if (session != null) {
        state = AppAuthSignedIn();
        final data = await supabase
            .from('users')
            .select()
            .eq('id', session.user.id)
            .single();
        _user = UserProfile.fromJson(data);
        state = AppAuthProfileLoaded(_user!);
      }
    });
  }
}
