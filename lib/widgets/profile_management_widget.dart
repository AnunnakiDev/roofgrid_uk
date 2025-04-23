import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:roofgrid_uk/models/user_model.dart';
import 'package:roofgrid_uk/providers/auth_provider.dart';
import 'package:roofgrid_uk/providers/theme_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class ProfileManagementWidget extends ConsumerStatefulWidget {
  const ProfileManagementWidget({super.key});

  @override
  ConsumerState<ProfileManagementWidget> createState() =>
      _ProfileManagementWidgetState();
}

class _ProfileManagementWidgetState
    extends ConsumerState<ProfileManagementWidget> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _displayNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _passwordController;
  String? _photoURL;
  File? _imageFile;
  bool _isLoading = false;
  bool _isPasswordLoading = false;
  final _analytics = FirebaseAnalytics.instance;
  Color _selectedColor = Colors.blue; // Default color

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider).value;
    _displayNameController =
        TextEditingController(text: user?.displayName ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _passwordController = TextEditingController();
    _photoURL = user?.photoURL;

    // Load custom primary color from ThemeProvider
    final themeState = ref.read(themeProvider);
    _selectedColor = themeState.customPrimaryColor!;
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final user = ref.read(currentUserProvider).value!;
        String? newPhotoURL = _photoURL;
        if (_imageFile != null) {
          final storageRef = FirebaseStorage.instance.ref().child(
              'profile_images/${user.id}/${_imageFile!.path.split('/').last}');
          await storageRef.putFile(_imageFile!);
          newPhotoURL = await storageRef.getDownloadURL();
        }

        await ref.read(authProvider.notifier).updateUserProfile(
              displayName: _displayNameController.text,
              photoURL: newPhotoURL,
            );

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.id)
            .update({
          'phone': _phoneController.text,
          'lastUpdated': FieldValue.serverTimestamp(),
        });

        await _analytics.logEvent(
          name: 'update_profile',
          parameters: {
            'user_id': user.id,
            'updated_fields': [
              if (_displayNameController.text != user.displayName)
                'displayName',
              if (_phoneController.text != user.phone) 'phone',
              if (_imageFile != null) 'photoURL',
            ].join(','),
          },
        );

        if (_emailController.text != user.email) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Email updates require re-authentication. Please sign out and sign in again.'),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
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

      await _analytics.logEvent(
        name: 'change_password',
        parameters: {'user_id': user.uid},
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully')),
      );
      _passwordController.clear();
    } catch (e) {
      if (e.toString().contains('requires-recent-login')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Please sign out and sign in again to update your password.'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating password: $e')),
        );
      }
    } finally {
      setState(() => _isPasswordLoading = false);
    }
  }

  Future<void> _updateCustomPrimaryColor(Color color) async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    try {
      // Update ThemeProvider
      await ref.read(themeProvider.notifier).setCustomPrimaryColor(color);

      // Update Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.id).update({
        'settings': {
          'primaryColor': color.value,
        },
      });

      await _analytics.logEvent(
        name: 'update_theme_color',
        parameters: {
          'user_id': user.id,
          'color': color.value.toString(),
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Theme color updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating theme color: $e')),
      );
    }
  }

  Future<void> _signOut() async {
    await ref.read(authProvider.notifier).signOut();
    if (mounted) {
      context.go('/auth/login');
    }
  }

  void _pickColor() {
    showDialog(
      context: context,
      builder: (context) {
        Color pickerColor = _selectedColor;
        return AlertDialog(
          title: const Text('Pick a Theme Color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: pickerColor,
              onColorChanged: (color) {
                pickerColor = color;
              },
              showLabel: true,
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedColor = pickerColor;
                });
                _updateCustomPrimaryColor(pickerColor);
                Navigator.of(context).pop();
              },
              child: const Text('Select'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value;

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(2, 2),
          ),
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withOpacity(0.1)
                : Colors.white.withOpacity(0.3),
            blurRadius: 5,
            offset: const Offset(-2, -2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Manage Your Profile',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ).animate().fadeIn(duration: 400.ms),
              const SizedBox(height: 16),
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: _imageFile != null
                          ? FileImage(_imageFile!)
                          : (_photoURL != null
                              ? NetworkImage(_photoURL!)
                              : null) as ImageProvider?,
                      child: _imageFile == null && _photoURL == null
                          ? const Icon(Icons.person, size: 50)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Semantics(
                        label: 'Upload profile picture',
                        child: IconButton(
                          icon:
                              const Icon(Icons.camera_alt, color: Colors.white),
                          onPressed: () async {
                            final result = await FilePicker.platform
                                .pickFiles(type: FileType.image);
                            if (result != null &&
                                result.files.single.path != null) {
                              setState(() {
                                _imageFile = File(result.files.single.path!);
                              });
                            }
                          },
                          style: IconButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
              ),
              const SizedBox(height: 16),
              Semantics(
                label: 'Display name field',
                child: TextFormField(
                  controller: _displayNameController,
                  decoration: InputDecoration(
                    labelText: 'Display Name',
                    border: const OutlineInputBorder(),
                    labelStyle: GoogleFonts.poppins(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your display name';
                    }
                    return null;
                  },
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      label: 'Email field (read-only)',
                      child: TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          border: const OutlineInputBorder(),
                          hintText: 'Email updates require re-authentication',
                          labelStyle: GoogleFonts.poppins(),
                        ),
                        readOnly: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Semantics(
                    label: 'Sign out to update email',
                    child: TextButton(
                      onPressed: _signOut,
                      child: Text(
                        'Sign Out',
                        style: GoogleFonts.poppins(),
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
              const SizedBox(height: 12),
              Semantics(
                label: 'Phone number field',
                child: TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    border: const OutlineInputBorder(),
                    labelStyle: GoogleFonts.poppins(),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      if (value.length < 10) {
                        return 'Phone number must be at least 10 digits';
                      }
                      if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                        return 'Phone number must contain only digits';
                      }
                    }
                    return null;
                  },
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 400.ms),
              const SizedBox(height: 12),
              Semantics(
                label: 'New password field',
                child: TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    border: const OutlineInputBorder(),
                    labelStyle: GoogleFonts.poppins(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value != null && value.isNotEmpty && value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 500.ms),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: user.isPro
                      ? Colors.green.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: user.isPro ? Colors.green : Colors.grey,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Subscription Status: ${user.isPro ? 'Pro' : 'Free'}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: user.isPro ? Colors.green : Colors.grey,
                          ),
                    ),
                    const SizedBox(height: 8),
                    if (user.isTrialActive)
                      Text(
                        'Trial Active - ${user.remainingTrialDays} days remaining',
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                    if (user.isTrialExpired)
                      Text(
                        'Trial Expired',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.red,
                        ),
                      ),
                    if (user.isSubscribed)
                      Text(
                        'Subscribed until ${user.subscriptionEndDate?.toLocal().toString().split(' ')[0]}',
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                    const SizedBox(height: 12),
                    Semantics(
                      label:
                          user.isPro ? 'Manage subscription' : 'Upgrade to Pro',
                      child: ElevatedButton(
                        onPressed: () => context.go('/subscription'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: user.isPro
                              ? Colors.grey
                              : Theme.of(context).colorScheme.primary,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                        child: Text(user.isPro
                            ? 'Manage Subscription'
                            : 'Upgrade to Pro'),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 600.ms),
              if (user.isPro) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Customize Theme',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _selectedColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Semantics(
                            label: 'Pick a theme color',
                            child: ElevatedButton(
                              onPressed: _pickColor,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                              ),
                              child: Text(
                                'Pick Color',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: 700.ms),
              ],
              const SizedBox(height: 16),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _isLoading
                        ? const CircularProgressIndicator()
                        : Semantics(
                            label: 'Update profile button',
                            child: ElevatedButton(
                              onPressed: _updateProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                              ),
                              child: Text(
                                'Update Profile',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                    const SizedBox(width: 16),
                    _isPasswordLoading
                        ? const CircularProgressIndicator()
                        : Semantics(
                            label: 'Change password button',
                            child: ElevatedButton(
                              onPressed: _changePassword,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.secondary,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                              ),
                              child: Text(
                                'Change Password',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 800.ms),
            ],
          ),
        ),
      ),
    );
  }
}
