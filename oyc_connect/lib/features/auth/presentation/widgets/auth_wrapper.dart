import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authStateAsync = ref.watch(authStateProvider);

    return authStateAsync.when(
      data: (authState) {
        final session = authState.session;
        if (session != null) {
          // Use Future.microtask to avoid modification during build
          Future.microtask(() => context.go('/home'));
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else {
          // Use Future.microtask to avoid modification during build
          Future.microtask(() => context.go('/login'));
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
    );
  }
}
