import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:roofgrid_uk/navigation/nav_utils.dart';
import 'package:roofgrid_uk/theme/app_color_schemes.dart';

class QuickAccessItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool locked;

  const QuickAccessItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.locked = false,
  });
}

class QuickAccessRow extends StatelessWidget {
  final List<QuickAccessItem> items;

  const QuickAccessRow({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: items.map((item) {
        final accent = colorScheme.secondary;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: item.onTap,
                child: Container(
                  constraints: const BoxConstraints(minHeight: 84),
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: item.locked
                                  ? colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.12)
                                  : accent.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(
                                AppColorSchemes.buttonRadius,
                              ),
                            ),
                            child: Icon(
                              item.icon,
                              size: 22,
                              color: item.locked
                                  ? colorScheme.onSurfaceVariant
                                  : accent,
                            ),
                          ),
                          if (item.locked)
                            Positioned(
                              right: -4,
                              top: -4,
                              child: Icon(
                                Icons.lock_rounded,
                                size: 14,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.label,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

void navigateToProSubscription(BuildContext context) {
  showProGateSnackBar(context);
  context.go('/subscription');
}