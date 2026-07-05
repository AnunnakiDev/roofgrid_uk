import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:roofgrid_uk/providers/auth_provider.dart';
import 'package:roofgrid_uk/navigation/home_back_button.dart';
import 'package:roofgrid_uk/widgets/main_drawer.dart';
import 'package:roofgrid_uk/widgets/profile_hub_widget.dart';
import 'package:roofgrid_uk/widgets/profile_summary_widget.dart';

class ProfileScreen extends ConsumerWidget {
  final String? initialTabKey;

  const ProfileScreen({super.key, this.initialTabKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: const [HomeBackButton()],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
      ),
      drawer: const MainDrawer(),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Please sign in again.'));
          }
          return Column(
            children: [
              ProfileSummaryWidget(
                user: user,
                headerOnly: true,
              ),
              Expanded(
                child: ProfileHubWidget(
                  user: user,
                  initialTabKey: initialTabKey,
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}