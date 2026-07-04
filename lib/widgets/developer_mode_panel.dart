import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:roofgrid_uk/app/calculator/providers/calculator_provider.dart';
import 'package:roofgrid_uk/models/user_model.dart';
import 'package:roofgrid_uk/models/developer_mode_config.dart';
import 'package:roofgrid_uk/providers/developer_mode_provider.dart';
import 'package:roofgrid_uk/utils/connectivity_utils.dart';

class DeveloperModePanel extends ConsumerWidget {
  final UserModel user;

  const DeveloperModePanel({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devMode = ref.watch(developerModeProvider);
    final effectiveIsPro = ref.watch(effectiveIsProProvider);
    final calcState = ref.watch(calculatorProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.developer_mode, color: Colors.orange, size: 22),
              const SizedBox(width: 8),
              Text(
                'Developer Mode',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade800,
                    ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Local only',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.orange.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Admin testing tools — never syncs to Firestore.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Text(
            'Pro UI Override',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          SegmentedButton<ProOverrideMode>(
            segments: const [
              ButtonSegment(
                value: ProOverrideMode.actual,
                label: Text('Actual'),
                icon: Icon(Icons.autorenew, size: 16),
              ),
              ButtonSegment(
                value: ProOverrideMode.free,
                label: Text('Free'),
                icon: Icon(Icons.person, size: 16),
              ),
              ButtonSegment(
                value: ProOverrideMode.pro,
                label: Text('Pro'),
                icon: Icon(Icons.workspace_premium, size: 16),
              ),
            ],
            selected: {devMode.proOverride},
            onSelectionChanged: (selection) {
              ref
                  .read(developerModeProvider.notifier)
                  .setProOverride(selection.first);
            },
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Force Offline Mode'),
            subtitle: Text(
              devMode.forceOffline
                  ? 'Connectivity forced offline'
                  : 'Using real device connectivity',
            ),
            value: devMode.forceOffline,
            onChanged: (value) {
              ref.read(developerModeProvider.notifier).setForceOffline(value);
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _confirmReset(context, ref),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Reset Local Data'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    side: BorderSide(color: Colors.red.shade300),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _seedTiles(context, ref),
                  icon: const Icon(Icons.grass, size: 18),
                  label: const Text('Seed UK Tiles'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade700,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDebugInfo(
            context,
            effectiveIsPro: effectiveIsPro,
            devMode: devMode,
            selectedTile: calcState.selectedTile?.name,
            verticalResult: calcState.verticalResult,
            horizontalResult: calcState.horizontalResult,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 150.ms);
  }

  Widget _buildDebugInfo(
    BuildContext context, {
    required bool effectiveIsPro,
    required DeveloperModeState devMode,
    required String? selectedTile,
    required dynamic verticalResult,
    required dynamic horizontalResult,
  }) {
    final calcSummary = _formatCalcSummary(verticalResult, horizontalResult);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Debug Info', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          _debugRow('Role', user.role.toString().split('.').last),
          _debugRow('Actual isPro', user.isPro.toString()),
          _debugRow('Effective isPro', effectiveIsPro.toString()),
          _debugRow('Pro override', devMode.proOverride.name),
          _debugRow('Force offline', devMode.forceOffline.toString()),
          _debugRow(
            'Connectivity',
            forceOfflineOverride ? 'forced offline' : 'normal',
          ),
          _debugRow('Selected tile', selectedTile ?? 'none'),
          _debugRow('Last calculation', calcSummary),
        ],
      ),
    );
  }

  Widget _debugRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  String _formatCalcSummary(dynamic vertical, dynamic horizontal) {
    final parts = <String>[];
    if (vertical != null) {
      parts.add('Vertical: ${vertical.gauge}mm gauge, ${vertical.totalCourses} courses');
    }
    if (horizontal != null) {
      parts.add('Horizontal: ${horizontal.solution}');
    }
    return parts.isEmpty ? 'none' : parts.join(' | ');
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Local Data?'),
        content: const Text(
          'Clears cached tiles, saved results, calculations, and last selected tile. '
          'Firestore data and dev settings are not affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Reset', style: TextStyle(color: Colors.red.shade700)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await ref.read(developerModeProvider.notifier).resetLocalData();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Local Hive data cleared')),
      );
    }
  }

  Future<void> _seedTiles(BuildContext context, WidgetRef ref) async {
    final count = await ref.read(developerModeProvider.notifier).seedUkTiles();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Seeded $count UK tiles locally')),
      );
    }
  }
}