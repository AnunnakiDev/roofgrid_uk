import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CancelPage extends StatefulWidget {
  const CancelPage({super.key});

  @override
  State<CancelPage> createState() => _CancelPageState();
}

class _CancelPageState extends State<CancelPage> {
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Are You Sure?',
          style: GoogleFonts.roboto(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E88E5),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'By cancelling your Pro subscription, you will lose access to:',
              style: GoogleFonts.roboto(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 10),
            Text(
              '• Advanced roof survey features\n'
              '• Priority support\n'
              '• Unlimited storage for survey data',
              style: GoogleFonts.roboto(fontSize: 14, color: Colors.black54),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'No, Keep Pro',
              style: GoogleFonts.roboto(color: const Color(0xFF1E88E5)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelSubscription();
            },
            child: Text(
              'Yes, Cancel',
              style: GoogleFonts.roboto(color: Colors.red),
            ),
          ),
        ],
      ).animate().fadeIn(duration: 600.ms),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'RoofGrid UK',
          style: GoogleFonts.roboto(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1E88E5),
        automaticallyImplyLeading: false,
      ),
      body: Container(
        color: const Color(0xFFF5F5F5),
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Warning Icon with Animation
              const Icon(
                Icons.warning,
                color: Colors.red,
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
                style: GoogleFonts.roboto(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E88E5),
                ),
              ).animate().fadeIn(
                    duration: 800.ms,
                    delay: 200.ms,
                  ),
              const SizedBox(height: 10),
              Text(
                'You can cancel your Pro subscription at any time. Please confirm if you’d like to proceed.',
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ).animate().fadeIn(
                    duration: 800.ms,
                    delay: 400.ms,
                  ),
              const SizedBox(height: 30),
              // Cancel Button with Slide Animation
              ElevatedButton(
                onPressed: _isCancelling ? null : _showCancelConfirmationDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isCancelling
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Cancel Subscription',
                        style: GoogleFonts.roboto(
                          fontSize: 18,
                          color: Colors.white,
                        ),
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
              TextButton(
                onPressed: () => context.go('/home'),
                child: Text(
                  'Go Back',
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    color: const Color(0xFF1E88E5),
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
}
