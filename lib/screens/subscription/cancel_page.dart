import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:roofgrid_uk/widgets/brand_wordmark.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:roofgrid_uk/navigation/home_back_button.dart';
import 'package:roofgrid_uk/navigation/subscription_nav.dart';
import 'package:roofgrid_uk/providers/developer_mode_provider.dart';
import 'package:roofgrid_uk/widgets/main_drawer.dart';

class CancelPage extends ConsumerStatefulWidget {
  const CancelPage({super.key});

  @override
  ConsumerState<CancelPage> createState() => _CancelPageState();
}

class _CancelPageState extends ConsumerState<CancelPage> {
  bool _isCancelling = false;

  Future<void> _cancelSubscription() async {
    setState(() {
      _isCancelling = true;
    });

    try {
      // Get the current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not authenticated");

      // Update Firestore to revert user to free role
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'role': 'free',
        'subscriptionId': null,
        'subscriptionPlan': null,
        'subscriptionStatus': 'cancelled',
        'subscriptionEndDate': null,
        'proTrialStartDate': null,
        'proTrialEndDate': null,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Show confirmation message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Subscription cancelled. You are now a free user.')),
      );

      // Navigate to Home
      context.go('/home');
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cancelling subscription: $error')),
      );
    } finally {
      setState(() {
        _isCancelling = false;
      });
    }
  }

  void _showCancelConfirmationDialog() {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Are You Sure?',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'By cancelling your Pro subscription, you will lose access to:',
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '• Advanced roof survey features\n'
              '• Priority support\n'
              '• Unlimited storage for survey data',
              style: GoogleFonts.poppins(
                fontSize: 14,
                height: 1.45,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'No, Keep Pro',
              style: GoogleFonts.poppins(color: colorScheme.secondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelSubscription();
            },
            child: Text(
              'Yes, Cancel',
              style: GoogleFonts.poppins(color: colorScheme.error),
            ),
          ),
        ],
      ).animate().fadeIn(duration: 600.ms),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              // Warning Icon with Animation
              Icon(
                Icons.warning_amber_rounded,
                color: colorScheme.error,
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
              // Cancellation Message with Fade-In Animation
              Text(
                'Cancel Your Pro Subscription',
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ).animate().fadeIn(
                    duration: 800.ms,
                    delay: 200.ms,
                  ),
              const SizedBox(height: 10),
              Text(
                'You can cancel your Pro subscription at any time. Please confirm if you’d like to proceed.',
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
              // Cancel Button with Slide Animation
              OutlinedButton.icon(
                onPressed: _isCancelling ? null : _showCancelConfirmationDialog,
                icon: _isCancelling
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cancel_outlined),
                label: const Text('Cancel Subscription'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.error,
                  side: BorderSide(
                    color: colorScheme.error.withValues(alpha: 0.6),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
              ).animate().slideY(
                    begin: 1.0,
                    end: 0.0,
                    duration: 800.ms,
                    delay: 600.ms,
                    curve: Curves.easeOut,
                  ),
              const SizedBox(height: 10),
              // Back Button
              TextButton.icon(
                onPressed: () => context.go('/home'),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Go Back'),
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
