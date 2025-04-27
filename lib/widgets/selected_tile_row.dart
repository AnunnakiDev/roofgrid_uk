import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:roofgrid_uk/models/user_model.dart';
import 'package:roofgrid_uk/models/tile_model.dart';
import 'package:roofgrid_uk/app/calculator/providers/calculator_provider.dart';

class SelectedTileRow extends ConsumerWidget {
  final UserModel user;
  final Widget Function(TileSlateType) placeholderImageBuilder;

  const SelectedTileRow({
    super.key,
    required this.user,
    required this.placeholderImageBuilder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth >= 600;
    final padding = isLargeScreen ? 12.0 : 8.0;
    final fontSize = isLargeScreen ? 14.0 : 12.0;

    final selectedTile =
        ref.watch(calculatorProvider.select((state) => state.selectedTile));
    debugPrint(
        "Rebuilding selected tile row, selectedTile: ${selectedTile?.name}, Image URL: ${selectedTile?.image}");

    return Padding(
      padding: EdgeInsets.all(padding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                if (user.isPro)
                  if (selectedTile?.image != null &&
                      selectedTile!.image!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Image.network(
                        selectedTile.image!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          debugPrint(
                              'Failed to load tile image: ${selectedTile.image}, error: $error');
                          return placeholderImageBuilder(
                              selectedTile.materialType);
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const SizedBox(
                            width: 40,
                            height: 40,
                            child: CircularProgressIndicator(),
                          );
                        },
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: selectedTile != null
                          ? placeholderImageBuilder(selectedTile.materialType)
                          : const Icon(
                              Icons.broken_image,
                              size: 40,
                              color: Colors.grey,
                            ),
                    )
                else
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: GestureDetector(
                      onTap: () => context.go('/subscription'),
                      child: Semantics(
                        label: 'Upgrade to Pro for access to the tile database',
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Image.asset(
                              'assets/images/upgrade_to_pro.png',
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                debugPrint(
                                    'Failed to load upgrade_to_pro.png, error: $error');
                                return const Icon(
                                  Icons.broken_image,
                                  size: 40,
                                  color: Colors.grey,
                                );
                              },
                            ),
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Center(
                                child: Text(
                                  'Upgrade\nto Pro',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontSize: 10,
                                      ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                Flexible(
                  child: Text(
                    'Selected Tile: ${selectedTile?.name ?? "None"}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: fontSize,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          if (user.isPro)
            Semantics(
              label: 'Edit selected tile',
              child: TextButton(
                onPressed: () async {
                  try {
                    final selectedTile =
                        await context.push('/calculator/tile-select');
                    if (selectedTile != null && selectedTile is TileModel) {
                      debugPrint(
                          "Tile selected: ${selectedTile.name}, Image URL: ${selectedTile.image}");
                      ref
                          .read(calculatorProvider.notifier)
                          .setTile(selectedTile);
                    } else {
                      debugPrint(
                          'No tile selected or invalid tile data returned');
                    }
                  } catch (e) {
                    debugPrint('Error selecting tile: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error selecting tile: $e'),
                        backgroundColor: Theme.of(context).colorScheme.error,
                      ),
                    );
                  }
                },
                child: Text(
                  'Edit Tile',
                  style: TextStyle(fontSize: fontSize - 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
