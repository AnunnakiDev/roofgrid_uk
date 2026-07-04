import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:roofgrid_uk/providers/auth_provider.dart';
import 'package:roofgrid_uk/widgets/auth_shell.dart';
import 'package:roofgrid_uk/widgets/brand_wordmark.dart';

/// Fallback screen for email link completion on web or when the app resumes.
class EmailLinkScreen extends ConsumerStatefulWidget {
  const EmailLinkScreen({super.key});

  @override
  ConsumerState<EmailLinkScreen> createState() => _EmailLinkScreenState();
}

class _EmailLinkScreenState extends ConsumerState<EmailLinkScreen> {
  final _emailController = TextEditingController();
  bool _needsEmailConfirmation = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryCompleteFromCurrentLocation();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _tryCompleteFromCurrentLocation() async {
    final uri = Uri.base;
    if (!uri.queryParameters.containsKey('apiKey') &&
        !uri.toString().contains('/__/auth/links')) {
      return;
    }

    final success = await ref.read(authProvider.notifier).completeEmailLinkSignIn(
          emailLink: uri.toString(),
        );
    if (!mounted) return;

    if (success) {
      context.go('/home');
      return;
    }

    setState(() => _needsEmailConfirmation = true);
  }

  Future<void> _completeWithEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the email you used to request the link.')),
      );
      return;
    }

    final success = await ref.read(authProvider.notifier).completeEmailLinkSignIn(
          emailLink: Uri.base.toString(),
          email: email,
        );

    if (!mounted) return;
    if (success) {
      context.go('/home');
    } else {
      final error = ref.read(authProvider).error;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return AuthShell(
      showBackButton: true,
      onBack: () => context.go('/auth/login'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const BrandWordmark(fontSize: 28),
          const SizedBox(height: 24),
          Icon(
            _needsEmailConfirmation
                ? Icons.mark_email_read_outlined
                : Icons.link_rounded,
            size: 72,
            color: Theme.of(context).colorScheme.secondary,
          ),
            const SizedBox(height: 16),
            Text(
              _needsEmailConfirmation
                  ? 'Confirm your email'
                  : 'Check your email',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _needsEmailConfirmation
                  ? 'Open the sign-in link on this device, then confirm the email address it was sent to.'
                  : 'If you requested a sign-in link, open it on this device to continue. Password login remains available if you are on site with poor signal.',
              textAlign: TextAlign.center,
            ),
            if (authState.error != null) ...[
              const SizedBox(height: 16),
              Text(
                authState.error!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (_needsEmailConfirmation) ...[
              const SizedBox(height: 24),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: authState.isLoading ? null : _completeWithEmail,
                child: authState.isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Complete sign-in'),
              ),
            ],
            const SizedBox(height: 32),
            TextButton(
              onPressed: () => context.go('/auth/login'),
              child: const Text('Back to password login'),
            ),
          ],
      ),
    );
  }
}