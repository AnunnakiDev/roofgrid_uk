import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:roofgrid_uk/models/user_model.dart';
import 'package:roofgrid_uk/providers/auth_provider.dart';
import 'package:roofgrid_uk/providers/developer_mode_provider.dart';
import 'package:roofgrid_uk/theme/app_color_schemes.dart';

import 'package:roofgrid_uk/widgets/brand_wordmark.dart';
import 'package:roofgrid_uk/widgets/roof_grid_pattern.dart';

class MainDrawer extends ConsumerWidget {
  const MainDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final effectiveIsPro = ref.watch(effectiveIsProProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _DrawerHeader(
            userAsync: userAsync,
            effectiveIsPro: effectiveIsPro,
          ),
          _DrawerNavTile(
            icon: Icons.person_outline_rounded,
            title: 'My Profile',
            onTap: () {
              context.go('/profile');
              Navigator.pop(context);
            },
          ),
          _DrawerNavTile(
            icon: Icons.home_outlined,
            title: 'Home',
            onTap: () {
              context.go('/home');
              Navigator.pop(context);
            },
          ),
          _DrawerNavTile(
            icon: Icons.calculate_outlined,
            title: 'Calculator',
            onTap: () {
              Navigator.pop(context);
              context.go('/calculator');
            },
          ),
          _DrawerNavTile(
            icon: Icons.folder_outlined,
            title: effectiveIsPro ? 'Saved Results' : 'Saved Results (Pro)',
            locked: !effectiveIsPro,
            onTap: () {
              if (!effectiveIsPro) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Upgrade to Pro to access this feature'),
                  ),
                );
                context.go('/subscription');
              } else {
                context.go('/results');
              }
              Navigator.pop(context);
            },
          ),
          _DrawerNavTile(
            icon: Icons.grid_view_rounded,
            title: effectiveIsPro ? 'Manage Tiles' : 'Manage Tiles (Pro)',
            locked: !effectiveIsPro,
            onTap: () {
              if (!effectiveIsPro) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Upgrade to Pro to access this feature'),
                  ),
                );
                context.go('/subscription');
              } else {
                context.go('/tiles');
              }
              Navigator.pop(context);
            },
          ),
          if (!effectiveIsPro)
            _DrawerNavTile(
              icon: Icons.workspace_premium_outlined,
              title: 'Upgrade to Pro',
              highlight: true,
              onTap: () {
                context.go('/subscription');
                Navigator.pop(context);
              },
            ),
          ExpansionTile(
            leading: Icon(
              Icons.support_agent_outlined,
              color: colorScheme.secondary,
            ),
            iconColor: colorScheme.secondary,
            collapsedIconColor: colorScheme.onSurfaceVariant,
            title: Text(
              'Support',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
            children: [
              _DrawerSubTile(
                title: 'FAQ',
                onTap: () {
                  context.go('/support/faq');
                  Navigator.pop(context);
                },
              ),
              _DrawerSubTile(
                title: 'Legal',
                onTap: () {
                  context.go('/support/legal');
                  Navigator.pop(context);
                },
              ),
              _DrawerSubTile(
                title: 'Contact',
                onTap: () {
                  context.go('/support/contact');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          userAsync.when(
            data: (user) {
              if (user == null || user.role != UserRole.admin) {
                return const SizedBox.shrink();
              }
              return ExpansionTile(
                leading: Icon(
                  Icons.admin_panel_settings_outlined,
                  color: colorScheme.secondary,
                ),
                iconColor: colorScheme.secondary,
                collapsedIconColor: colorScheme.onSurfaceVariant,
                title: Text(
                  'Admin',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
                children: [
                  _DrawerSubTile(
                    title: 'Dashboard',
                    onTap: () {
                      context.go('/admin/dashboard');
                      Navigator.pop(context);
                    },
                  ),
                  _DrawerSubTile(
                    title: 'Users',
                    onTap: () {
                      context.go('/admin/users');
                      Navigator.pop(context);
                    },
                  ),
                  _DrawerSubTile(
                    title: 'Tiles',
                    onTap: () {
                      context.go('/admin/tiles');
                      Navigator.pop(context);
                    },
                  ),
                  _DrawerSubTile(
                    title: 'Analytics',
                    onTap: () {
                      context.go('/admin/stats');
                      Navigator.pop(context);
                    },
                  ),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const Divider(height: 1),
          _DrawerNavTile(
            icon: Icons.logout_rounded,
            title: 'Sign Out',
            destructive: true,
            onTap: () async {
              await ref.read(authProvider.notifier).signOut();
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  final AsyncValue<UserModel?> userAsync;
  final bool effectiveIsPro;

  const _DrawerHeader({
    required this.userAsync,
    required this.effectiveIsPro,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final onPrimary = colorScheme.onPrimary;

    return DrawerHeader(
      decoration: BoxDecoration(color: colorScheme.primary),
      child: Stack(
        fit: StackFit.expand,
        children: [
          RoofGridPattern(
            lineColor: onPrimary.withValues(alpha: 0.12),
            cellSize: 24,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              BrandWordmark.compact(color: onPrimary),
              const SizedBox(height: 12),
              userAsync.when(
                data: (user) {
                  if (user == null) {
                    return Text(
                      'Not signed in',
                      style: GoogleFonts.poppins(
                        color: onPrimary.withValues(alpha: 0.75),
                        fontSize: 14,
                      ),
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName ?? 'User',
                        style: GoogleFonts.poppins(
                          color: onPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email ?? 'No email',
                        style: GoogleFonts.poppins(
                          color: onPrimary.withValues(alpha: 0.75),
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      _PlanBadge(
                        user: user,
                        effectiveIsPro: effectiveIsPro,
                        onPrimary: onPrimary,
                      ),
                    ],
                  );
                },
                loading: () => CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(onPrimary),
                  strokeWidth: 2,
                ),
                error: (error, _) => Text(
                  'Error loading profile',
                  style: GoogleFonts.poppins(
                    color: onPrimary.withValues(alpha: 0.75),
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlanBadge extends StatelessWidget {
  final UserModel user;
  final bool effectiveIsPro;
  final Color onPrimary;

  const _PlanBadge({
    required this.user,
    required this.effectiveIsPro,
    required this.onPrimary,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final label = user.isAdmin
        ? 'Admin · ${effectiveIsPro ? 'Pro' : 'Free'}'
        : effectiveIsPro
            ? 'Pro'
            : 'Free';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: effectiveIsPro
            ? colorScheme.secondary
            : onPrimary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppColorSchemes.buttonRadius),
        border: Border.all(
          color: effectiveIsPro
              ? colorScheme.secondary
              : onPrimary.withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          color: effectiveIsPro ? colorScheme.onSecondary : onPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DrawerNavTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool locked;
  final bool highlight;
  final bool destructive;

  const _DrawerNavTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.locked = false,
    this.highlight = false,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final iconColor = destructive
        ? colorScheme.error
        : locked
            ? colorScheme.onSurfaceVariant.withValues(alpha: 0.45)
            : highlight
                ? colorScheme.secondary
                : colorScheme.secondary;

    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontWeight: highlight ? FontWeight.w600 : FontWeight.w500,
          color: destructive
              ? colorScheme.error
              : locked
                  ? colorScheme.onSurfaceVariant
                  : colorScheme.onSurface,
        ),
      ),
      trailing: locked
          ? Icon(
              Icons.lock_outline_rounded,
              size: 18,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            )
          : null,
      onTap: onTap,
    );
  }
}

class _DrawerSubTile extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _DrawerSubTile({
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 56, right: 16),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      onTap: onTap,
    );
  }
}