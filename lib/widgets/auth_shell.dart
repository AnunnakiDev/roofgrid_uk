import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:roofgrid_uk/widgets/roof_grid_pattern.dart';

/// Shared centred layout for auth screens (max-width card on wide viewports).
class AuthShell extends StatelessWidget {
  final Widget child;
  final bool showBackButton;
  final VoidCallback? onBack;

  const AuthShell({
    super.key,
    required this.child,
    this.showBackButton = false,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: showBackButton
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              foregroundColor: colorScheme.onSurface,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: onBack ?? () => Navigator.of(context).maybePop(),
              ),
            )
          : null,
      body: Stack(
        children: [
          Positioned.fill(
            child: ColoredBox(
              color: colorScheme.surface,
              child: RoofGridPattern(
                lineColor: colorScheme.primary.withValues(alpha: 0.07),
                cellSize: 32,
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: DefaultTextStyle(
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: colorScheme.onSurface,
                        ),
                        child: child,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}