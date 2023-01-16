import 'package:flutter/material.dart';
import 'package:twitter_clone/constants.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  var _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('login'),
      ),
      body: _loading
          ? preloader
          : Form(
              key: _formKey,
              child: ListView(
                padding: listPadding,
                children: [
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      label: Text('Email'),
                    ),
                  ),
                  spacer,
                  ElevatedButton(
                    onPressed: () async {
                      if (!_formKey.currentState!.validate()) {
                        return;
                      }
                      setState(() {
                        _loading = true;
                      });
                      final email = _emailController.text;
                      await supabase.auth.signInWithOtp(
                        email: email,
                        emailRedirectTo: 'com.supabase://login',
                      );

                      setState(() {
                        _loading = false;
                      });
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Check your email inbox'),
                          ),
                        );
                      }
                    },
                    child: const Text('Login with magic link'),
                  ),
                ],
              ),
            ),
    );
  }
}
