import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roofgrid_uk/models/tile_model.dart';
import 'package:roofgrid_uk/models/user_model.dart';
import 'package:roofgrid_uk/providers/tile_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';

class AddTileWidget extends ConsumerStatefulWidget {
  final UserRole userRole;
  final String userId;
  final TileModel? tile; // Optional tile for editing
  final Function(TileModel)? onTileCreated; // Callback for free users

  const AddTileWidget({
    super.key,
    required this.userRole,
    required this.userId,
    this.tile,
    this.onTileCreated,
  });

  @override
  ConsumerState<AddTileWidget> createState() => _AddTileWidgetState();
}

class _AddTileWidgetState extends ConsumerState<AddTileWidget> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _manufacturerController;
  late TextEditingController _descriptionController;
  late TextEditingController _heightController;
  late TextEditingController _widthController;
  late TextEditingController _minGaugeController;
  late TextEditingController _maxGaugeController;
  late TextEditingController _minSpacingController;
  late TextEditingController _maxSpacingController;
  late TextEditingController _leftHandTileWidthController;
  File? _dataSheetFile;
  File? _imageFile;
  String? _dataSheetUrl;
  String? _imageUrl;
  TileSlateType _materialType = TileSlateType.slate;
  bool _crossBonded = false;
  String _saveDestination = 'Personal'; // For admins: 'Default' or 'Personal'
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing tile data if editing
    _nameController = TextEditingController(
        text: widget.tile != null ? widget.tile!.name : '');
    _manufacturerController = TextEditingController(
        text: widget.tile != null ? widget.tile!.manufacturer : '');
    _descriptionController = TextEditingController(
        text: widget.tile != null ? widget.tile!.description : '');
    _heightController = TextEditingController(
        text:
            widget.tile != null ? widget.tile!.slateTileHeight.toString() : '');
    _widthController = TextEditingController(
        text:
            widget.tile != null ? widget.tile!.tileCoverWidth.toString() : '');
    _minGaugeController = TextEditingController(
        text: widget.tile != null ? widget.tile!.minGauge.toString() : '');
    _maxGaugeController = TextEditingController(
        text: widget.tile != null ? widget.tile!.maxGauge.toString() : '');
    _minSpacingController = TextEditingController(
        text: widget.tile != null ? widget.tile!.minSpacing.toString() : '');
    _maxSpacingController = TextEditingController(
        text: widget.tile != null ? widget.tile!.maxSpacing.toString() : '');
    _leftHandTileWidthController = TextEditingController(
        text: widget.tile != null
            ? widget.tile!.leftHandTileWidth?.toString() ?? ''
            : '');
    _dataSheetUrl = widget.tile?.dataSheet;
    _imageUrl = widget.tile?.image;
    if (widget.tile != null) {
      _materialType = widget.tile!.materialType;
      _crossBonded = widget.tile!.defaultCrossBonded;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _manufacturerController.dispose();
    _descriptionController.dispose();
    _heightController.dispose();
    _widthController.dispose();
    _minGaugeController.dispose();
    _maxGaugeController.dispose();
    _minSpacingController.dispose();
    _maxSpacingController.dispose();
    _leftHandTileWidthController.dispose();
    super.dispose();
  }

  Future<String?> _uploadFile(File file, String path) async {
    try {
      final ref = FirebaseStorage.instance.ref().child(path);
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading file: $e')),
      );
      return null;
    }
  }

  Future<void> _pickFile({
    required Function(File?) onFilePicked,
    required String fieldName,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        onFilePicked(File(result.files.single.path!));
      });
    }
  }

  Future<void> _deleteTile() async {
    if (widget.tile != null) {
      try {
        setState(() {
          _isSaving = true;
        });
        // Delete associated files from Firebase Storage
        try {
          final storageRef =
              FirebaseStorage.instance.ref().child('tiles/${widget.tile!.id}');
          final listResult = await storageRef.listAll();
          for (var item in listResult.items) {
            await item.delete();
          }
        } catch (e) {
          // Ignore errors if files don't exist
        }

        // Delete the tile from Firestore
        await FirebaseFirestore.instance
            .collection('tiles')
            .doc(widget.tile!.id)
            .delete();
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting tile: $e')),
        );
      } finally {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _saveTile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final now = DateTime.now();
      String? newDataSheetUrl = _dataSheetUrl;
      String? newImageUrl = _imageUrl;
      String tileId = widget.tile != null
          ? widget.tile!.id
          : 'tile_${DateTime.now().millisecondsSinceEpoch}';

      // Upload data sheet if a new file is selected
      if (_dataSheetFile != null) {
        final path =
            'tiles/$tileId/datasheet${_dataSheetFile!.path.split('.').last}';
        newDataSheetUrl = await _uploadFile(_dataSheetFile!, path);
      }

      // Upload image if a new file is selected
      if (_imageFile != null) {
        final path = 'tiles/$tileId/image${_imageFile!.path.split('.').last}';
        newImageUrl = await _uploadFile(_imageFile!, path);
      }

      final tile = TileModel(
        id: tileId,
        name: widget.userRole == UserRole.free
            ? 'Temporary Tile'
            : _nameController.text,
        manufacturer: widget.userRole == UserRole.free
            ? 'Manual Input'
            : _manufacturerController.text,
        materialType: _materialType,
        description: widget.userRole == UserRole.free
            ? 'Manually entered tile specifications'
            : _descriptionController.text,
        isPublic: widget.tile != null ? widget.tile!.isPublic : false,
        isApproved: widget.tile != null ? widget.tile!.isApproved : false,
        createdById: widget.userId,
        createdAt: widget.tile != null ? widget.tile!.createdAt : now,
        updatedAt: now,
        slateTileHeight: double.parse(_heightController.text),
        tileCoverWidth: double.parse(_widthController.text),
        minGauge: double.parse(_minGaugeController.text),
        maxGauge: double.parse(_maxGaugeController.text),
        minSpacing: double.parse(_minSpacingController.text),
        maxSpacing: double.parse(_maxSpacingController.text),
        leftHandTileWidth: _leftHandTileWidthController.text.isNotEmpty
            ? double.parse(_leftHandTileWidthController.text)
            : null,
        defaultCrossBonded: _crossBonded,
        dataSheet: widget.userRole == UserRole.free ? null : newDataSheetUrl,
        image: widget.userRole == UserRole.free ? null : newImageUrl,
      );

      if (widget.userRole == UserRole.free) {
        // Free user: Return temporary tile via callback
        widget.onTileCreated?.call(tile);
      } else {
        // Pro user or Admin: Save to Firestore
        final tileService = ref.read(tileServiceProvider);
        if (widget.userRole == UserRole.admin &&
            _saveDestination == 'Default') {
          final defaultTile = tile.copyWith(
            isPublic: true,
            isApproved: true,
          );
          await tileService.saveToDefaultTiles(defaultTile);
        } else {
          await tileService.saveTile(tile);
        }
      }

      // Navigate back
      if (context.mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving tile: $e')),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open URL')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid URL')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth >= 600;
    final padding =
        isLargeScreen ? const EdgeInsets.all(24.0) : const EdgeInsets.all(16.0);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tile != null ? 'Edit Tile' : 'Add New Tile'),
      ),
      body: SingleChildScrollView(
        padding: padding,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.userRole != UserRole.free &&
                  _imageUrl != null &&
                  _imageUrl!.isNotEmpty)
                Center(
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.0),
                      color: Colors.grey[200],
                    ),
                    child: Image.network(
                      _imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.broken_image,
                        size: 50,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              if (widget.userRole != UserRole.free) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tile Name *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Name is required' : null,
                ),
              ],
              const SizedBox(height: 16),
              DropdownButtonFormField<TileSlateType>(
                value: _materialType,
                decoration: const InputDecoration(
                  labelText: 'Material Type *',
                  border: OutlineInputBorder(),
                ),
                items: TileSlateType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.toString().split('.').last),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _materialType = value!;
                  });
                },
                validator: (value) =>
                    value == null ? 'Material type is required' : null,
              ),
              const SizedBox(height: 16),
              if (widget.userRole != UserRole.free) ...[
                TextFormField(
                  controller: _manufacturerController,
                  decoration: const InputDecoration(
                    labelText: 'Manufacturer *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value?.isEmpty ?? true
                      ? 'Manufacturer is required'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
              ],
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _heightController,
                      decoration: const InputDecoration(
                        labelText: 'Height/Length (mm) *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value?.isEmpty ?? true) return 'Height is required';
                        if (double.tryParse(value!) == null) {
                          return 'Invalid number';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _widthController,
                      decoration: const InputDecoration(
                        labelText: 'Cover Width (mm) *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value?.isEmpty ?? true) return 'Width is required';
                        if (double.tryParse(value!) == null) {
                          return 'Invalid number';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _minGaugeController,
                      decoration: const InputDecoration(
                        labelText: 'Min Gauge (mm) *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Min gauge is required';
                        }
                        if (double.tryParse(value!) == null) {
                          return 'Invalid number';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _maxGaugeController,
                      decoration: const InputDecoration(
                        labelText: 'Max Gauge (mm) *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Max gauge is required';
                        }
                        if (double.tryParse(value!) == null) {
                          return 'Invalid number';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _minSpacingController,
                      decoration: const InputDecoration(
                        labelText: 'Min Spacing (mm) *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Min spacing is required';
                        }
                        if (double.tryParse(value!) == null) {
                          return 'Invalid number';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _maxSpacingController,
                      decoration: const InputDecoration(
                        labelText: 'Max Spacing (mm) *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Max spacing is required';
                        }
                        if (double.tryParse(value!) == null) {
                          return 'Invalid number';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _leftHandTileWidthController,
                decoration: const InputDecoration(
                  labelText: 'Left Hand Tile Width (mm)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (double.tryParse(value) == null) return 'Invalid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Cross Bonded'),
                value: _crossBonded,
                onChanged: (value) {
                  setState(() {
                    _crossBonded = value ?? false;
                  });
                },
              ),
              if (widget.userRole != UserRole.free) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _dataSheetFile != null
                            ? 'Data Sheet: ${_dataSheetFile!.path.split('/').last}'
                            : _dataSheetUrl != null
                                ? 'Data Sheet: ${_dataSheetUrl!.split('/').last}'
                                : 'No Data Sheet',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _pickFile(
                        onFilePicked: (file) => _dataSheetFile = file,
                        fieldName: 'Data Sheet',
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                      ),
                      child: const Text(
                        'Upload Data Sheet',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
                if (_dataSheetUrl != null && _dataSheetUrl!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _launchURL(_dataSheetUrl!),
                    child: const Text('Preview Data Sheet'),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _imageFile != null
                            ? 'Image: ${_imageFile!.path.split('/').last}'
                            : _imageUrl != null
                                ? 'Image: ${_imageUrl!.split('/').last}'
                                : 'No Image',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _pickFile(
                        onFilePicked: (file) => _imageFile = file,
                        fieldName: 'Image',
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                      ),
                      child: const Text(
                        'Upload Image',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
              if (widget.userRole == UserRole.admin) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _saveDestination,
                  decoration: const InputDecoration(
                    labelText: 'Save Destination',
                    border: OutlineInputBorder(),
                  ),
                  items: ['Personal', 'Default'].map((destination) {
                    return DropdownMenuItem(
                      value: destination,
                      child: Text(destination),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _saveDestination = value!;
                    });
                  },
                ),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (widget.tile != null && widget.userRole == UserRole.admin)
                    TextButton(
                      onPressed: _isSaving ? null : _deleteTile,
                      child: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveTile,
                    child: Text(widget.tile != null ? 'Save' : 'Add Tile'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
