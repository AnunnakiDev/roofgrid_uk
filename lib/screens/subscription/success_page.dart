import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:roofgrid_uk/navigation/home_back_button.dart';
import 'package:roofgrid_uk/widgets/brand_wordmark.dart';
import 'package:roofgrid_uk/navigation/subscription_nav.dart';
import 'package:roofgrid_uk/providers/developer_mode_provider.dart';
import 'package:roofgrid_uk/widgets/main_drawer.dart';

class SuccessPage extends ConsumerWidget {
  const SuccessPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final effectiveIsPro = ref.watch(effectiveIsProProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: BrandWordmark.compact(color: colorScheme.onPrimary),
        automaticallyImplyLeading: false,
        actions: const [HomeBackButton()],
      ),
      drawer: effectiveIsPro ? null : const MainDrawer(),
      body: Container(
        color: theme.scaffoldBackgroundColor,
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: colorScheme.secondary,
                size: 100,
              )
                  .animate()
                  .scale(
                    duration: 800.ms,
                    curve: Curves.elasticOut,
                  )
                  .fadeIn(
                    duration: 600.ms,
                  ),
              const SizedBox(height: 20),
              Text(
                'Subscription Successful!',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ).animate().fadeIn(
                    duration: 800.ms,
                    delay: 200.ms,
                  ),
              const SizedBox(height: 10),
              Text(
                'Welcome to RoofGrid Pro! You now have access to advanced roof survey features and more.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  height: 1.45,
                  color: colorScheme.onSurfaceVariant,
                ),
              ).animate().fadeIn(
                    duration: 800.ms,
                    delay: 400.ms,
                  ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () => context.go('/home'),
                icon: const Icon(Icons.home_outlined),
                label: const Text('Get Started'),
              ).animate().slideY(
                    begin: 1.0,
                    end: 0.0,
                    duration: 800.ms,
                    delay: 600.ms,
                    curve: Curves.easeOut,
                  ),
            ],
          ),
        ),
      ),
      bottomNavigationBar:
          effectiveIsPro ? null : const FreeSubscriptionNav(currentIndex: 1),
    );
  }
}