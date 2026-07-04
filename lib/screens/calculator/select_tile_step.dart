import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:roofgrid_uk/models/tile_model.dart';
import 'package:roofgrid_uk/models/user_model.dart';
import 'package:roofgrid_uk/providers/developer_mode_provider.dart';
import 'package:roofgrid_uk/providers/tile_provider.dart';
import 'package:roofgrid_uk/utils/tile_access.dart';
import 'package:roofgrid_uk/widgets/add_tile_widget.dart';
import 'package:roofgrid_uk/widgets/calculator/calculator_step_progress.dart';
import 'package:roofgrid_uk/widgets/tile_selector_widget.dart';

class SelectTileStep extends ConsumerWidget {
  final UserModel user;
  final bool effectiveIsPro;
  final void Function(TileModel tile) onTileSelected;
  final VoidCallback onCancel;

  const SelectTileStep({
    super.key,
    required this.user,
    required this.effectiveIsPro,
    required this.onTileSelected,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final padding = MediaQuery.of(context).size.width >= 600 ? 16.0 : 12.0;
    final canBrowse = canBrowseTileDatabase(
      user,
      ref.watch(developerModeProvider),
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.only(top: padding, bottom: 8),
            child: const CalculatorStepProgress(
              currentStep: CalculatorFlowStep.selectTile,
            ),
          ),
          Text(
            'Select your tile',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tile specifications drive gauge, spacing, and set-out calculations.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: canBrowse
                ? _ProTilePicker(
                    user: user,
                    onTileSelected: onTileSelected,
                  )
                : _FreeTilePicker(
                    user: user,
                    onTileSelected: onTileSelected,
                  ),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: padding, top: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(
                onPressed: onCancel,
                child: const Text('Cancel'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProTilePicker extends ConsumerWidget {
  final UserModel user;
  final void Function(TileModel tile) onTileSelected;

  const _ProTilePicker({
    required this.user,
    required this.onTileSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tilesAsync = ref.watch(allAvailableTilesProvider(user.id));

    return tilesAsync.when(
      data: (tiles) {
        if (Hive.isBoxOpen('tilesBox')) {
          final tilesBox = Hive.box<TileModel>('tilesBox');
          for (final tile in tiles) {
            tilesBox.put(tile.id, tile);
          }
        }
        return TileSelectorWidget(
          tiles: tiles,
          user: user,
          onTileSelected: onTileSelected,
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) {
        final fallback = Hive.isBoxOpen('tilesBox')
            ? Hive.box<TileModel>('tilesBox').values.toList()
            : <TileModel>[];
        if (fallback.isNotEmpty) {
          return TileSelectorWidget(
            tiles: fallback,
            user: user,
            onTileSelected: onTileSelected,
          );
        }
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Error loading tiles: $error',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(allAvailableTilesProvider(user.id));
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FreeTilePicker extends StatelessWidget {
  final UserModel user;
  final void Function(TileModel tile) onTileSelected;

  const _FreeTilePicker({
    required this.user,
    required this.onTileSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.35),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Manual tile input',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  'Enter your tile cover width, gauge, and spacing to continue. '
                  'Upgrade to Pro to browse the full UK tile database.',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (dialogContext) => Dialog(
                  child: AddTileWidget(
                    userRole: user.role,
                    userId: user.id,
                    onTileCreated: (newTile) {
                      Navigator.pop(dialogContext);
                      onTileSelected(newTile);
                    },
                  ),
                ),
              );
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text('Enter tile specifications'),
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () => context.go('/subscription'),
            child: const Text('Upgrade to Pro for tile database'),
          ),
        ],
      ),
    );
  }
}