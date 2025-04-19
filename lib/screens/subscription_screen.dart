import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roofgrid_uk/providers/auth_provider.dart';
import 'package:roofgrid_uk/widgets/main_drawer.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  // Function to initiate Stripe Checkout
  Future<void> _startCheckoutSession(String plan) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not authenticated");

      // Get the user's ID token for authentication
      final idToken = await user.getIdToken();

      // Call the Cloud Function to create a Stripe Checkout session
      final response = await http.post(
        Uri.parse('https://api-gbtz2ngl6q-uc.a.run.app/createCheckoutSession'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'data': {'plan': plan}, // 'monthly' or 'annual'
          'context': {'uid': user.uid},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final sessionUrl = data['sessionUrl'];

        // Redirect to Stripe Checkout (you'll need a mechanism to open the URL, e.g., url_launcher)
        // For simplicity, we'll assume the redirect happens in the app
        context.go('/subscription/success'); // Simulate redirect after payment
      } else {
        throw Exception('Failed to create checkout session: ${response.body}');
      }
    } catch (error) {
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Function to open Stripe Customer Portal
  Future<void> _openCustomerPortal() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not authenticated");

      // Get the user's ID token for authentication
      final idToken = await user.getIdToken();

      // Call the Cloud Function to create a Customer Portal session
      final response = await http.post(
        Uri.parse(
            'https://api-gbtz2ngl6q-uc.a.run.app/createCustomerPortalSession'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'data': {},
          'context': {'uid': user.uid},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final portalUrl = data['portalUrl'];

        // Redirect to the Stripe Customer Portal (you'll need a mechanism to open the URL, e.g., url_launcher)
        // For simplicity, we'll assume the redirect happens in the app
        context.go(
            '/subscription/success'); // Simulate redirect after portal access
      } else {
        throw Exception(
            'Failed to create customer portal session: ${response.body}');
      }
    } catch (error) {
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value;

    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(
          'RoofGrid UK',
          style: GoogleFonts.roboto(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1E88E5),
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
                  child: Text(
                    user?.isPro == true
                        ? 'You’re a Pro Member!'
                        : 'Upgrade to Pro for Advanced Features',
                    style: GoogleFonts.roboto(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E88E5),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ).animate().fadeIn(duration: 600.ms),
              ),
              const SizedBox(height: 24),
              Text(
                'Free vs Pro Features',
                style: GoogleFonts.roboto(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E88E5),
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
                        style: GoogleFonts.roboto(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color:
                              user?.isPro == true ? Colors.green : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (user?.isTrialActive == true)
                        Text(
                          'Trial Active - ${user!.remainingTrialDays} days remaining',
                          style: GoogleFonts.roboto(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                      if (user?.isTrialExpired == true)
                        Text(
                          'Trial Expired',
                          style: GoogleFonts.roboto(
                            fontSize: 16,
                            color: Colors.red,
                          ),
                        ),
                      if (user?.isSubscribed == true)
                        Text(
                          'Subscribed until ${user!.subscriptionEndDate?.toLocal().toString().split(' ')[0]}',
                          style: GoogleFonts.roboto(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                      const SizedBox(height: 16),
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Text(
                            _errorMessage!,
                            style: GoogleFonts.roboto(
                              fontSize: 14,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      if (user?.isPro != true) ...[
                        Text(
                          'Choose Your Plan:',
                          style: GoogleFonts.roboto(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E88E5),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              onPressed: _isLoading
                                  ? null
                                  : () => _startCheckoutSession('monthly'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E88E5),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white)
                                  : Text(
                                      'Monthly - £9.99',
                                      style: GoogleFonts.roboto(
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                            ElevatedButton(
                              onPressed: _isLoading
                                  ? null
                                  : () => _startCheckoutSession('annual'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E88E5),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white)
                                  : Text(
                                      'Annual - £99.99',
                                      style: GoogleFonts.roboto(
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ] else ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              onPressed:
                                  _isLoading ? null : _openCustomerPortal,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E88E5),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white)
                                  : Text(
                                      'Manage Subscription',
                                      style: GoogleFonts.roboto(
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                            ElevatedButton(
                              onPressed: _isLoading
                                  ? null
                                  : () => context.go('/subscription/cancel'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                'Cancel Subscription',
                                style: GoogleFonts.roboto(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3, // Highlight Subscription tab
        onTap: (index) {
          if (index == 0) context.go('/home');
          if (index == 1) context.go('/surveys');
          if (index == 2) context.go('/profile');
          if (index == 3) context.go('/subscription');
        },
        selectedItemColor: const Color(0xFF1E88E5),
        unselectedItemColor: const Color(0xFFB0BEC5),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Surveys'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(
              icon: Icon(Icons.subscriptions), label: 'Subscription'),
        ],
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
              style: GoogleFonts.roboto(fontSize: 16, color: Colors.black87),
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
