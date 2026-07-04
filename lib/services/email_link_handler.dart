import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roofgrid_uk/providers/auth_provider.dart';
import 'package:roofgrid_uk/utils/email_link_auth_config.dart';

class EmailLinkHandler {
  EmailLinkHandler(this._ref);

  final Ref _ref;
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;
    _initialized = true;

    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      await _handleUri(initialUri);
    }

    _linkSubscription = _appLinks.uriLinkStream.listen(
      _handleUri,
      onError: (Object error) {
        debugPrint('Email link handler stream error: $error');
      },
    );
  }

  Future<void> dispose() async {
    await _linkSubscription?.cancel();
    _linkSubscription = null;
    _initialized = false;
  }

  Future<void> _handleUri(Uri uri) async {
    if (!EmailLinkAuthConfig.isEmailAuthLink(uri)) {
      return;
    }

    final authNotifier = _ref.read(authProvider.notifier);
    final pendingEmail = await authNotifier.getPendingEmailLinkEmail();
    await authNotifier.completeEmailLinkSignIn(
      emailLink: uri.toString(),
      email: pendingEmail,
    );
  }
}

final emailLinkHandlerProvider = Provider<EmailLinkHandler>((ref) {
  final handler = EmailLinkHandler(ref);
  ref.onDispose(handler.dispose);
  return handler;
});

final emailLinkHandlerInitializerProvider = FutureProvider<void>((ref) async {
  final handler = ref.watch(emailLinkHandlerProvider);
  await handler.initialize();
});