import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:roofgrid_uk/navigation/home_back_button.dart';
import 'package:roofgrid_uk/navigation/nav_utils.dart';
import 'package:roofgrid_uk/utils/customer_quote_checkout_utils.dart';
import 'package:roofgrid_uk/widgets/main_drawer.dart';
import 'package:roofgrid_uk/widgets/section_header.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomerQuoteUpsellScreen extends ConsumerStatefulWidget {
  const CustomerQuoteUpsellScreen({super.key});

  @override
  ConsumerState<CustomerQuoteUpsellScreen> createState() =>
      _CustomerQuoteUpsellScreenState();
}

class _CustomerQuoteUpsellScreenState
    extends ConsumerState<CustomerQuoteUpsellScreen> {
  bool _isCheckoutLoading = false;

  Future<void> _contactSupport() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'support@roofgrid.uk',
      queryParameters: {
        'subject': 'Customer Quote add-on',
        'body':
            'Hi, I would like to enable the Customer Quote add-on on my account.',
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

  Future<void> _startCheckout() async {
    setState(() => _isCheckoutLoading = true);
    try {
      final sessionUrl = await createCustomerQuoteCheckoutSessionUrl();
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
        title: const Text('Customer Quote'),
        actions: const [HomeBackButton()],
      ),
      drawer: const MainDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              title: 'Professional customer quotes',
              subtitle:
                  'Branded PDFs with your logo and company details for clients',
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.description_outlined,
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
                      'Customer Quote is a paid add-on on top of the Labour '
                      'Pricing Calculator. Export polished, client-ready PDFs '
                      'with your branding while keeping internal breakdown PDFs '
                      'for your own records.',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _FeatureLine(
                      icon: Icons.business_outlined,
                      text: 'Company logo, address, and VAT details',
                    ),
                    _FeatureLine(
                      icon: Icons.preview_outlined,
                      text: 'Live preview before sharing with customers',
                    ),
                    _FeatureLine(
                      icon: Icons.share_outlined,
                      text: 'Share branded PDF from your device',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isCheckoutLoading ? null : _startCheckout,
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
                      : 'Subscribe to customer quote',
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
                onPressed: () => context.go(labourCalculatorPath),
                child: const Text('Back to labour calculator'),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Requires the Labour Pricing Calculator add-on. Internal breakdown '
              'PDFs remain available with labour only.',
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