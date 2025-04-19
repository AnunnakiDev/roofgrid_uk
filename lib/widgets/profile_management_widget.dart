import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:roofgrid_uk/models/user_model.dart';
import 'package:roofgrid_uk/providers/auth_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

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
  String? _photoURL;
  File? _imageFile;
  bool _isLoading = false;
  final _analytics = FirebaseAnalytics.instance;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider).value;
    _displayNameController =
        TextEditingController(text: user?.displayName ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _photoURL = user?.photoURL;
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
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

        // Update phone number in Firestore directly
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.id)
            .update({
          'phone': _phoneController.text,
          'lastUpdated': FieldValue.serverTimestamp(),
        });

        // Log analytics event
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

        // Email updates are handled via Firebase Auth, which requires re-authentication
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

  Future<void> _signOut() async {
    await ref.read(authProvider.notifier).signOut();
    if (mounted) {
      context.go('/auth/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value;

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
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
              ),
              const SizedBox(height: 16),
              // Profile Picture
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
                ),
              ),
              const SizedBox(height: 16),
              // Display Name
              Semantics(
                label: 'Display name field',
                child: TextFormField(
                  controller: _displayNameController,
                  decoration: const InputDecoration(
                    labelText: 'Display Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your display name';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 12),
              // Email (read-only with sign-out option)
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      label: 'Email field (read-only)',
                      child: TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                          hintText: 'Email updates require re-authentication',
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
                      child: const Text('Sign Out'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Phone Number
              Semantics(
                label: 'Phone number field',
                child: TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
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
              ),
              const SizedBox(height: 16),
              // Subscription Status
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
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    if (user.isTrialExpired)
                      Text(
                        'Trial Expired',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.red,
                            ),
                      ),
                    if (user.isSubscribed)
                      Text(
                        'Subscribed until ${user.subscriptionEndDate?.toLocal().toString().split(' ')[0]}',
                        style: Theme.of(context).textTheme.bodyMedium,
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
              ),
              const SizedBox(height: 16),
              Center(
                child: _isLoading
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
                          child: const Text('Update Profile'),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
