import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:roofgrid_uk/providers/auth_provider.dart';
import 'package:roofgrid_uk/widgets/auth_shell.dart';
import 'package:roofgrid_uk/widgets/brand_wordmark.dart';
import 'package:roofgrid_uk/widgets/captcha_widget.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _captchaToken;
  bool _rememberMe = false;
  bool _obscurePassword = true;
  bool _emailLinkSent = false;
  final bool _isRecaptchaEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadRememberMePreferences();
  }

  Future<void> _loadRememberMePreferences() async {
    final prefs =
        await ref.read(authProvider.notifier).loadRememberMePreferences();
    if (!mounted) return;
    setState(() {
      _rememberMe = prefs.enabled;
      if (prefs.email != null && prefs.email!.isNotEmpty) {
        _emailController.text = prefs.email!;
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isRecaptchaEnabled && _captchaToken == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please wait for CAPTCHA verification'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return;
    }

    final success = await ref.read(authProvider.notifier).login(
          _emailController.text.trim(),
          _passwordController.text.trim(),
          _captchaToken ?? '',
          rememberMe: _rememberMe,
        );

    if (!mounted || success) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ref.read(authProvider).error ?? 'Login failed'),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  Future<void> _sendEmailSignInLink() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Enter a valid email address first.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return;
    }

    final success =
        await ref.read(authProvider.notifier).sendEmailSignInLink(email);
    if (!mounted) return;

    if (success) {
      setState(() => _emailLinkSent = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Sign-in link sent. Open it on this device to continue.',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ref.read(authProvider).error ?? 'Could not send sign-in link.',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _signInWithGoogle() async {
    final success = await ref.read(authProvider.notifier).signInWithGoogle();
    if (!mounted || success) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ref.read(authProvider).error ?? 'Google Sign-In failed'),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  void _showEmailLinkSheet() {
    final authState = ref.read(authProvider);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            0,
            24,
            24 + MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Sign in with email link',
                style: Theme.of(sheetContext).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'We will email a secure link. Open it on this device to sign in without a password.',
                style: Theme.of(sheetContext).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              if (_emailLinkSent) ...[
                const SizedBox(height: 12),
                Text(
                  'Link sent. Check your inbox and open it on this device.',
                  style: Theme.of(sheetContext).textTheme.bodySmall?.copyWith(
                        color: Theme.of(sheetContext).colorScheme.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: authState.isLoading ? null : () async {
                  await _sendEmailSignInLink();
                  if (sheetContext.mounted) {
                    Navigator.of(sheetContext).pop();
                  }
                },
                child: const Text('Send sign-in link'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  context.go('/auth/email-link');
                },
                child: const Text('Already have the link open?'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);
    final isLoading = authState.isLoading;

    return AuthShell(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BrandWordmark(fontSize: 36),
            const SizedBox(height: 8),
            Text(
              'Precision roofing calculations',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'you@example.com',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Enter your password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
              ),
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onFieldSubmitted: (_) => _login(),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your password';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(
                  height: 24,
                  width: 24,
                  child: Checkbox(
                    value: _rememberMe,
                    onChanged: (value) {
                      setState(() => _rememberMe = value ?? false);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _rememberMe = !_rememberMe),
                    child: Text(
                      'Remember me',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => context.go('/auth/forgot-password'),
                  child: const Text('Forgot password?'),
                ),
              ],
            ),
            if (_isRecaptchaEnabled) ...[
              const SizedBox(height: 16),
              CaptchaWidget(
                onVerified: (token) {
                  setState(() => _captchaToken = token);
                },
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: isLoading ? null : _login,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: isLoading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.onSecondary,
                      ),
                    )
                  : const Text('Sign in'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: isLoading ? null : _signInWithGoogle,
              icon: const Icon(Icons.login),
              label: const Text('Continue with Google'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: isLoading ? null : _showEmailLinkSheet,
              child: const Text('Sign in with email link'),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'No account? ',
                  style: theme.textTheme.bodyMedium,
                ),
                TextButton(
                  onPressed: () => context.go('/auth/register'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Register'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 4,
              children: [
                TextButton(
                  onPressed: () => context.go('/support/faq'),
                  child: Text(
                    'FAQ',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                Text(
                  '·',
                  style: theme.textTheme.bodySmall,
                ),
                TextButton(
                  onPressed: () => context.go('/support/legal'),
                  child: Text(
                    'Legal',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                Text(
                  '·',
                  style: theme.textTheme.bodySmall,
                ),
                TextButton(
                  onPressed: () => context.go('/support/contact'),
                  child: Text(
                    'Contact',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}