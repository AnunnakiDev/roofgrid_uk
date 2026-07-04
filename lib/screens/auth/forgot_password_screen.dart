// screens/auth/forgot_password_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:roofgrid_uk/providers/auth_provider.dart';
import 'package:roofgrid_uk/widgets/auth_shell.dart';
import 'package:roofgrid_uk/widgets/brand_wordmark.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

// Rest of the file remains the same

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _resetSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate() || !mounted) return;

    setState(() => _isLoading = true);

    final authNotifier = ref.read(authProvider.notifier);
    final success =
        await authNotifier.resetPassword(_emailController.text.trim());

    if (!mounted) return;

    if (success) {
      await FirebaseAnalytics.instance.logEvent(name: 'password_reset_sent');
      if (!mounted) return;
      setState(() {
        _resetSent = true;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'If an account exists for this email, a reset link was sent.',
          ),
        ),
      );
    } else {
      setState(() => _isLoading = false);
      final error = ref.read(authProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error ?? 'Could not send reset link. Please try again.',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return AuthShell(
      showBackButton: true,
      onBack: () => context.go('/auth/login'),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BrandWordmark(fontSize: 28),
            const SizedBox(height: 24),
            Icon(
              _resetSent
                  ? Icons.check_circle_outline_rounded
                  : Icons.lock_reset_rounded,
              size: 72,
              color: _resetSent
                  ? Theme.of(context).colorScheme.secondary
                  : Theme.of(context).colorScheme.primary,
            ),
                  const SizedBox(height: 24),
                  Text(
                    _resetSent ? 'Reset Link Sent' : 'Forgot Password',
                    style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _resetSent
                        ? 'We\'ve sent a password reset link to ${_emailController.text}. Please check your inbox and spam folder.'
                        : 'Enter your email address below to receive a password reset link.',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  if (!_resetSent) ...[
                    if (authState.error != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          authState.error!,
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    if (authState.error != null) const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'Enter your email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading || authState.isLoading
                          ? null
                          : _resetPassword,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading || authState.isLoading
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color:
                                    Theme.of(context).colorScheme.onSecondary,
                              ),
                            )
                          : const Text('Send Reset Link'),
                    ),
                  ] else ...[
                    Text(
                      'No email after a few minutes?\n'
                      '• Check spam/promotions\n'
                      '• If you signed up with Google, use Google Sign-In on the login screen instead\n'
                      '• Password reset only works for email/password accounts',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.go('/auth/login'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Back to Login'),
                    ),
                  ],
                ],
        ),
      ),
    );
  }
}
