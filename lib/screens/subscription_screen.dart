import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roofgrid_uk/providers/auth_provider.dart';
import 'package:roofgrid_uk/widgets/main_drawer.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;

    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
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
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 1.0,
                    ),
                  ),
                  child: const Text(
                    'Upgrade to Pro for advanced features',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ).animate().fadeIn(duration: 600.ms),
              ),
              const SizedBox(height: 24),
              Text(
                'Free vs Pro Features',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
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
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Plan: ${user?.isPro == true ? "Pro" : "Free"}',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: user?.isPro == true
                                      ? Colors.green
                                      : Colors.grey,
                                ),
                      ),
                      const SizedBox(height: 8),
                      if (user?.isTrialActive == true)
                        Text(
                          'Trial Active - ${user!.remainingTrialDays} days remaining',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      if (user?.isTrialExpired == true)
                        Text(
                          'Trial Expired',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.red,
                                  ),
                        ),
                      if (user?.isSubscribed == true)
                        Text(
                          'Subscribed until ${user!.subscriptionEndDate?.toLocal().toString().split(' ')[0]}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      const SizedBox(height: 16),
                      if (user?.isPro != true)
                        ElevatedButton(
                          onPressed: () async {
                            await ref
                                .read(authProvider.notifier)
                                .upgradeToProStatus();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Upgraded to Pro!')),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                          ),
                          child: const Text('Upgrade to Pro Now'),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(
      BuildContext context, String feature, bool free, bool pro) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              feature,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          Row(
            children: [
              Icon(
                free ? Icons.check_circle : Icons.cancel,
                color: free ? Colors.green : Colors.grey,
              ),
              const SizedBox(width: 16),
              Icon(
                pro ? Icons.check_circle : Icons.cancel,
                color: pro ? Colors.green : Colors.grey,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
