import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:roofgrid_uk/models/user_model.dart';
import 'package:roofgrid_uk/theme/app_color_schemes.dart';

class ProfileSummaryWidget extends StatelessWidget {
  final UserModel user;
  final bool? effectiveIsPro;
  final bool isExpanded;
  final VoidCallback? onToggle;
  final bool headerOnly;

  const ProfileSummaryWidget({
    super.key,
    required this.user,
    this.effectiveIsPro,
    this.isExpanded = false,
    this.onToggle,
    this.headerOnly = false,
  });

  String _getInitials(String name) {
    final nameParts = name.trim().split(' ');
    if (nameParts.isEmpty) return 'U';
    if (nameParts.length == 1) return nameParts[0][0].toUpperCase();
    return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isPro = effectiveIsPro ?? user.isPro;
    final accent = colorScheme.secondary;

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
                  backgroundImage:
                      user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                  child: user.photoURL == null
                      ? Text(
                          _getInitials(user.displayName ?? 'User'),
                          style: GoogleFonts.poppins(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 22,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        user.displayName ?? 'User',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (headerOnly && user.email != null)
                        Text(
                          user.email!,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                if (!headerOnly && onToggle != null)
                  IconButton(
                    icon: Icon(
                      isExpanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    onPressed: onToggle,
                    tooltip: isExpanded ? 'Collapse profile' : 'Edit profile',
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _PlanBadge(
              user: user,
              isPro: isPro,
              accent: accent,
              headerOnly: headerOnly,
            ),
            if (!headerOnly && user.isTrialActive) ...[
              const SizedBox(height: 12),
              _StatusBanner(
                icon: Icons.access_time_rounded,
                title: 'Pro Trial: ${user.remainingTrialDays} days remaining',
                subtitle: 'Upgrade now to keep Pro features',
                actionLabel: 'Upgrade',
                onAction: () => context.go('/subscription'),
              ),
            ],
            if (!headerOnly && user.isSubscribed && !user.isTrialActive) ...[
              const SizedBox(height: 12),
              _StatusBanner(
                icon: Icons.star_rounded,
                title: 'Pro Subscription Active',
                subtitle:
                    'Valid until ${user.subscriptionEndDate!.toString().substring(0, 10)}',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PlanBadge extends StatelessWidget {
  final UserModel user;
  final bool isPro;
  final Color accent;
  final bool headerOnly;

  const _PlanBadge({
    required this.user,
    required this.isPro,
    required this.accent,
    required this.headerOnly,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final label = user.isAdmin
        ? 'Admin · ${isPro ? 'Pro' : 'Free'}'
        : isPro
            ? 'Pro Account'
            : 'Free Account';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppColorSchemes.inputRadius),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            user.isAdmin
                ? Icons.admin_panel_settings_rounded
                : isPro
                    ? Icons.workspace_premium_rounded
                    : Icons.person_outline_rounded,
            size: 18,
            color: accent,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          if (!headerOnly && !isPro) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => context.go('/subscription'),
              style: TextButton.styleFrom(
                foregroundColor: accent,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Upgrade',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _StatusBanner({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppColorSchemes.inputRadius),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: colorScheme.secondary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}