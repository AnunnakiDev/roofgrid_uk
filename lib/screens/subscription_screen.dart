import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roofgrid_uk/navigation/home_back_button.dart';
import 'package:roofgrid_uk/navigation/subscription_nav.dart';
import 'package:roofgrid_uk/providers/auth_provider.dart';
import 'package:roofgrid_uk/providers/developer_mode_provider.dart';
import 'package:roofgrid_uk/widgets/main_drawer.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:roofgrid_uk/utils/roofgrid_api_client.dart';
import 'package:roofgrid_uk/widgets/brand_wordmark.dart';
import 'package:roofgrid_uk/widgets/section_header.dart';
import 'package:roofgrid_uk/widgets/settings/plan_status_card.dart';
import 'package:url_launcher/url_launcher.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _launchStripeUrl(String? url, {required String label}) async {
    if (url == null || url.isEmpty) {
      throw Exception('No $label URL returned from payment service');
    }

    final uri = Uri.tryParse(url);
    if (uri == null) {
      throw Exception('Invalid $label URL received');
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      throw Exception('Could not open $label in your browser');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() => _errorMessage = message);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Function to initiate Stripe Checkout
  Future<void> _startCheckoutSession(String plan) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await postAuthenticatedApi(
        '/createCheckoutSession',
        data: {'plan': plan},
      );
      final data = decodeApiJson(response);
      await _launchStripeUrl(
        data['sessionUrl'] as String?,
        label: 'checkout',
      );
    } catch (error) {
      _showError(error.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Function to open Stripe Customer Portal
  Future<void> _openCustomerPortal() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await postAuthenticatedApi(
        '/createCustomerPortalSession',
        data: {},
      );
      final data = decodeApiJson(response);
      await _launchStripeUrl(
        data['portalUrl'] as String?,
        label: 'customer portal',
      );
    } catch (error) {
      _showError(error.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value;
    final effectiveIsPro = ref.watch(effectiveIsProProvider);

    return Scaffold(
      appBar: AppBar(
        leading: effectiveIsPro
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/profile');
                  }
                },
              )
            : Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
        actions: effectiveIsPro ? const [HomeBackButton()] : null,
        title: BrandWordmark.compact(
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
      drawer: const MainDrawer(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                label: 'Subscription page description',
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .secondary
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .secondary
                          .withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    effectiveIsPro
                        ? 'You’re a Pro member — thank you for your support!'
                        : 'Upgrade to Pro for advanced roofing tools',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ).animate().fadeIn(duration: 600.ms),
              ),
              const SizedBox(height: 24),
              const SectionHeader(
                title: 'Free vs Pro',
                subtitle: 'Compare what’s included in each plan',
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildFeatureHeader(context),
                      const Divider(height: 24),
                      _buildFeatureRow(
                        context,
                        'Basic Calculations',
                        true,
                        true,
                      ),
                      _buildFeatureRow(
                        context,
                        'Save Results',
                        false,
                        true,
                      ),
                      _buildFeatureRow(
                        context,
                        'Tile Database Access',
                        false,
                        true,
                      ),
                      _buildFeatureRow(
                        context,
                        'Custom Tile Library',
                        false,
                        true,
                      ),
                      _buildFeatureRow(
                        context,
                        'Multiple Rafters/Widths',
                        false,
                        true,
                      ),
                      _buildFeatureRow(
                        context,
                        '2D Visualization',
                        false,
                        true,
                      ),
                      _buildFeatureRow(
                        context,
                        'Advanced Options',
                        false,
                        true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (user != null) ...[
                const SectionHeader(title: 'Your plan'),
                const SizedBox(height: 12),
                PlanStatusCard(
                  user: user,
                  effectiveIsPro: effectiveIsPro,
                ),
                const SizedBox(height: 16),
              ],
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            _errorMessage!,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      if (user?.isPro != true) ...[
                        Text(
                          'Choose your plan',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isLoading
                                    ? null
                                    : () => _startCheckoutSession('monthly'),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Monthly — £9.99'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isLoading
                                    ? null
                                    : () => _startCheckoutSession('annual'),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Annual — £99.99'),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed:
                                _isLoading ? null : _openCustomerPortal,
                            icon: _isLoading
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.manage_accounts_outlined),
                            label: const Text('Manage Subscription'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _isLoading
                                ? null
                                : () => context.go('/subscription/cancel'),
                            icon: const Icon(Icons.cancel_outlined),
                            label: const Text('Cancel Subscription'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor:
                                  Theme.of(context).colorScheme.error,
                              side: BorderSide(
                                color: Theme.of(context)
                                    .colorScheme
                                    .error
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar:
          effectiveIsPro ? null : const FreeSubscriptionNav(currentIndex: 1),
    );
  }

  Widget _buildFeatureHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            'Feature',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            'Free',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            'Pro',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: colorScheme.secondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureRow(
      BuildContext context, String feature, bool free, bool pro) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              feature,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          Expanded(
            child: Icon(
              free ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: free
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              size: 22,
            ),
          ),
          Expanded(
            child: Icon(
              pro ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: pro
                  ? colorScheme.secondary
                  : colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}
