import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:roofgrid_uk/models/developer_mode_config.dart';
import 'package:roofgrid_uk/models/user_model.dart';
import 'package:roofgrid_uk/providers/auth_provider.dart';
import 'package:roofgrid_uk/providers/developer_mode_provider.dart';
import 'package:roofgrid_uk/providers/theme_provider.dart';
import 'package:roofgrid_uk/widgets/results/results_section_header.dart';
import 'package:roofgrid_uk/widgets/settings/plan_status_card.dart';
import 'package:roofgrid_uk/widgets/theme_scheme_selector.dart';

class ProfileHubWidget extends ConsumerStatefulWidget {
  final UserModel user;
  final int initialTabIndex;

  const ProfileHubWidget({
    super.key,
    required this.user,
    this.initialTabIndex = 0,
  });

  @override
  ConsumerState<ProfileHubWidget> createState() => _ProfileHubWidgetState();
}

class _ProfileHubWidgetState extends ConsumerState<ProfileHubWidget>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final TabController _tabController;
  late TextEditingController _displayNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _passwordController;
  String? _photoURL;
  File? _imageFile;
  bool _isLoading = false;
  bool _isPasswordLoading = false;

  @override
  void initState() {
    super.initState();
    final tabCount = widget.user.isAdmin ? 4 : 3;
    final safeIndex = widget.initialTabIndex.clamp(0, tabCount - 1);
    _tabController = TabController(length: tabCount, vsync: this, initialIndex: safeIndex);
    _displayNameController =
        TextEditingController(text: widget.user.displayName ?? '');
    _emailController = TextEditingController(text: widget.user.email ?? '');
    _phoneController = TextEditingController(text: widget.user.phone ?? '');
    _passwordController = TextEditingController();
    _photoURL = widget.user.photoURL;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _displayNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      String? newPhotoURL = _photoURL;
      if (_imageFile != null) {
        final storageRef = FirebaseStorage.instance.ref().child(
            'profile_images/${widget.user.id}/${_imageFile!.path.split('/').last}');
        await storageRef.putFile(_imageFile!);
        newPhotoURL = await storageRef.getDownloadURL();
      }

      await ref.read(authProvider.notifier).updateUserProfile(
            displayName: _displayNameController.text,
            photoURL: newPhotoURL,
          );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.id)
          .update({
        'phone': _phoneController.text,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _changePassword() async {
    if (_passwordController.text.isEmpty ||
        _passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return;
    }

    setState(() => _isPasswordLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No user signed in');
      await user.updatePassword(_passwordController.text);
      _passwordController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating password: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPasswordLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabs = <Tab>[
      const Tab(text: 'Account'),
      const Tab(text: 'Plan'),
      const Tab(text: 'Appearance'),
      if (widget.user.isAdmin) const Tab(text: 'Admin'),
    ];

    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: colorScheme.secondary,
          unselectedLabelColor: colorScheme.onSurfaceVariant,
          indicatorColor: colorScheme.secondary,
          dividerColor: colorScheme.onSurface.withValues(alpha: 0.08),
          tabs: tabs,
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildAccountTab(),
              _buildPlanTab(),
              _buildAppearanceTab(),
              if (widget.user.isAdmin) _buildAdminTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccountTab() {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ResultsSectionHeader(title: 'Account details'),
                const SizedBox(height: 16),
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor:
                            colorScheme.primary.withValues(alpha: 0.12),
                        backgroundImage: _imageFile != null
                            ? FileImage(_imageFile!)
                            : (_photoURL != null
                                ? NetworkImage(_photoURL!)
                                : null) as ImageProvider?,
                        child: _imageFile == null && _photoURL == null
                            ? Icon(
                                Icons.person_outline_rounded,
                                size: 50,
                                color: colorScheme.primary,
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: IconButton(
                          icon: Icon(
                            Icons.camera_alt_rounded,
                            color: colorScheme.onSecondary,
                          ),
                          onPressed: () async {
                            final result = await FilePicker.pickFiles(
                              type: FileType.image,
                            );
                            if (result != null &&
                                result.files.single.path != null) {
                              setState(() {
                                _imageFile = File(result.files.single.path!);
                              });
                            }
                          },
                          style: IconButton.styleFrom(
                            backgroundColor: colorScheme.secondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _displayNameController,
                  decoration: const InputDecoration(
                    labelText: 'Display Name',
                  ),
                  validator: (value) =>
                      (value == null || value.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    helperText: 'Email changes require signing in again',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'New Password',
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _updateProfile,
                        icon: _isLoading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save_outlined, size: 18),
                        label: const Text('Update Profile'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed:
                            _isPasswordLoading ? null : _changePassword,
                        icon: _isPasswordLoading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.lock_outline_rounded, size: 18),
                        label: const Text('Change Password'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colorScheme.secondary,
                          side: BorderSide(
                            color: colorScheme.secondary.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlanTab() {
    final user = widget.user;
    final effectiveIsPro = ref.watch(effectiveIsProProvider);
    final devMode = ref.watch(developerModeProvider);
    final devOverrideActive =
        user.isAdmin && devMode.proOverride != ProOverrideMode.actual;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ResultsSectionHeader(title: 'Your plan'),
          const SizedBox(height: 12),
          PlanStatusCard(
            user: user,
            effectiveIsPro: effectiveIsPro,
            showDevOverride: devOverrideActive,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.go('/subscription'),
              icon: Icon(
                effectiveIsPro
                    ? Icons.manage_accounts_outlined
                    : Icons.workspace_premium_outlined,
              ),
              label: Text(
                effectiveIsPro ? 'Manage Subscription' : 'Upgrade to Pro',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppearanceTab() {
    final themeState = ref.watch(themeStateProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ResultsSectionHeader(title: 'Theme mode'),
                  const SizedBox(height: 12),
                  SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.light,
                label: Text('Light'),
                icon: Icon(Icons.wb_sunny, size: 16),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text('Dark'),
                icon: Icon(Icons.nightlight_round, size: 16),
              ),
              ButtonSegment(
                value: ThemeMode.system,
                label: Text('System'),
                icon: Icon(Icons.brightness_auto, size: 16),
              ),
            ],
            selected: {themeState.themeMode},
            onSelectionChanged: (selection) {
              ref
                  .read(themeProvider.notifier)
                  .setThemeMode(selection.first);
            },
          ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ResultsSectionHeader(title: 'Colour scheme'),
                  const SizedBox(height: 8),
                  Text(
                    'Choose a preset palette for the app.',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ThemeSchemeSelector(syncUserId: widget.user.id),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminTab() {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ResultsSectionHeader(title: 'Administrator'),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.22),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.admin_panel_settings_rounded,
                      color: colorScheme.secondary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Administrator access',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            widget.user.email ?? '',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/admin/dashboard'),
                  icon: const Icon(Icons.dashboard_outlined),
                  label: const Text('Open Admin Dashboard'),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Developer tools and platform management live on the Admin Dashboard.',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}