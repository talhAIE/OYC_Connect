import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_provider.dart';

/// Listens for app deep links (e.g. password reset). When user opens the app
/// via the reset link, recovers session and sets [recoveryPendingProvider] so
/// the router redirects to set-new-password.
class AppLinkHandler extends ConsumerStatefulWidget {
  const AppLinkHandler({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppLinkHandler> createState() => _AppLinkHandlerState();
}

class _AppLinkHandlerState extends ConsumerState<AppLinkHandler> {
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();
    _initAppLinks();
  }

  Future<void> _initAppLinks() async {
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      _handleLink(initialUri);
    }
    _linkSubscription = _appLinks.uriLinkStream.listen(_handleLink);
  }

  Future<void> _handleLink(Uri uri) async {
    final path = uri.toString();
    if (!path.contains('reset-password')) return;

    try {
      await Supabase.instance.client.auth.getSessionFromUrl(uri);
      if (!mounted) return;
      ref.read(recoveryPendingProvider.notifier).state = true;
    } catch (_) {
      // Expired or invalid link; user can request a new one from forgot-password
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
