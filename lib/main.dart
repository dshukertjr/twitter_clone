import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:twitter_clone/constants.dart';
import 'package:twitter_clone/pages/home_page.dart';
import 'package:twitter_clone/pages/login_page.dart';

Future<void> main() async {
  await Supabase.initialize(
    url: 'https://nhwlewfmhomcxgaqbamn.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5od2xld2ZtaG9tY3hnYXFiYW1uIiwicm9sZSI6ImFub24iLCJpYXQiOjE2NzM3Njk0ODksImV4cCI6MTk4OTM0NTQ4OX0.Be-43W7144En6aSAs_v54jN_4QixL1fAykZf5A6tMMU',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Twitter Clone',
      home: StreamBuilder<AuthState>(
          stream: supabase.auth.onAuthStateChange,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.active) {
              return preloader;
            }
            final session = snapshot.data?.session;
            if (session == null) {
              return const LoginPage();
            } else {
              return const HomePage();
            }
          }),
    );
  }
}
