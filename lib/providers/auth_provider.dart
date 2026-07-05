import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:roofgrid_uk/models/user_model.dart';
import 'package:roofgrid_uk/models/tile_model.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:roofgrid_uk/services/hive_service.dart';
import 'package:roofgrid_uk/utils/admin_utils.dart';
import 'package:roofgrid_uk/utils/connectivity_utils.dart';
import 'package:roofgrid_uk/utils/auth_error_utils.dart';
import 'package:roofgrid_uk/utils/email_link_auth_config.dart';
import 'package:roofgrid_uk/utils/remember_me_storage.dart';
import 'package:roofgrid_uk/utils/roofgrid_api_client.dart';

class AuthState {
  final bool isAuthenticated;
  final String? userId;
  final String? error;
  final bool isLoading;

  const AuthState({
    this.isAuthenticated = false,
    this.userId,
    this.error,
    this.isLoading = false,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    String? userId,
    String? error,
    bool? isLoading,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userId: userId ?? this.userId,
      error: error ?? this.error,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId:
        '796676497165-1cti237566v6smagn7o1huscmticpf69.apps.googleusercontent.com',
    scopes: ['email'],
  );
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _storage = const FlutterSecureStorage();
  late HiveService _hiveService;
  late Box<UserModel> _userBox;
  // Toggle reCAPTCHA for development (set to false for emulator testing)
  final bool _isRecaptchaEnabled = false;
  bool _rememberMePolicyApplied = false;

  @override
  AuthState build() {
    _hiveService = ref.read(hiveServiceProvider);

    // Listen to auth state changes to keep the state in sync
    _auth.authStateChanges().listen((User? user) {
      if (user == null) {
        state = const AuthState();
        // print("Auth state changed: User logged out");
      } else {
        state = state.copyWith(
          isAuthenticated: true,
          userId: user.uid,
        );
        // print("Auth state changed: User logged in, UID: ${user.uid}");
      }
    });

    // Initialize Hive box access safely after construction
    _initializeHiveAccess();

    return const AuthState();
  }

  Future<void> _initializeHiveAccess() async {
    try {
      await ref.read(hiveServiceInitializerProvider.future);
      _userBox = await HiveService.ensureUserBox();
      // print("HiveService userBox accessed successfully in AuthNotifier");
    } catch (e) {
      // print("Error initializing Hive access in AuthNotifier: $e");
    }
  }

  Future<UserModel> _ensureDesignatedAdminRole(UserModel userModel) {
    return promoteDesignatedAdminIfNeeded(userModel, _firestore, _userBox);
  }

  Future<bool> login(String email, String password, String captchaToken,
      {bool rememberMe = false}) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      // print("Starting login with email: $email, rememberMe: $rememberMe");

      if (_isRecaptchaEnabled) {
        final response = await postAuthenticatedApi(
          '/verifyCaptcha',
          data: {'token': captchaToken},
        );
        final result = decodeApiJson(response);
        if (result['success'] != true) {
          state = state.copyWith(
            isLoading: false,
            error:
                'CAPTCHA verification failed: ${result['error'] ?? ''}',
          );
          return false;
        }
      } else {
        // print("reCAPTCHA bypassed for development");
      }

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // print("Firebase sign-in successful, UID: ${userCredential.user?.uid}");

      await _persistRememberMePreference(
        rememberMe: rememberMe,
        email: email,
      );

      final isOnline = await isDeviceOnline();

      if (isOnline) {
        final userDoc = await _firestore
            .collection('users')
            .doc(userCredential.user?.uid)
            .get();
        if (userDoc.exists) {
          var userModel = UserModel.fromFirestore(userDoc);
          userModel = await _ensureDesignatedAdminRole(userModel);
          await _userBox.put(userCredential.user!.uid, userModel);
          // print("User data saved to Hive: ${userModel.id}");

          // Initialize tiles only for Pro or Admin users
          if (userModel.isPro || userModel.role == UserRole.admin) {
            await initializeDefaultTiles(userCredential.user!.uid);
          } else {
            // print("Skipping tile initialization: User is free");
          }
        } else {
          final newUser = newUserModelForAuthUser(
            userCredential.user!,
            defaultRole: UserRole.free,
          );
          await _firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .set(newUser.toJson());
          await _userBox.put(userCredential.user!.uid, newUser);
          // print("New user created and saved to Hive: ${newUser.id}");
          // print("Skipping tile initialization: New user is free");
        }
      } else {
        // (removed multi-line print for offline fetch)
      }

      await _analytics.logLogin(loginMethod: 'email');
      state = state.copyWith(
        isAuthenticated: true,
        userId: userCredential.user?.uid,
        isLoading: false,
      );
      // (removed multi-line print for login success)
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isAuthenticated: false,
        error: mapFirebaseAuthError(e.code),
        isLoading: false,
      );
      // print('FirebaseAuthException: ${e.code}, ${e.message}');
      return false;
    } catch (e) {
      state = state.copyWith(
        isAuthenticated: false,
        error: 'Unexpected error: $e',
        isLoading: false,
      );
      // print('Unexpected error: $e');
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      // print("Starting Google Sign-In");
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        state = state.copyWith(isLoading: false);
        // print("Google Sign-In cancelled by user");
        return false;
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      // (removed multi-line print for google sign-in)
      await _analytics.logLogin(loginMethod: 'google');

      final isOnline = await isDeviceOnline();

      if (isOnline) {
        final uid = userCredential.user!.uid;
        final existingDoc =
            await _firestore.collection('users').doc(uid).get();

        if (!existingDoc.exists) {
          final now = DateTime.now();
          final newUser = newUserModelForAuthUser(
            userCredential.user!,
            defaultRole: UserRole.pro,
            proTrialStartDate: now,
            proTrialEndDate: now.add(const Duration(days: 14)),
            createdAt: now,
            lastLoginAt: now,
          );
          await _firestore.collection('users').doc(uid).set(newUser.toJson());
        } else {
          await _firestore.collection('users').doc(uid).set({
            'displayName': userCredential.user?.displayName ?? 'User',
            'email': userCredential.user?.email,
            'lastLoginAt': FieldValue.serverTimestamp(),
            'photoURL': userCredential.user?.photoURL,
          }, SetOptions(merge: true));
        }

        await _waitForUserDocument(uid);

        final userDoc = await _firestore
            .collection('users')
            .doc(userCredential.user?.uid)
            .get();
        var userModel = UserModel.fromFirestore(userDoc);
        userModel = await _ensureDesignatedAdminRole(userModel);
        await _userBox.put(userCredential.user!.uid, userModel);
        // print("Google Sign-In user data saved to Hive: ${userModel.id}");

        if (userModel.isPro || userModel.role == UserRole.admin) {
          await initializeDefaultTiles(userCredential.user!.uid);
        } else {
          // print("Skipping tile initialization: Google Sign-In user is free");
        }
      } else {
        // print("Offline: Creating temporary user data in Hive");
        final userModel = UserModel.fromFirebaseUser(userCredential.user!);
        await _userBox.put(userCredential.user!.uid, userModel);
        // print("Skipping tile initialization: Offline user is free");
      }

      state = state.copyWith(
        isAuthenticated: true,
        userId: userCredential.user?.uid,
        isLoading: false,
      );
      // (removed multi-line print for google complete)
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isAuthenticated: false,
        error: mapFirebaseAuthError(e.code),
        isLoading: false,
      );
      // (removed multi-line print for google auth err)
      return false;
    } catch (e) {
      state = state.copyWith(
        isAuthenticated: false,
        error: 'An unexpected error occurred.',
        isLoading: false,
      );
      // print("Unexpected error during Google Sign-In: $e");
      return false;
    }
  }

  Future<bool> resetPassword(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    try {
      state = state.copyWith(isLoading: true, error: null);
      if (!await isDeviceOnline()) {
        state = state.copyWith(
          isLoading: false,
          error: 'No internet connection. Please try again when online.',
        );
        return false;
      }

      await _auth.sendPasswordResetEmail(
        email: normalizedEmail,
        actionCodeSettings:
            EmailLinkAuthConfig.buildPasswordResetActionCodeSettings(),
      );
      if (kDebugMode) {
        debugPrint('Password reset email requested for $normalizedEmail');
      }
      await _analytics.logEvent(name: 'password_reset');
      state = state.copyWith(isLoading: false);
      return true;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        debugPrint(
          'Password reset failed: ${e.code} ${e.message ?? ''}'.trim(),
        );
      }
      state = state.copyWith(
        error: mapFirebaseAuthError(e.code),
        isLoading: false,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        error: 'An unexpected error occurred.',
        isLoading: false,
      );
      // print("Unexpected error during password reset: $e");
      return false;
    }
  }

  Future<bool> sendEmailSignInLink(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    try {
      state = state.copyWith(isLoading: true, error: null);
      if (!await isDeviceOnline()) {
        state = state.copyWith(
          isLoading: false,
          error: 'No internet connection. Please try again when online.',
        );
        return false;
      }

      await _auth.sendSignInLinkToEmail(
        email: normalizedEmail,
        actionCodeSettings:
            EmailLinkAuthConfig.buildEmailLinkActionCodeSettings(),
      );
      await _storage.write(
        key: EmailLinkAuthConfig.pendingEmailStorageKey,
        value: normalizedEmail,
      );
      await _analytics.logEvent(name: 'email_link_sent');
      state = state.copyWith(isLoading: false);
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        error: mapFirebaseAuthError(e.code),
        isLoading: false,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        error: 'Could not send sign-in link. Please try again.',
        isLoading: false,
      );
      return false;
    }
  }

  Future<String?> getPendingEmailLinkEmail() {
    return _storage.read(key: EmailLinkAuthConfig.pendingEmailStorageKey);
  }

  Future<void> clearPendingEmailLinkEmail() {
    return _storage.delete(key: EmailLinkAuthConfig.pendingEmailStorageKey);
  }

  Future<bool> completeEmailLinkSignIn({
    required String emailLink,
    String? email,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      if (!_auth.isSignInWithEmailLink(emailLink)) {
        state = state.copyWith(
          isLoading: false,
          error: 'This link is not a valid sign-in link.',
        );
        return false;
      }

      final resolvedEmail =
          (email ?? await getPendingEmailLinkEmail())?.trim().toLowerCase();
      if (resolvedEmail == null || resolvedEmail.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          error:
              'Enter the same email address you used to request the sign-in link.',
        );
        return false;
      }

      final userCredential = await _auth.signInWithEmailLink(
        email: resolvedEmail,
        emailLink: emailLink,
      );

      await _syncUserAfterAuthentication(
        userCredential,
        loginMethod: 'email_link',
      );
      await clearPendingEmailLinkEmail();
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isAuthenticated: false,
        error: mapFirebaseAuthError(e.code),
        isLoading: false,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isAuthenticated: false,
        error: 'Could not complete sign-in. Please request a new link.',
        isLoading: false,
      );
      return false;
    }
  }

  Future<void> _syncUserAfterAuthentication(
    UserCredential userCredential, {
    required String loginMethod,
  }) async {
    final user = userCredential.user;
    if (user == null) {
      throw Exception('Authentication succeeded without a user record.');
    }

    final isOnline = await isDeviceOnline();
    if (isOnline) {
      final uid = user.uid;
      final existingDoc = await _firestore.collection('users').doc(uid).get();

      if (!existingDoc.exists) {
        final now = DateTime.now();
        final newUser = newUserModelForAuthUser(
          user,
          defaultRole: UserRole.pro,
          proTrialStartDate: now,
          proTrialEndDate: now.add(const Duration(days: 14)),
          createdAt: now,
          lastLoginAt: now,
        );
        await _firestore.collection('users').doc(uid).set(newUser.toJson());
      } else {
        await _firestore.collection('users').doc(uid).set({
          'displayName': user.displayName ?? 'User',
          'email': user.email,
          'lastLoginAt': FieldValue.serverTimestamp(),
          'photoURL': user.photoURL,
        }, SetOptions(merge: true));
      }

      await _waitForUserDocument(uid);
      final userDoc = await _firestore.collection('users').doc(uid).get();
      var userModel = UserModel.fromFirestore(userDoc);
      userModel = await _ensureDesignatedAdminRole(userModel);
      await _userBox.put(uid, userModel);

      if (userModel.isPro || userModel.role == UserRole.admin) {
        await initializeDefaultTiles(uid);
      }
    } else {
      final userModel = UserModel.fromFirebaseUser(user);
      await _userBox.put(user.uid, userModel);
    }

    if (loginMethod == 'email_link') {
      await _analytics.logLogin(loginMethod: 'email_link');
    }

    state = state.copyWith(
      isAuthenticated: true,
      userId: user.uid,
      isLoading: false,
    );
  }

  Future<void> _persistRememberMePreference({
    required bool rememberMe,
    required String email,
  }) async {
    if (rememberMe) {
      await _storage.write(key: RememberMeStorage.enabledKey, value: 'true');
      await _storage.write(
        key: RememberMeStorage.emailKey,
        value: email.trim().toLowerCase(),
      );
    } else {
      await _storage.write(key: RememberMeStorage.enabledKey, value: 'false');
      await _storage.delete(key: RememberMeStorage.emailKey);
    }
    await _storage.delete(key: 'auth_token');
  }

  Future<RememberMePreferences> loadRememberMePreferences() async {
    final enabledValue = await _storage.read(key: RememberMeStorage.enabledKey);
    final email = await _storage.read(key: RememberMeStorage.emailKey);
    return RememberMePreferences(
      enabled: RememberMeStorage.isEnabled(enabledValue),
      email: email,
    );
  }

  /// Signs out restored Firebase sessions when the user did not opt in to Remember Me.
  Future<void> applyRememberMePolicy() async {
    if (_rememberMePolicyApplied) return;
    _rememberMePolicyApplied = true;

    try {
      final enabledValue =
          await _storage.read(key: RememberMeStorage.enabledKey);
      final rememberMeEnabled = RememberMeStorage.isEnabled(enabledValue);

      if (!rememberMeEnabled && _auth.currentUser != null) {
        await _auth.signOut();
        await _googleSignIn.signOut();
        state = const AuthState();
      } else if (rememberMeEnabled && _auth.currentUser != null) {
        await _syncRememberedUserData();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Remember Me policy error: $e');
      }
    }
  }

  Future<void> _syncRememberedUserData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final isOnline = await isDeviceOnline();
      if (isOnline) {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          var userModel = UserModel.fromFirestore(userDoc);
          userModel = await _ensureDesignatedAdminRole(userModel);
          await _userBox.put(user.uid, userModel);
          if (userModel.isPro || userModel.role == UserRole.admin) {
            await initializeDefaultTiles(user.uid);
          }
        }
      }

      state = state.copyWith(
        isAuthenticated: true,
        userId: user.uid,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Remember Me sync error: $e');
      }
    }
  }

  Future<void> signOut() async {
    try {
      // print("Starting sign-out process");
      await _storage.delete(key: RememberMeStorage.enabledKey);
      await _storage.delete(key: RememberMeStorage.emailKey);
      await _storage.delete(key: 'auth_token');
      await clearPendingEmailLinkEmail();
      await _userBox.delete(_auth.currentUser?.uid);
      await _auth.signOut();
      await _googleSignIn.signOut();
      await _analytics.logEvent(name: 'sign_out');
      state = const AuthState();
      // (removed multi-line print for sign out)
    } catch (e) {
      state = state.copyWith(error: 'Failed to sign out: $e');
      // print("Sign out error: $e");
    }
  }

  Future<bool> registerWithEmailAndPassword(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      if (!await isDeviceOnline()) {
        state = state.copyWith(
          isLoading: false,
          error: 'No internet connection. Please try again when online.',
        );
        return false;
      }

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await userCredential.user?.updateDisplayName(displayName);

      final now = DateTime.now();
      final newUser = newUserModelForAuthUser(
        userCredential.user!,
        defaultRole: UserRole.pro,
        proTrialStartDate: now,
        proTrialEndDate: now.add(const Duration(days: 14)),
        createdAt: now,
        lastLoginAt: now,
      ).copyWith(displayName: displayName);

      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(newUser.toJson());
      await _waitForUserDocument(userCredential.user!.uid);
      await _userBox.put(userCredential.user!.uid, newUser);

      if (newUser.role == UserRole.admin || newUser.isPro) {
        await initializeDefaultTiles(userCredential.user!.uid);
      }

      await _analytics.logSignUp(signUpMethod: 'email');
      state = state.copyWith(
        isAuthenticated: true,
        userId: userCredential.user?.uid,
        isLoading: false,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isAuthenticated: false,
        error: mapFirebaseAuthError(e.code),
        isLoading: false,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isAuthenticated: false,
        error: 'An unexpected error occurred.',
        isLoading: false,
      );
      return false;
    }
  }

  Future<bool> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      // print("Starting user creation with email: $email");
      if (!await isDeviceOnline()) {
        state = state.copyWith(
          isLoading: false,
          error: 'No internet connection. Please try again when online.',
        );
        // print("User creation failed: No internet connection");
        return false;
      }

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final now = DateTime.now();
      final newUser = newUserModelForAuthUser(
        userCredential.user!,
        defaultRole: UserRole.pro,
        proTrialStartDate: now,
        proTrialEndDate: now.add(const Duration(days: 14)),
        createdAt: now,
        lastLoginAt: now,
      );
      await _firestore
          .collection('users')
          .doc(userCredential.user?.uid)
          .set(newUser.toJson());

      await _waitForUserDocument(userCredential.user!.uid);

      await _userBox.put(userCredential.user!.uid, newUser);
      // print("New user created and saved to Hive: ${newUser.id}");

      if (newUser.role == UserRole.admin || newUser.isPro) {
        await initializeDefaultTiles(userCredential.user!.uid);
      }

      state = state.copyWith(
        isAuthenticated: true,
        userId: userCredential.user?.uid,
        isLoading: false,
      );
      // (removed multi-line print for user creation)
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isAuthenticated: false,
        error: mapFirebaseAuthError(e.code),
        isLoading: false,
      );
      // (removed multi-line print for user creation err)
      return false;
    } catch (e) {
      state = state.copyWith(
        isAuthenticated: false,
        error: 'An unexpected error occurred.',
        isLoading: false,
      );
      // print("Unexpected error during user creation: $e");
      return false;
    }
  }

  Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
  }) async {
    if (!await isDeviceOnline()) {
      state = state.copyWith(
          error:
              'No internet connection. Profile update requires online access.');
      // print("Profile update failed: No internet connection");
      return;
    }

    final user = _auth.currentUser;
    if (user != null) {
      // (removed multi-line print for profile update)
      await user.updateDisplayName(displayName);
      await user.updatePhotoURL(photoURL);
      await _firestore.collection('users').doc(user.uid).update({
        if (displayName != null) 'displayName': displayName,
        if (photoURL != null) 'photoURL': photoURL,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final userModel = UserModel.fromFirestore(userDoc);
        await _userBox.put(user.uid, userModel);
        // print("User profile updated in Hive: ${userModel.id}");
      }
    } else {
      // print("Profile update failed: No user logged in");
    }
  }

  Future<bool> upgradeToProStatus() async {
    try {
      if (!await isDeviceOnline()) {
        state = state.copyWith(
          isLoading: false,
          error: 'No internet connection. Upgrade requires online access.',
        );
        // print("Upgrade to Pro failed: No internet connection");
        return false;
      }

      state = state.copyWith(isLoading: true, error: null);
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        state = state.copyWith(isLoading: false, error: 'No user logged in.');
        // print("Upgrade to Pro failed: No user logged in");
        return false;
      }
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'role': 'pro',
        'proTrialStartDate': Timestamp.now(),
        'proTrialEndDate': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 14)),
        ),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final userModel = UserModel.fromFirestore(userDoc);
        await _userBox.put(userId, userModel);
        // print("User upgraded to Pro and saved to Hive: ${userModel.id}");

        // Initialize tiles for newly upgraded Pro user
        await initializeDefaultTiles(userId);
      }

      await _analytics.logEvent(name: 'upgrade_to_pro');
      state = state.copyWith(isLoading: false);
      // print("Upgrade to Pro successful for UID: $userId");
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to upgrade: $e');
      // print("Error during upgrade to Pro: $e");
      return false;
    }
  }

  Future<void> initializeDefaultTiles(String userId) async {
    try {
      // print('Initializing default tiles for user: $userId');
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        // print('User document not found for UID: $userId');
        return;
      }
      final userModel = UserModel.fromFirestore(userDoc);
      if (!userModel.isPro && userModel.role != UserRole.admin) {
        // print('Skipping tile initialization: User is not Pro or Admin');
        return;
      }

      final isOnline = await isDeviceOnline();

      if (isOnline) {
        // Sync existing tiles from Firestore to Hive
        final querySnapshot = await _firestore
            .collection('tiles')
            .where('isPublic', isEqualTo: true)
            .where('isApproved', isEqualTo: true)
            .get();
        final tiles = querySnapshot.docs
            .map((doc) => TileModel.fromJson(doc.data()))
            .toList();

        for (var tile in tiles) {
          await _hiveService.tilesBox.put(tile.id, tile);
        }
        // print('Synced ${tiles.length} tiles from Firestore to Hive');

        await _analytics.logEvent(
          name: 'sync_default_tiles',
          parameters: {'tile_count': tiles.length},
        );
      } else {
        // print('Offline: Using cached tiles from Hive');
        // print('Loaded ${_hiveService.tilesBox.length} cached tiles from Hive');
      }
    } catch (e) {
      // print('Failed to initialize default tiles: $e');
      // Log non-fatal error instead of crashing
      await _analytics.logEvent(
        name: 'tile_initialization_error',
        parameters: {'error': e.toString()},
      );
    }
  }

  Future<void> initializeDefaultTilesForAdmin() async {
    try {
      // print('Initializing default tiles for Admin');
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        // print('No user logged in for Admin tile initialization');
        return;
      }
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists || userDoc.data()!['role'] != 'admin') {
        // print('Skipping Admin tile initialization: User is not Admin');
        return;
      }

      final isOnline = await isDeviceOnline();
      if (!isOnline) {
        // print('Offline: Cannot initialize default tiles for Admin');
        return;
      }

      final now = DateTime.now();
      final defaultTiles = [
        TileModel(
          id: '1',
          name: 'Standard Slate',
          manufacturer: 'Generic',
          materialType: TileSlateType.slate,
          description: 'Standard 500x250mm natural slate',
          isPublic: true,
          isApproved: true,
          createdById: userId,
          createdAt: now,
          updatedAt: now,
          slateTileHeight: 500,
          tileCoverWidth: 250,
          minGauge: 195,
          maxGauge: 210,
          minSpacing: 1,
          maxSpacing: 5,
          defaultCrossBonded: true,
          image: 'assets/images/tiles/natural_slate.jpg',
        ),
        TileModel(
          id: '2',
          name: 'Standard Plain Tile',
          manufacturer: 'Generic',
          materialType: TileSlateType.plainTile,
          description: 'Standard 265x165mm clay plain tile',
          isPublic: true,
          isApproved: true,
          createdById: userId,
          createdAt: now,
          updatedAt: now,
          slateTileHeight: 265,
          minGauge: 85,
          maxGauge: 115,
          tileCoverWidth: 165,
          minSpacing: 1,
          maxSpacing: 7,
          defaultCrossBonded: true,
          image: 'assets/images/tiles/plain_tile.png',
        ),
        TileModel(
          id: '3',
          name: 'Standard Concrete Tile',
          manufacturer: 'Generic',
          materialType: TileSlateType.concreteTile,
          description: 'Standard 420x330mm concrete tile',
          isPublic: true,
          isApproved: true,
          createdById: userId,
          createdAt: now,
          updatedAt: now,
          slateTileHeight: 420,
          minGauge: 310,
          maxGauge: 345,
          tileCoverWidth: 300,
          minSpacing: 1,
          maxSpacing: 5,
          defaultCrossBonded: false,
          image: 'assets/images/tiles/concrete_tile.jpg',
        ),
      ];

      for (var tile in defaultTiles) {
        await _firestore.collection('tiles').doc(tile.id).set(
              tile.toJson(),
              SetOptions(merge: true),
            );

        await _hiveService.tilesBox.put(tile.id, tile);
      }

      await _analytics.logEvent(
        name: 'initialize_default_tiles_admin',
        parameters: {'tile_count': defaultTiles.length},
      );
      // print("Default tiles initialized successfully for Admin");
    } catch (e) {
      // print('Failed to initialize default tiles for Admin: $e');
      await _analytics.logEvent(
        name: 'admin_tile_initialization_error',
        parameters: {'error': e.toString()},
      );
    }
  }

  Future<void> _waitForUserDocument(String userId) async {
    const maxAttempts = 3;
    const delay = Duration(milliseconds: 500);
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        // print("User document found after $attempt attempts");
        return;
      }
      // (removed multi-line print for user doc retry)
      await Future.delayed(delay);
    }
    throw Exception("User document not found after $maxAttempts attempts");
  }

  bool isUserLoggedIn() {
    return _auth.currentUser != null;
  }

}

