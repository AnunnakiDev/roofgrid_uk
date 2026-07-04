import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:roofgrid_uk/models/user_model.dart';

/// Displays the user's plan tier, trial, and subscription details.
class PlanStatusCard extends StatelessWidget {
  final UserModel user;
  final bool effectiveIsPro;
  final bool showDevOverride;

  const PlanStatusCard({
    super.key,
    required this.user,
    required this.effectiveIsPro,
    this.showDevOverride = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = effectiveIsPro ? colorScheme.secondary : colorScheme.primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    effectiveIsPro
                        ? Icons.workspace_premium_rounded
                        : Icons.person_outline_rounded,
                    color: accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        effectiveIsPro
                            ? 'Pro Account${showDevOverride ? ' (dev)' : ''}'
                            : 'Free Account',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      if (user.isTrialActive)
                        Text(
                          'Trial: ${user.remainingTrialDays} days remaining',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      if (user.isTrialExpired)
                        Text(
                          'Trial expired',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: colorScheme.error,
                          ),
                        ),
                      if (user.isSubscribed && !user.isTrialActive)
                        Text(
                          'Subscribed until ${user.subscriptionEndDate?.toLocal().toString().split(' ')[0]}',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}