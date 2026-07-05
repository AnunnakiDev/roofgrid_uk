import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:roofgrid_uk/navigation/home_back_button.dart';
import 'package:roofgrid_uk/utils/labour_checkout_utils.dart';
import 'package:roofgrid_uk/widgets/main_drawer.dart';
import 'package:roofgrid_uk/widgets/section_header.dart';
import 'package:url_launcher/url_launcher.dart';

class LabourPricingUpsellScreen extends ConsumerStatefulWidget {
  const LabourPricingUpsellScreen({super.key});

  @override
  ConsumerState<LabourPricingUpsellScreen> createState() =>
      _LabourPricingUpsellScreenState();
}

class _LabourPricingUpsellScreenState
    extends ConsumerState<LabourPricingUpsellScreen> {
  bool _isCheckoutLoading = false;

  Future<void> _contactSupport() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'support@roofgrid.uk',
      queryParameters: {
        'subject': 'Labour Pricing Calculator add-on',
        'body':
            'Hi, I would like to enable the Labour Pricing Calculator add-on on my account.',
      },
    );
    final launched = await launchUrl(uri);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email support@roofgrid.uk to request access'),
        ),
      );
    }
  }

  Future<void> _startLabourCheckout() async {
    setState(() => _isCheckoutLoading = true);
    try {
      final sessionUrl = await createLabourCheckoutSessionUrl();
      final launched = await launchUrl(
        Uri.parse(sessionUrl),
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        throw Exception('Could not open checkout in your browser');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _isCheckoutLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Labour Pricing'),
        actions: const [HomeBackButton()],
      ),
      drawer: const MainDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              title: 'Labour Pricing Calculator',
              subtitle:
                  'Quote profitable day rates from UK roofing labour timings',
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.calculate_rounded,
                      size: 40,
                      color: colorScheme.secondary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Separate add-on',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'The Labour Pricing Calculator is a paid add-on, separate '
                      'from set-out Pro. It helps you build quotes from strip/install '
                      'timings, gang size, travel, and your target margin.',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _FeatureLine(
                      icon: Icons.payments_outlined,
                      text: 'Profitable day rate per man and per gang',
                    ),
                    _FeatureLine(
                      icon: Icons.tune_rounded,
                      text: 'Editable UK starter rates saved on your device',
                    ),
                    _FeatureLine(
                      icon: Icons.groups_outlined,
                      text: 'Direct customer and sub-contractor pricing modes',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isCheckoutLoading ? null : _startLabourCheckout,
                icon: _isCheckoutLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.shopping_cart_checkout_outlined),
                label: Text(
                  _isCheckoutLoading
                      ? 'Opening checkout…'
                      : 'Subscribe to labour add-on',
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _contactSupport,
                icon: const Icon(Icons.mail_outline_rounded),
                label: const Text('Request add-on access'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => context.go('/subscription'),
                child: const Text('View set-out Pro plans'),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Set-out Pro unlocks saved jobs and tile database. You can hold '
              'one subscription without the other.',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureLine({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: colorScheme.secondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}