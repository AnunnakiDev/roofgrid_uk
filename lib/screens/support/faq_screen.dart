// lib/screens/support/faq_screen.dart
import 'package:flutter/material.dart';
import 'package:roofgrid_uk/widgets/main_drawer.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Frequently Asked Questions'),
      ),
      drawer: const MainDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Frequently Asked Questions',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 24),
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
              question:
                  'What\'s the difference between the free and Pro version?',
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
            const SizedBox(height: 32),
            Center(
              child: Text(
                'Have more questions?',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                icon: const Icon(Icons.email_outlined),
                label: const Text('Contact Support'),
                onPressed: () {
                  // TODO: Implement contact support functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Contact support coming soon!')),
                  );
                },
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
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(
            answer,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ],
    );
  }
}
