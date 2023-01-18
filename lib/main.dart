import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:twitter_clone/constants.dart';
import 'package:twitter_clone/pages/home_page.dart';
import 'package:twitter_clone/pages/login_page.dart';

Future<void> main() async {
  await Supabase.initialize(
    url: 'https://iklpnvjgvkoqcdcjdoyw.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlrbHBudmpndmtvcWNkY2pkb3l3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE2NzM4NzEwMDMsImV4cCI6MTk4OTQ0NzAwM30.F7NwngvXo55C29pC5eBOp7FvUitjXASz9l88MdTrD0g',
  );
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Twitter Clone',
      theme: ThemeData.light().copyWith(
        appBarTheme: const AppBarTheme(
          elevation: 1,
          color: Colors.white,
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
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