class RememberMePreferences {
  final bool enabled;
  final String? email;

  const RememberMePreferences({
    required this.enabled,
    this.email,
  });
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

final authStateStreamProvider = StreamProvider<UserModel?>((ref) {
  final authNotifier = ref.watch(authProvider.notifier);
  return authNotifier._auth.authStateChanges().map(
        (User? user) => user != null ? UserModel.fromFirebaseUser(user) : null,
      );
});

final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final userId = ref.watch(authProvider.select((state) => state.userId));
  if (userId == null) {
    // print("Current user provider: No user ID, returning null");
    return Stream.value(null);
  }

  return Stream.fromFuture(
    Future.wait([isDeviceOnline(), HiveService.ensureUserBox()]),
  ).asyncExpand((results) {
    final isOnline = results[0] as bool;
    final hiveService = ref.read(hiveServiceProvider);
    final userBox = hiveService.userBox;

    if (isOnline) {
      return _fetchUserWithRetry(userId).asyncMap((snapshot) async {
        if (snapshot.exists) {
          var userModel = UserModel.fromFirestore(snapshot);
          userModel = await promoteDesignatedAdminIfNeeded(
            userModel,
            FirebaseFirestore.instance,
            userBox,
          );
          await userBox.put(userId, userModel);
          // (removed multi-line print for current user firestore)
          return userModel;
        }
        // print("Current user provider: User document not found in Firestore");
        return null;
      }).handleError((error) {
        // print("Error fetching user from Firestore: $error");
        final userModel = userBox.get(userId);
        // (removed multi-line print for current user hive)
        return Stream.value(userModel);
      });
    } else {
      // print("Current user provider: Offline, fetching user from Hive");
      final userModel = userBox.get(userId);
      return Stream.value(userModel);
    }
  });
});

Stream<DocumentSnapshot> _fetchUserWithRetry(String userId) async* {
  const maxAttempts = 3;
  const delay = Duration(milliseconds: 500);
  for (int attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (snapshot.exists) {
        yield snapshot;
        yield* FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .snapshots();
        return;
      }
      // (removed multi-line print for user doc retry)
      await Future.delayed(delay);
    } catch (e) {
      // print("Error fetching user document, attempt $attempt/$maxAttempts: $e");
      if (attempt == maxAttempts) {
        throw Exception(
            'Failed to load user data after $maxAttempts attempts: $e');
      }
      await Future.delayed(delay);
    }
  }
  throw TimeoutException('Failed to load user data in time');
}
