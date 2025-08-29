import 'package:flutter/material.dart';
import 'package:geolab/features/Auth/SignInPage.dart';

class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  State<AuthCheck> createState() => _AuthCheckPageState();
}

class _AuthCheckPageState extends State<AuthCheck> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // Add slight delay to allow context to be available
    await Future.delayed(Duration.zero);

    if (!mounted) return;

    // For now, always navigate to Sign In
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SignInPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
