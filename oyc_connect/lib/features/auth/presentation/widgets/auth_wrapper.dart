import 'package:flutter/material.dart';

/// The router waits here until the launch link and recovery marker are checked.
/// Navigation has one owner: the router's recovery-aware redirect.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
