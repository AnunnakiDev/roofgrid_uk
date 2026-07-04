import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:roofgrid_uk/providers/auth_provider.dart';
import 'package:roofgrid_uk/widgets/brand_wordmark.dart';
import 'package:roofgrid_uk/widgets/roof_grid_pattern.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryNavigate(ref.read(currentUserProvider));
    });
  }

  void _tryNavigate(AsyncValue<dynamic> userAsync) {
    if (_navigated || !mounted) return;

    userAsync.when(
      data: (user) {
        _navigated = true;
        context.go(user == null ? '/auth/login' : '/home');
      },
      loading: () {},
      error: (error, _) {
        _navigated = true;
        context.go('/auth/login');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading user data: $error'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<dynamic>>(currentUserProvider, (_, next) {
      _tryNavigate(next);
    });

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: ColoredBox(
              color: colorScheme.surface,
              child: RoofGridPattern(
                lineColor: colorScheme.primary.withValues(alpha: 0.08),
                cellSize: 36,
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const BrandWordmark(fontSize: 40),
                const SizedBox(height: 12),
                Text(
                  'Precision roofing calculations',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),
                CircularProgressIndicator(
                  color: colorScheme.secondary,
                  strokeWidth: 2.5,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}