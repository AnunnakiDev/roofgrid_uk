// lib/screens/support/legal_screen.dart
import 'package:flutter/material.dart';
import 'package:roofgrid_uk/widgets/main_drawer.dart';

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Legal Information'),
      ),
      drawer: const MainDrawer(),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            TabBar(
              tabs: const [
                Tab(text: 'Terms of Service'),
                Tab(text: 'Privacy Policy'),
              ],
              labelColor: Theme.of(context).colorScheme.primary,
              indicatorColor: Theme.of(context).colorScheme.primary,
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildTermsOfService(context),
                  _buildPrivacyPolicy(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsOfService(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Terms of Service',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            'Last Updated: April 9, 2025',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
          ),
          const SizedBox(height: 24),
          _buildLegalSection(
            context,
            title: '1. Acceptance of Terms',
            content:
                'By accessing and using RoofGrid UK, you accept and agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use our application.',
          ),
          _buildLegalSection(
            context,
            title: '2. Description of Service',
            content:
                'RoofGrid UK provides roofing calculation tools for professional and personal use. We offer both free and premium (Pro) services with different feature sets.',
          ),
          _buildLegalSection(
            context,
            title: '3. User Accounts',
            content:
                'You are responsible for maintaining the confidentiality of your account information and for all activities that occur under your account. You must notify us immediately of any unauthorized use of your account.',
          ),
          _buildLegalSection(
            context,
            title: '4. Subscription and Payment',
            content:
                'Pro subscriptions are billed on a recurring basis. You can cancel your subscription at any time, but no refunds will be provided for partially used subscription periods.',
          ),
          _buildLegalSection(
            context,
            title: '5. Accuracy of Calculations',
            content:
                'While we strive to provide accurate calculations, we do not guarantee the accuracy of all results. Users should verify all calculations with professional judgment.',
          ),
          _buildLegalSection(
            context,
            title: '6. Limitation of Liability',
            content:
                'RoofGrid UK shall not be liable for any direct, indirect, incidental, special, consequential or punitive damages resulting from your use or inability to use the service.',
          ),
          _buildLegalSection(
            context,
            title: '7. Modifications to Service',
            content:
                'We reserve the right to modify or discontinue the service at any time without notice. We shall not be liable to you or any third party for any modification, suspension, or discontinuance of the service.',
          ),
          _buildLegalSection(
            context,
            title: '8. Governing Law',
            content:
                'These Terms shall be governed by the laws of the United Kingdom without regard to its conflict of law provisions.',
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildPrivacyPolicy(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Privacy Policy',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            'Last Updated: April 9, 2025',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
          ),
          const SizedBox(height: 24),
          _buildLegalSection(
            context,
            title: '1. Information We Collect',
            content:
                'We collect personal information such as name, email address, and payment information for Pro subscriptions. We also collect usage data to improve our services.',
          ),
          _buildLegalSection(
            context,
            title: '2. How We Use Your Information',
            content:
                'We use your information to provide and improve our services, process payments, send notifications about your account, and provide customer support.',
          ),
          _buildLegalSection(
            context,
            title: '3. Data Storage and Security',
            content:
                'Your data is stored securely on our servers. We implement appropriate security measures to protect against unauthorized access or alteration of your data.',
          ),
          _buildLegalSection(
            context,
            title: '4. Sharing Your Information',
            content:
                'We do not sell or rent your personal information to third parties. We may share your information with service providers who help us operate our business.',
          ),
          _buildLegalSection(
            context,
            title: '5. Cookies and Tracking',
            content:
                'We use cookies and similar technologies to improve user experience, analyze usage patterns, and customize content.',
          ),
          _buildLegalSection(
            context,
            title: '6. Your Rights',
            content:
                'You have the right to access, correct, or delete your personal information. You may also request a copy of your data or object to certain processing.',
          ),
          _buildLegalSection(
            context,
            title: '7. Changes to This Policy',
            content:
                'We may update this privacy policy from time to time. We will notify you of any changes by posting the new policy on this page.',
          ),
          _buildLegalSection(
            context,
            title: '8. Contact Us',
            content:
                'If you have questions about this privacy policy or our data practices, please contact us at privacy@roofgrid.uk.',
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildLegalSection(
    BuildContext context, {
    required String title,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
