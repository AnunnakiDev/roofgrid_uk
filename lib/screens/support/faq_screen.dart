import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:roofgrid_uk/navigation/home_back_button.dart';
import 'package:roofgrid_uk/widgets/main_drawer.dart';
import 'package:roofgrid_uk/widgets/section_header.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('FAQ'),
        actions: const [HomeBackButton()],
      ),
      drawer: const MainDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              title: 'Frequently Asked Questions',
              subtitle: 'Quick answers about RoofGrid UK',
            ),
            const SizedBox(height: 16),
            _buildFaqItem(
              context,
              question: 'What is RoofGrid UK?',
              answer:
                  'RoofGrid UK is a professional tool designed for roofers and construction professionals to calculate vertical batten gauge and horizontal tile spacing with precision and ease.',
            ),
            _buildFaqItem(
              context,
              question: 'Do I need to create an account?',
              answer:
                  'Yes, a free account is required to use the basic calculator functions. A Pro account gives you access to additional features like saving calculations, managing custom tiles, and more.',
            ),
            _buildFaqItem(
              context,
              question: 'What\'s the difference between the free and Pro version?',
              answer:
                  'The free version provides basic vertical and horizontal calculations. The Pro version includes advanced features like multiple rafters, custom tile management, saved calculations, and more customization options.',
            ),
            _buildFaqItem(
              context,
              question: 'How accurate are the calculations?',
              answer:
                  'Our calculations follow industry standards and best practices for roofing measurements. The results provide precise gauge measurements and spacing to ensure proper installation of roofing materials.',
            ),
            _buildFaqItem(
              context,
              question: 'Can I save my calculations?',
              answer:
                  'Yes, with a Pro account you can save your calculations for future reference. This feature is particularly useful for contractors working on multiple projects.',
            ),
            _buildFaqItem(
              context,
              question: 'How do I add custom tiles?',
              answer:
                  'Pro users can add custom tiles through the Tile Management section. You\'ll be able to specify dimensions, minimum/maximum gauge, and other properties that will be used in calculations.',
            ),
            _buildFaqItem(
              context,
              question: 'What if I need help with the app?',
              answer:
                  'You can contact our support team at support@roofgrid.uk for any technical assistance or questions about using the application.',
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Have more questions?',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () => context.go('/support/contact'),
                      icon: const Icon(Icons.email_outlined),
                      label: const Text('Contact Support'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(
    BuildContext context, {
    required String question,
    required String answer,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          iconColor: colorScheme.secondary,
          collapsedIconColor: colorScheme.onSurfaceVariant,
          title: Text(
            question,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: colorScheme.onSurface,
            ),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                answer,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  height: 1.45,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}