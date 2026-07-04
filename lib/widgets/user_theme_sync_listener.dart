import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roofgrid_uk/providers/auth_provider.dart';
import 'package:roofgrid_uk/providers/theme_provider.dart';
import 'package:roofgrid_uk/utils/user_theme_settings.dart';

/// Applies Firestore colour-scheme updates after the first frame so theme
/// state is not mutated during another provider's build/init.
class UserThemeSyncListener extends ConsumerStatefulWidget {
  final Widget child;

  const UserThemeSyncListener({super.key, required this.child});

  @override
  ConsumerState<UserThemeSyncListener> createState() =>
      _UserThemeSyncListenerState();
}

class _UserThemeSyncListenerState extends ConsumerState<UserThemeSyncListener> {
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _subscription;
  ProviderSubscription<String?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _attachForUser(ref.read(authProvider).userId);
    });
    _authSubscription = ref.listenManual<String?>(
      authProvider.select((state) => state.userId),
      (previousUserId, userId) {
        _attachForUser(userId);
      },
    );
  }

  void _attachForUser(String? userId) {
    _subscription?.cancel();
    _subscription = null;
    if (userId == null) return;

    _subscription = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .snapshots()
        .listen(
      (snapshot) {
        final schemeId = colorSchemeIdFromUserData(snapshot.data());
        if (schemeId == null) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ref.read(themeProvider.notifier).applyUserColorSchemeFromCloud(
                schemeId,
              );
        });
      },
      onError: (error) {
        debugPrint('User theme sync error: $error');
      },
    );
  }

  @override
  void dispose() {
    _authSubscription?.close();
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}