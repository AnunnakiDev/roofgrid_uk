import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:roofgrid_uk/models/user_model.dart';
import 'package:roofgrid_uk/models/tile_model.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:roofgrid_uk/services/hive_service.dart';

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

class AuthNotifier extends StateNotifier<AuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId:
        '796676497165-1cti237566v6smagn7o1huscmticpf69.apps.googleusercontent.com',
    scopes: ['email'],
  );
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _storage = const FlutterSecureStorage();
  final Ref _ref;
  final HiveService _hiveService;
  late final Box<UserModel> _userBox;
  // Toggle reCAPTCHA for development (set to false for emulator testing)
  final bool _isRecaptchaEnabled = false;

  AuthNotifier(this._ref)
      : _hiveService = _ref.read(hiveServiceProvider),
        super(const AuthState()) {
    // Listen to auth state changes to keep the state in sync
    _auth.authStateChanges().listen((User? user) {
      if (user == null) {
        state = const AuthState();
        print("Auth state changed: User logged out");
      } else {
        state = state.copyWith(
          isAuthenticated: true,
          userId: user.uid,
        );
        print("Auth state changed: User logged in, UID: ${user.uid}");
      }
    });

    // Initialize Hive box access safely after construction
    _initializeHiveAccess();
  }

  Future<void> _initializeHiveAccess() async {
    try {
      await _ref.read(hiveServiceInitializerProvider.future);
      _userBox = _hiveService.userBox;
      print("HiveService userBox accessed successfully in AuthNotifier");
    } catch (e) {
      print("Error initializing Hive access in AuthNotifier: $e");
    }
  }

  Future<bool> login(String email, String password, String captchaToken,
      {bool rememberMe = false}) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      print("Starting login with email: $email, rememberMe: $rememberMe");

      if (_isRecaptchaEnabled) {
        final callable =
            FirebaseFunctions.instance.httpsCallable('verifyCaptcha');
        final result = await callable.call({'token': captchaToken});
        if (result.data['success'] != true) {
          state = state.copyWith(
            isLoading: false,
            error:
                'CAPTCHA verification failed: ${result.data['message'] ?? ''}',
          );
          print("CAPTCHA verification failed: ${result.data['message']}");
          return false;
        }
      } else {
        print("reCAPTCHA bypassed for development");
      }

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print("Firebase sign-in successful, UID: ${userCredential.user?.uid}");

      if (rememberMe) {
        final token = await userCredential.user?.getIdToken();
        if (token != null) {
          await _storage.write(key: 'auth_token', value: token);
          print("Stored auth token for Remember Me");
        }
      }

      final connectivityResult = await Connectivity().checkConnectivity();
      bool isOnline = connectivityResult != ConnectivityResult.none;

      if (isOnline) {
        final userDoc = await _firestore
            .collection('users')
            .doc(userCredential.user?.uid)
            .get();
        if (userDoc.exists) {
          final userModel = UserModel.fromFirestore(userDoc);
          await _userBox.put(userCredential.user!.uid, userModel);
          print("User data saved to Hive: ${userModel.id}");

          // Initialize tiles only for Pro or Admin users
          if (userModel.isPro || userModel.role == UserRole.admin) {
            await initializeDefaultTiles(userCredential.user!.uid);
          } else {
            print("Skipping tile initialization: User is free");
          }
        } else {
          final newUser = UserModel.fromFirebaseUser(userCredential.user!);
          await _firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .set(newUser.toJson());
          await _userBox.put(userCredential.user!.uid, newUser);
          print("New user created and saved to Hive: ${newUser.id}");
          print("Skipping tile initialization: New user is free");
        }
      } else {
        print(
            "Offline: Skipping Firestore fetch, using Hive data if available");
      }

      await _analytics.logLogin(loginMethod: 'email');
      state = state.copyWith(
        isAuthenticated: true,
        userId: userCredential.user?.uid,
        isLoading: false,
      );
      print(
          "Login successful, updated state: isAuthenticated=${state.isAuthenticated}, userId=${state.userId}");
      return true;
    } on FirebaseFunctionsException catch (e) {
      state = state.copyWith(
        isAuthenticated: false,
        error: 'CAPTCHA error: ${e.message} (Code: ${e.code})',
        isLoading: false,
      );
      print('FirebaseFunctionsException: ${e.code}, ${e.message}');
      return false;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isAuthenticated: false,
        error: mapFirebaseError(e.code),
        isLoading: false,
      );
      print('FirebaseAuthException: ${e.code}, ${e.message}');
      return false;
    } catch (e) {
      state = state.copyWith(
        isAuthenticated: false,
        error: 'Unexpected error: $e',
        isLoading: false,
      );
      print('Unexpected error: $e');
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      print("Starting Google Sign-In");
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        state = state.copyWith(isLoading: false);
        print("Google Sign-In cancelled by user");
        return false;
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      print(
          "Google Sign-In successful with Firebase, UID: ${userCredential.user?.uid}");
      await _analytics.logLogin(loginMethod: 'google');

      final connectivityResult = await Connectivity().checkConnectivity();
      bool isOnline = connectivityResult != ConnectivityResult.none;

      if (isOnline) {
        await _firestore.collection('users').doc(userCredential.user?.uid).set({
          'displayName': userCredential.user?.displayName ?? 'User',
          'email': userCredential.user?.email,
          'role': 'free',
          'createdAt': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
          'photoURL': userCredential.user?.photoURL,
        }, SetOptions(merge: true));

        await _waitForUserDocument(userCredential.user!.uid);

        final userDoc = await _firestore
            .collection('users')
            .doc(userCredential.user?.uid)
            .get();
        final userModel = UserModel.fromFirestore(userDoc);
        await _userBox.put(userCredential.user!.uid, userModel);
        print("Google Sign-In user data saved to Hive: ${userModel.id}");

        if (userModel.isPro || userModel.role == UserRole.admin) {
          await initializeDefaultTiles(userCredential.user!.uid);
        } else {
          print("Skipping tile initialization: Google Sign-In user is free");
        }
      } else {
        print("Offline: Creating temporary user data in Hive");
        final userModel = UserModel.fromFirebaseUser(userCredential.user!);
        await _userBox.put(userCredential.user!.uid, userModel);
        print("Skipping tile initialization: Offline user is free");
      }

      state = state.copyWith(
        isAuthenticated: true,
        userId: userCredential.user?.uid,
        isLoading: false,
      );
      print(
          "Google Sign-In completed, updated state: isAuthenticated=${state.isAuthenticated}, userId=${state.userId}");
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isAuthenticated: false,
        error: mapFirebaseError(e.code),
        isLoading: false,
      );
      print(
          "FirebaseAuthException during Google Sign-In: ${e.code}, ${e.message}");
      return false;
    } catch (e) {
      state = state.copyWith(
        isAuthenticated: false,
        error: 'An unexpected error occurred.',
        isLoading: false,
      );
      print("Unexpected error during Google Sign-In: $e");
      return false;
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      print("Starting password reset for email: $email");
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        state = state.copyWith(
          isLoading: false,
          error: 'No internet connection. Please try again when online.',
        );
        print("Password reset failed: No internet connection");
        return false;
      }

      await _auth.sendPasswordResetEmail(email: email);
      await _analytics.logEvent(name: 'password_reset');
      state = state.copyWith(isLoading: false);
      print("Password reset email sent successfully");
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(error: mapFirebaseError(e.code), isLoading: false);
      print(
          "FirebaseAuthException during password reset: ${e.code}, ${e.message}");
      return false;
    } catch (e) {
      state = state.copyWith(
        error: 'An unexpected error occurred.',
        isLoading: false,
      );
      print("Unexpected error during password reset: $e");
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      print("Starting sign-out process");
      await _storage.delete(key: 'auth_token');
      await _userBox.delete(_auth.currentUser?.uid);
      await _auth.signOut();
      await _googleSignIn.signOut();
      await _analytics.logEvent(name: 'sign_out');
      state = const AuthState();
      print(
          "User signed out successfully, updated state: isAuthenticated=${state.isAuthenticated}");
    } catch (e) {
      state = state.copyWith(error: 'Failed to sign out: $e');
      print("Sign out error: $e");
    }
  }

  Future<bool> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      print("Starting user creation with email: $email");
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        state = state.copyWith(
          isLoading: false,
          error: 'No internet connection. Please try again when online.',
        );
        print("User creation failed: No internet connection");
        return false;
      }

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String role = 'free';
      if (email.toLowerCase() == 'admin@example.com' ||
          email.toLowerCase() == 'support@roofgrid.uk') {
        role = 'admin';
      }

      final now = DateTime.now();
      final trialStartDate = now;
      final trialEndDate = now.add(const Duration(days: 14));

      final newUser = UserModel.fromFirebaseUser(
        userCredential.user!,
        role: UserRole.values
            .firstWhere((r) => r.toString().split('.').last == role),
        proTrialStartDate: trialStartDate,
        proTrialEndDate: trialEndDate,
        createdAt: now,
        lastLoginAt: now,
      );
      await _firestore
          .collection('users')
          .doc(userCredential.user?.uid)
          .set(newUser.toJson());

      await _waitForUserDocument(userCredential.user!.uid);

      await _userBox.put(userCredential.user!.uid, newUser);
      print("New user created and saved to Hive: ${newUser.id}");

      if (role == 'admin') {
        await initializeDefaultTiles(userCredential.user!.uid);
      } else {
        print("Skipping tile initialization: New user is free");
      }

      state = state.copyWith(
        isAuthenticated: true,
        userId: userCredential.user?.uid,
        isLoading: false,
      );
      print(
          "User creation successful, updated state: isAuthenticated=${state.isAuthenticated}, userId=${state.userId}");
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isAuthenticated: false,
        error: mapFirebaseError(e.code),
        isLoading: false,
      );
      print(
          "FirebaseAuthException during user creation: ${e.code}, ${e.message}");
      return false;
    } catch (e) {
      state = state.copyWith(
        isAuthenticated: false,
        error: 'An unexpected error occurred.',
        isLoading: false,
      );
      print("Unexpected error during user creation: $e");
      return false;
    }
  }

  Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
  }) async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      state = state.copyWith(
          error:
              'No internet connection. Profile update requires online access.');
      print("Profile update failed: No internet connection");
      return;
    }

    final user = _auth.currentUser;
    if (user != null) {
      print(
          "Updating user profile for UID: ${user.uid}, displayName: $displayName, photoURL: $photoURL");
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
        print("User profile updated in Hive: ${userModel.id}");
      }
    } else {
      print("Profile update failed: No user logged in");
    }
  }

  Future<bool> upgradeToProStatus() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        state = state.copyWith(
          isLoading: false,
          error: 'No internet connection. Upgrade requires online access.',
        );
        print("Upgrade to Pro failed: No internet connection");
        return false;
      }

      state = state.copyWith(isLoading: true, error: null);
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        state = state.copyWith(isLoading: false, error: 'No user logged in.');
        print("Upgrade to Pro failed: No user logged in");
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
        print("User upgraded to Pro and saved to Hive: ${userModel.id}");

        // Initialize tiles for newly upgraded Pro user
        await initializeDefaultTiles(userId);
      }

      await _analytics.logEvent(name: 'upgrade_to_pro');
      state = state.copyWith(isLoading: false);
      print("Upgrade to Pro successful for UID: $userId");
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to upgrade: $e');
      print("Error during upgrade to Pro: $e");
      return false;
    }
  }

  Future<void> initializeDefaultTiles(String userId) async {
    try {
      print('Initializing default tiles for user: $userId');
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        print('User document not found for UID: $userId');
        return;
      }
      final userModel = UserModel.fromFirestore(userDoc);
      if (!userModel.isPro && userModel.role != UserRole.admin) {
        print('Skipping tile initialization: User is not Pro or Admin');
        return;
      }

      final connectivityResult = await Connectivity().checkConnectivity();
      bool isOnline = connectivityResult != ConnectivityResult.none;

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
        print('Synced ${tiles.length} tiles from Firestore to Hive');

        await _analytics.logEvent(
          name: 'sync_default_tiles',
          parameters: {'tile_count': tiles.length},
        );
      } else {
        print('Offline: Using cached tiles from Hive');
        final tiles = _hiveService.tilesBox.values.toList();
        print('Loaded ${tiles.length} cached tiles from Hive');
      }
    } catch (e) {
      print('Failed to initialize default tiles: $e');
      // Log non-fatal error instead of crashing
      await _analytics.logEvent(
        name: 'tile_initialization_error',
        parameters: {'error': e.toString()},
      );
    }
  }

  Future<void> initializeDefaultTilesForAdmin() async {
    try {
      print('Initializing default tiles for Admin');
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        print('No user logged in for Admin tile initialization');
        return;
      }
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists || userDoc.data()!['role'] != 'admin') {
        print('Skipping Admin tile initialization: User is not Admin');
        return;
      }

      final connectivityResult = await Connectivity().checkConnectivity();
      bool isOnline = connectivityResult != ConnectivityResult.none;
      if (!isOnline) {
        print('Offline: Cannot initialize default tiles for Admin');
        return;
      }

      final existingTiles = await _firestore.collection('tiles').get();
      if (existingTiles.docs.isNotEmpty) {
        print('Default tiles already initialized in Firestore');
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
        ),
      ];

      for (var tile in defaultTiles) {
        await _firestore.collection('tiles').doc(tile.id).set({
          'id': tile.id,
          'name': tile.name,
          'manufacturer': tile.manufacturer,
          'materialType': tile.materialType.toString().split('.').last,
          'description': tile.description,
          'isPublic': tile.isPublic,
          'isApproved': tile.isApproved,
          'createdById': tile.createdById,
          'createdAt': Timestamp.fromDate(tile.createdAt),
          'updatedAt': Timestamp.fromDate(tile.updatedAt),
          'slateTileHeight': tile.slateTileHeight,
          'tileCoverWidth': tile.tileCoverWidth,
          'minGauge': tile.minGauge,
          'maxGauge': tile.maxGauge,
          'minSpacing': tile.minSpacing,
          'maxSpacing': tile.maxSpacing,
          'defaultCrossBonded': tile.defaultCrossBonded,
        }, SetOptions(merge: true));

        await _hiveService.tilesBox.put(tile.id, tile);
      }

      await _analytics.logEvent(
        name: 'initialize_default_tiles_admin',
        parameters: {'tile_count': defaultTiles.length},
      );
      print("Default tiles initialized successfully for Admin");
    } catch (e) {
      print('Failed to initialize default tiles for Admin: $e');
      await _analytics.logEvent(
        name: 'admin_tile_initialization_error',
        parameters: {'error': e.toString()},
      );
    }
  }

  Future<bool> checkPersistentLogin() async {
    try {
      print('Checking persistent login');
      final token = await _storage.read(key: 'auth_token');
      if (token != null && _auth.currentUser != null) {
        final connectivityResult = await Connectivity().checkConnectivity();
        bool isOnline = connectivityResult != ConnectivityResult.none;
        if (isOnline) {
          final userDoc = await _firestore
              .collection('users')
              .doc(_auth.currentUser!.uid)
              .get();
          if (userDoc.exists) {
            final userModel = UserModel.fromFirestore(userDoc);
            await _userBox.put(_auth.currentUser!.uid, userModel);
            print("User data synced from Firestore to Hive: ${userModel.id}");

            if (userModel.isPro || userModel.role == UserRole.admin) {
              await initializeDefaultTiles(_auth.currentUser!.uid);
            } else {
              print("Skipping tile initialization: User is free");
            }
          }
        } else {
          print("Offline: Using user data from Hive");
        }

        state = state.copyWith(
          isAuthenticated: true,
          userId: _auth.currentUser!.uid,
        );
        print(
            "Persistent login successful, UID: ${_auth.currentUser!.uid}, updated state: isAuthenticated=${state.isAuthenticated}");
        return true;
      }
      print("No persistent login found");
      return false;
    } catch (e) {
      print('Error checking persistent login: $e');
      return false;
    }
  }

  Future<void> _waitForUserDocument(String userId) async {
    const maxAttempts = 10;
    const delay = Duration(milliseconds: 500);
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        print("User document found after $attempt attempts");
        return;
      }
      print(
          "User document not found, attempt $attempt/$maxAttempts, retrying...");
      await Future.delayed(delay);
    }
    throw Exception("User document not found after $maxAttempts attempts");
  }

  bool isUserLoggedIn() {
    return _auth.currentUser != null;
  }

  String mapFirebaseError(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
        return 'Invalid email or password.';
      case 'invalid-email':
        return 'Invalid email format.';
      case 'email-already-in-use':
        return 'Email already in use.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});

final authStateStreamProvider = StreamProvider<UserModel?>((ref) {
  final authNotifier = ref.watch(authProvider.notifier);
  return authNotifier._auth.authStateChanges().map(
        (User? user) => user != null ? UserModel.fromFirebaseUser(user) : null,
      );
});

final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authProvider);
  if (authState.userId == null) {
    print("Current user provider: No user ID, returning null");
    return Stream.value(null);
  }

  return Stream.fromFuture(Connectivity().checkConnectivity())
      .asyncExpand((connectivityResult) {
    bool isOnline = connectivityResult != ConnectivityResult.none;
    final hiveService = ref.read(hiveServiceProvider);
    final userBox = hiveService.userBox;

    if (isOnline) {
      return _fetchUserWithRetry(authState.userId!).map((snapshot) {
        if (snapshot.exists) {
          final userModel = UserModel.fromFirestore(snapshot);
          userBox.put(authState.userId!, userModel);
          print(
              "Current user provider: Fetched user from Firestore, UID: ${userModel.id}");
          return userModel;
        }
        print("Current user provider: User document not found in Firestore");
        return null;
      }).handleError((error) {
        print("Error fetching user from Firestore: $error");
        final userModel = userBox.get(authState.userId);
        print(
            "Current user provider: Falling back to Hive, user: ${userModel?.id}");
        return Stream.value(userModel);
      });
    } else {
      print("Current user provider: Offline, fetching user from Hive");
      final userModel = userBox.get(authState.userId);
      return Stream.value(userModel);
    }
  });
});

Stream<DocumentSnapshot> _fetchUserWithRetry(String userId) async* {
  const maxAttempts = 10;
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
      print(
          "User document not found, attempt $attempt/$maxAttempts, retrying...");
      await Future.delayed(delay);
    } catch (e) {
      print("Error fetching user document, attempt $attempt/$maxAttempts: $e");
      if (attempt == maxAttempts) {
        throw Exception(
            'Failed to load user data after $maxAttempts attempts: $e');
      }
      await Future.delayed(delay);
    }
  }
  throw TimeoutException('Failed to load user data in time');
}
