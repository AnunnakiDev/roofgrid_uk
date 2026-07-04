import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:roofgrid_uk/providers/theme_provider.dart';
import 'package:roofgrid_uk/theme/app_color_schemes.dart';

/// Three preset colour scheme cards for the Appearance settings tab.
class ThemeSchemeSelector extends ConsumerWidget {
  final String? syncUserId;

  const ThemeSchemeSelector({super.key, this.syncUserId});

  static const _schemes = AppColorSchemeId.values;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeStateProvider);
    final brightness = Theme.of(context).brightness;

    return Column(
      children: [
        for (var i = 0; i < _schemes.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          _SchemeCard(
            schemeId: _schemes[i],
            selected: themeState.colorSchemeId == _schemes[i],
            brightness: brightness,
            onTap: () async {
              if (themeState.colorSchemeId == _schemes[i]) return;
              await ref.read(themeProvider.notifier).setColorSchemeId(
                    _schemes[i],
                    syncUserId: syncUserId,
                  );
            },
          ),
        ],
      ],
    );
  }
}

class _SchemeCard extends StatelessWidget {
  final AppColorSchemeId schemeId;
  final bool selected;
  final Brightness brightness;
  final VoidCallback onTap;

  const _SchemeCard({
    required this.schemeId,
    required this.selected,
    required this.brightness,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = AppColorSchemes.tokensFor(schemeId, brightness);
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppColorSchemes.cardRadius),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppColorSchemes.cardRadius),
            border: Border.all(
              color: selected
                  ? tokens.accent
                  : colorScheme.onSurface.withValues(alpha: 0.15),
              width: selected ? 2 : 1,
            ),
            color: colorScheme.surface,
          ),
          child: Row(
            children: [
              _SwatchPair(primary: tokens.primary, accent: tokens.accent),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      schemeId.displayName,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      schemeId.description,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle, color: tokens.accent, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwatchPair extends StatelessWidget {
  final Color primary;
  final Color accent;

  const _SwatchPair({required this.primary, required this.accent});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: _Swatch(color: primary, size: 28),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: _Swatch(color: accent, size: 28),
          ),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  final Color color;
  final double size;

  const _Swatch({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
    );
  }
}