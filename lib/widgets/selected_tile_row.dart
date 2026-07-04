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
  final bool compact;

  const SelectedTileRow({
    super.key,
    required this.user,
    required this.effectiveIsPro,
    required this.placeholderImageBuilder,
    this.previewSize = 72,
    this.compact = false,
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

  Future<void> _openTilePicker(BuildContext context, WidgetRef ref) async {
    try {
      final result = await context.push('/calculator/tile-select');
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
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth >= 600;
    final padding = compact
        ? const EdgeInsets.symmetric(horizontal: 12, vertical: 6)
        : EdgeInsets.all(isLargeScreen ? 12.0 : 8.0);
    final fontSize = isLargeScreen ? 14.0 : 12.0;
    final thumbSize = compact ? 36.0 : previewSize;
    final canBrowseDatabase = effectiveIsPro;

    final selectedTile =
        ref.watch(calculatorProvider.select((state) => state.selectedTile));

    final editButton = canBrowseDatabase
        ? Semantics(
            label: 'Edit selected tile',
            child: TextButton(
              onPressed: () => _openTilePicker(context, ref),
              child: Text(
                compact ? 'Edit' : 'Edit Tile',
                style: TextStyle(fontSize: fontSize - 2),
              ),
            ),
          )
        : selectedTile != null
            ? Semantics(
                label: 'Change tile specifications',
                child: TextButton(
                  onPressed: () => _openManualTileDialog(context, ref),
                  child: Text(
                    compact ? 'Edit' : 'Change Specs',
                    style: TextStyle(fontSize: fontSize - 2),
                  ),
                ),
              )
            : null;

    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (selectedTile != null)
            buildTilePreviewImage(
              image: selectedTile.image,
              materialType: selectedTile.materialType,
              placeholderBuilder: placeholderImageBuilder,
              width: thumbSize,
              height: thumbSize,
              borderRadius: BorderRadius.circular(compact ? 6 : 10),
            )
          else
            SizedBox(
              width: thumbSize,
              height: thumbSize,
              child: Icon(
                Icons.image_not_supported_outlined,
                size: thumbSize * 0.45,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          SizedBox(width: compact ? 8 : 12),
          Expanded(
            child: compact
                ? Text(
                    selectedTile?.name ?? 'No tile selected',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: fontSize,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selected Tile',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color:
                                  Theme.of(context).colorScheme.onSurfaceVariant,
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
                            style:
                                Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      decoration: TextDecoration.underline,
                                    ),
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
          if (editButton != null) editButton,
        ],
      ),
    );
  }
}