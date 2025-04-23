import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:roofgrid_uk/providers/auth_provider.dart';

class MainDrawer extends ConsumerWidget {
  const MainDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primaryContainer,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Semantics(
                  label: 'RoofGrid UK logo',
                  child: Image.asset(
                    'assets/images/logo/RoofGridUk-Logo-hor-250.png',
                    fit: BoxFit.contain,
                    height: 40, // Adjusted for better fit on smaller screens
                    width: double.infinity,
                  ),
                ),
                const SizedBox(height: 12),
                userAsync.when(
                  data: (user) {
                    if (user == null) {
                      return const Text(
                        'Not signed in',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.displayName ?? 'User',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email ?? 'No Email',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: user.isPro ? Colors.green : Colors.grey,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            user.isPro ? 'Pro' : 'Free',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                  error: (error, stackTrace) => Text(
                    'Error: $error',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () {
              context.go('/home');
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.calculate),
            title: const Text('Calculator'),
            onTap: () {
              context.go('/calculator');
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.save),
            title: const Text('Saved Results'),
            onTap: () {
              context.go('/results');
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.grid_view),
            title: const Text('Manage Tiles'),
            onTap: () {
              context.go('/tiles');
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.star),
            title: const Text('Upgrade to Pro'),
            onTap: () {
              context.go('/subscription');
              Navigator.pop(context);
            },
          ),
          ExpansionTile(
            leading: const Icon(Icons.support),
            title: const Text('Support'),
            children: [
              ListTile(
                title: const Text('FAQ'),
                onTap: () {
                  context.go('/support/faq');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Legal'),
                onTap: () {
                  context.go('/support/legal');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Contact'),
                onTap: () {
                  context.go('/support/contact');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          ListTile(
            leading: const Icon(Icons.admin_panel_settings),
            title: const Text('Admin Dashboard'),
            onTap: () {
              context.go('/admin');
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign Out'),
            onTap: () async {
              await ref.read(authProvider.notifier).signOut();
              Navigator.pop(context);
              // Router will handle navigation to /auth/login
            },
          ),
        ],
      ),
    );
  }
}
