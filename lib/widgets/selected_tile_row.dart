import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:roofgrid_uk/models/user_model.dart';
import 'package:roofgrid_uk/models/tile_model.dart';
import 'package:roofgrid_uk/app/calculator/providers/calculator_provider.dart';

import 'package:roofgrid_uk/utils/tile_image_utils.dart';
import 'package:roofgrid_uk/widgets/add_tile_widget.dart';

class SelectedTileRow extends ConsumerWidget {
  final UserModel user;
  final bool effectiveIsPro;
  final Widget Function(TileSlateType) placeholderImageBuilder;
  final double previewSize;

  const SelectedTileRow({
    super.key,
    required this.user,
    required this.effectiveIsPro,
    required this.placeholderImageBuilder,
    this.previewSize = 72,
  });

  void _openManualTileDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        child: AddTileWidget(
          userRole: UserRole.free,
          userId: user.id,
          onTileCreated: (newTile) {
            ref.read(calculatorProvider.notifier).setTile(newTile);
            Navigator.pop(dialogContext);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth >= 600;
    final padding = isLargeScreen ? 12.0 : 8.0;
    final fontSize = isLargeScreen ? 14.0 : 12.0;
    final canBrowseDatabase = effectiveIsPro;

    final selectedTile =
        ref.watch(calculatorProvider.select((state) => state.selectedTile));

    return Padding(
      padding: EdgeInsets.all(padding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (selectedTile != null)
            buildTilePreviewImage(
              image: selectedTile.image,
              materialType: selectedTile.materialType,
              placeholderBuilder: placeholderImageBuilder,
              width: previewSize,
              height: previewSize,
              borderRadius: BorderRadius.circular(10),
            )
          else
            SizedBox(
              width: previewSize,
              height: previewSize,
              child: Icon(
                Icons.image_not_supported_outlined,
                size: previewSize * 0.45,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selected Tile',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  selectedTile?.name ?? 'None',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: fontSize + 1,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (!canBrowseDatabase) ...[
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => context.go('/subscription'),
                    child: Text(
                      'Upgrade to Pro for the full tile database',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            decoration: TextDecoration.underline,
                          ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (canBrowseDatabase)
            Semantics(
              label: 'Edit selected tile',
              child: TextButton(
                onPressed: () async {
                  try {
                    final result =
                        await context.push('/calculator/tile-select');
                    if (result != null && result is TileModel) {
                      ref.read(calculatorProvider.notifier).setTile(result);
                    }
                  } catch (e) {
                    if (kDebugMode) {
                      debugPrint('Error selecting tile: $e');
                    }
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error selecting tile: $e'),
                          backgroundColor: Theme.of(context).colorScheme.error,
                        ),
                      );
                    }
                  }
                },
                child: Text(
                  'Edit Tile',
                  style: TextStyle(fontSize: fontSize - 2),
                ),
              ),
            )
          else if (selectedTile != null)
            Semantics(
              label: 'Change tile specifications',
              child: TextButton(
                onPressed: () => _openManualTileDialog(context, ref),
                child: Text(
                  'Change Specs',
                  style: TextStyle(fontSize: fontSize - 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}