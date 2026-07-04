import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:roofgrid_uk/models/user_model.dart';
import 'package:roofgrid_uk/providers/developer_mode_provider.dart';

import 'package:roofgrid_uk/widgets/admin_access_guard.dart';

/// Maps a location to the main shell tab index (0–3).
int shellTabIndexFromLocation(String location) {
  if (location.startsWith('/calculator')) return 1;
  if (location.startsWith('/results')) return 2;
  if (location.startsWith('/tiles')) return 3;
  return 0;
}

const _proGatedPaths = ['/results', '/tiles'];

bool isProGatedShellPath(String location) {
  return _proGatedPaths.any((path) => location.startsWith(path));
}

/// Pure redirect resolver used by [goRouterProvider] and tests.
String? resolveAppRedirect({
  required String location,
  required bool isAuthenticated,
  required bool effectiveIsPro,
  UserModel? currentUser,
}) {
  final isSplash = location == '/splash';
  final isAuthRoute = location.startsWith('/auth');
  final isAdminRoute = location.startsWith('/admin');

  if (isSplash) {
    return isAuthenticated ? '/home' : '/auth/login';
  }

  if (!isAuthenticated && !isAuthRoute) {
    return '/auth/login';
  }

  final isForgotPassword = location == '/auth/forgot-password';
  if (isAuthenticated && isAuthRoute && !isForgotPassword) {
    return '/home';
  }

  if (isAdminRoute) {
    if (!isAuthenticated) {
      return '/auth/login';
    }
    if (currentUser != null && !isAdminUser(currentUser)) {
      return '/home';
    }
  }

  if (isAuthenticated &&
      !effectiveIsPro &&
      (location == '/results' || location == '/tiles')) {
    return '/subscription';
  }

  return null;
}

void showProGateSnackBar(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Upgrade to Pro to access this feature'),
    ),
  );
}

/// Navigate to a shell tab, gating Results/Tiles for non-Pro users.
void navigateToShellTab(
  BuildContext context,
  WidgetRef ref,
  int index, {
  void Function(int index)? goBranch,
}) {
  if (index == 2 || index == 3) {
    final isPro = ref.read(effectiveIsProProvider);
    if (!isPro) {
      showProGateSnackBar(context);
      context.go('/subscription');
      return;
    }
  }

  if (goBranch != null) {
    goBranch(index);
    return;
  }

  switch (index) {
    case 0:
      context.go('/home');
    case 1:
      context.go('/calculator');
    case 2:
      context.go('/results');
    case 3:
      context.go('/tiles');
  }
}