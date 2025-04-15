import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roofgrid_uk/models/tile_model.dart';
import 'package:roofgrid_uk/providers/auth_provider.dart';
import 'package:roofgrid_uk/models/tiles/services/tile_service.dart';

/// Screen for submitting custom tiles to be reviewed by admins and
/// potentially added to the public tile database
class TileSubmissionScreen extends ConsumerStatefulWidget {
  final TileModel? initialTile;

  const TileSubmissionScreen({super.key, this.initialTile});

  @override
  ConsumerState<TileSubmissionScreen> createState() =>
      _TileSubmissionScreenState();
}

class _TileSubmissionScreenState extends ConsumerState<TileSubmissionScreen> {
  bool _isLoading = false;
  bool _submitted = false;
  late TileModel _tile;

  @override
  void initState() {
    super.initState();
    _tile = widget.initialTile ??
        TileModel(
          id: 'submit_${DateTime.now().millisecondsSinceEpoch}',
          name: '',
          manufacturer: '',
          materialType: MaterialType.slate,
          description: '',
          isPublic: false, // Will be set to true when submitted
          isApproved: false,
          createdById: '',
          createdAt: DateTime.now(),
          slateTileHeight: 0,
          tileCoverWidth: 0,
          minGauge: 0,
          maxGauge: 0,
          minSpacing: 0,
          maxSpacing: 0,
          defaultCrossBonded: false,
        );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;

    // Safety check - redirect if not logged in
    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in to submit tiles'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Tile for Review'),
      ),
      body: _submitted ? _buildSuccessView() : _buildSubmissionForm(user.id),
    );
  }

  Widget _buildSuccessView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Colors.green,
              size: 64,
            ),
            const SizedBox(height: 24),
            Text(
              'Submission Received!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Thank you for submitting your tile data. Our team will review it shortly and add it to the public database if approved.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            const Text(
              'Review typically takes 1-2 business days.',
              style: TextStyle(fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Return to Tile Management'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmissionForm(String userId) {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    // Form controllers
    final nameController = TextEditingController(text: _tile.name);
    final manufacturerController =
        TextEditingController(text: _tile.manufacturer);
    final descriptionController =
        TextEditingController(text: _tile.description);
    final heightController = TextEditingController(
        text:
            _tile.slateTileHeight > 0 ? _tile.slateTileHeight.toString() : '');
    final widthController = TextEditingController(
        text: _tile.tileCoverWidth > 0 ? _tile.tileCoverWidth.toString() : '');
    final minGaugeController = TextEditingController(
        text: _tile.minGauge > 0 ? _tile.minGauge.toString() : '');
    final maxGaugeController = TextEditingController(
        text: _tile.maxGauge > 0 ? _tile.maxGauge.toString() : '');
    final minSpacingController = TextEditingController(
        text: _tile.minSpacing > 0 ? _tile.minSpacing.toString() : '');
    final maxSpacingController = TextEditingController(
        text: _tile.maxSpacing > 0 ? _tile.maxSpacing.toString() : '');
    final leftHandTileWidthController =
        TextEditingController(text: _tile.leftHandTileWidth?.toString() ?? '0');

    MaterialType selectedMaterialType = _tile.materialType;
    bool isCrossBonded = _tile.defaultCrossBonded;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info card
            Card(
              margin: const EdgeInsets.only(bottom: 24),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Submission Guidelines',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Submit accurate tile information to be reviewed by our team. If approved, your submitted tile will be added to the public database for all users to access.',
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Required information includes tile dimensions and gauge specifications. Please provide accurate manufacturer details where possible.',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ),

            // Form fields
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Tile Name *'),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Name is required' : null,
            ),
            const SizedBox(height: 16),

            StatefulBuilder(
              builder: (context, setState) =>
                  DropdownButtonFormField<MaterialType>(
                value: selectedMaterialType,
                decoration: const InputDecoration(labelText: 'Material Type *'),
                items: MaterialType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(_getMaterialTypeDisplayName(type)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => selectedMaterialType = value);
                  }
                },
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: manufacturerController,
              decoration: const InputDecoration(labelText: 'Manufacturer *'),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Manufacturer is required' : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: heightController,
              decoration:
                  const InputDecoration(labelText: 'Height/Length (mm) *'),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Height is required';
                if (double.tryParse(value!) == null) return 'Invalid number';
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: widthController,
              decoration:
                  const InputDecoration(labelText: 'Cover Width (mm) *'),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Width is required';
                if (double.tryParse(value!) == null) return 'Invalid number';
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: minGaugeController,
              decoration: const InputDecoration(labelText: 'Min Gauge (mm) *'),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Min gauge is required';
                if (double.tryParse(value!) == null) return 'Invalid number';
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: maxGaugeController,
              decoration: const InputDecoration(labelText: 'Max Gauge (mm) *'),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Max gauge is required';
                if (double.tryParse(value!) == null) return 'Invalid number';
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: minSpacingController,
              decoration:
                  const InputDecoration(labelText: 'Min Spacing (mm) *'),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Min spacing is required';
                if (double.tryParse(value!) == null) return 'Invalid number';
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: maxSpacingController,
              decoration:
                  const InputDecoration(labelText: 'Max Spacing (mm) *'),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Max spacing is required';
                if (double.tryParse(value!) == null) return 'Invalid number';
                return null;
              },
            ),
            const SizedBox(height: 16),

            StatefulBuilder(
              builder: (context, setState) => SwitchListTile(
                title: const Text('Cross Bonded'),
                value: isCrossBonded,
                onChanged: (value) {
                  setState(() => isCrossBonded = value);
                },
              ),
            ),

            StatefulBuilder(
              builder: (context, setState) => isCrossBonded
                  ? Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: TextFormField(
                        controller: leftHandTileWidthController,
                        decoration: const InputDecoration(
                          labelText: 'Left Hand Tile Width (mm)',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            if (double.tryParse(value) == null) {
                              return 'Invalid number';
                            }
                          }
                          return null;
                        },
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () => _submitTile(
                        formKey,
                        userId,
                        nameController.text,
                        manufacturerController.text,
                        descriptionController.text,
                        selectedMaterialType,
                        heightController.text,
                        widthController.text,
                        minGaugeController.text,
                        maxGaugeController.text,
                        minSpacingController.text,
                        maxSpacingController.text,
                        isCrossBonded,
                        leftHandTileWidthController.text,
                      ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Submit Tile for Review'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitTile(
    GlobalKey<FormState> formKey,
    String userId,
    String name,
    String manufacturer,
    String description,
    MaterialType materialType,
    String heightText,
    String widthText,
    String minGaugeText,
    String maxGaugeText,
    String minSpacingText,
    String maxSpacingText,
    bool isCrossBonded,
    String leftHandTileWidthText,
  ) async {
    if (!formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Prepare the tile data
      final submittedTile = TileModel(
        id: _tile.id,
        name: name,
        manufacturer: manufacturer,
        materialType: materialType,
        description: description,
        isPublic: true, // Setting to true for public submission
        isApproved: false, // Requires admin approval
        createdById: userId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        slateTileHeight: double.parse(heightText),
        tileCoverWidth: double.parse(widthText),
        minGauge: double.parse(minGaugeText),
        maxGauge: double.parse(maxGaugeText),
        minSpacing: double.parse(minSpacingText),
        maxSpacing: double.parse(maxSpacingText),
        defaultCrossBonded: isCrossBonded,
        leftHandTileWidth: isCrossBonded && leftHandTileWidthText.isNotEmpty
            ? double.parse(leftHandTileWidthText)
            : null,
      );

      // Save to Firestore
      final tileService = ref.read(tileServiceProvider);
      final success = await tileService.saveTile(submittedTile);

      if (success) {
        setState(() {
          _isLoading = false;
          _submitted = true;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to submit tile. Please try again later.'),
            ),
          );
        }
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error submitting tile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: $e'),
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  /// Helper to get a display-friendly name for material types
  String _getMaterialTypeDisplayName(MaterialType type) {
    switch (type) {
      case MaterialType.slate:
        return 'Natural Slate';
      case MaterialType.fibreCementSlate:
        return 'Fibre Cement Slate';
      case MaterialType.interlockingTile:
        return 'Interlocking Tile';
      case MaterialType.plainTile:
        return 'Plain Tile';
      case MaterialType.concreteTile:
        return 'Concrete Tile';
      case MaterialType.pantile:
        return 'Pantile';
      case MaterialType.unknown:
        return 'Unknown Type';
    }
  }
}
