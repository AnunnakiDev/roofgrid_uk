import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:roofgrid_uk/utils/calculator_mode.dart';

/// Home hub calculator entry points — vertical, horizontal, and combined.
class CalculatorLaunchCards extends StatelessWidget {
  final void Function(CalculationTypeSelection type) onLaunch;

  const CalculatorLaunchCards({super.key, required this.onLaunch});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _CalculatorModeCard(
                  title: 'Vertical',
                  subtitle: 'Batten gauge',
                  icon: Icons.straighten_rounded,
                  semanticsLabel: 'Tap to calculate batten gauge',
                  onTap: () => onLaunch(CalculationTypeSelection.verticalOnly),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _CalculatorModeCard(
                  title: 'Horizontal',
                  subtitle: 'Marking out',
                  icon: Icons.auto_awesome_mosaic_rounded,
                  semanticsLabel: 'Tap to calculate marking out',
                  onTap: () =>
                      onLaunch(CalculationTypeSelection.horizontalOnly),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _CalculatorModeCard(
          title: 'Combined',
          subtitle:
              'Full roof layout — vertical batten gauge and horizontal marking out',
          icon: Icons.roofing_rounded,
          featured: true,
          semanticsLabel: 'Tap to calculate full roof layout',
          onTap: () => onLaunch(CalculationTypeSelection.both),
        ),
      ],
    );
  }
}

class _CalculatorModeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool featured;
  final String semanticsLabel;

  const _CalculatorModeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    required this.semanticsLabel,
    this.featured = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = colorScheme.secondary;

    return Semantics(
      label: semanticsLabel,
      button: true,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(featured ? 18 : 16),
            child: featured
                ? _FeaturedLayout(
                    title: title,
                    subtitle: subtitle,
                    icon: icon,
                    accent: accent,
                    primary: colorScheme.primary,
                    onSurface: colorScheme.onSurface,
                    onSurfaceVariant: colorScheme.onSurfaceVariant,
                  )
                : _CompactLayout(
                    title: title,
                    subtitle: subtitle,
                    icon: icon,
                    accent: accent,
                    onSurface: colorScheme.onSurface,
                    onSurfaceVariant: colorScheme.onSurfaceVariant,
                  ),
          ),
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final double size;

  const _IconBadge({
    required this.icon,
    required this.accent,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: accent, size: size * 0.55),
    );
  }
}

class _CompactLayout extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final Color onSurface;
  final Color onSurfaceVariant;

  const _CompactLayout({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.onSurface,
    required this.onSurfaceVariant,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 132,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IconBadge(icon: icon, accent: accent),
          const Spacer(),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: onSurfaceVariant,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Icon(
              Icons.arrow_forward_rounded,
              size: 20,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturedLayout extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final Color primary;
  final Color onSurface;
  final Color onSurfaceVariant;

  const _FeaturedLayout({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.primary,
    required this.onSurface,
    required this.onSurfaceVariant,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _IconBadge(icon: icon, accent: accent, size: 48),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: onSurfaceVariant,
                  height: 1.35,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Icon(Icons.arrow_forward_rounded, color: accent, size: 24),
      ],
    );
  }
}