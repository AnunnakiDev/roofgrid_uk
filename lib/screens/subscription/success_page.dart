import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SuccessPage extends StatelessWidget {
  const SuccessPage({super.key});

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
              // Success Icon with Animation
              const Icon(
                Icons.check_circle,
                color: Color(0xFF1E88E5),
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
              // Success Message with Fade-In Animation
              Text(
                'Subscription Successful!',
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
                'Welcome to RoofGrid Pro! You now have access to advanced roof survey features and more.',
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
              // Button to Return to Home with Slide Animation
              ElevatedButton(
                onPressed: () {
                  context.go('/home'); // Navigate to Home screen
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E88E5),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Get Started',
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
