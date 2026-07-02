import 'dart:async';
import '../error/app_exception.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/database_seeder.dart';
import '../../data/models/user_entity.dart';

class AuthState {
  final String? userId;
  final UserEntity? user;
  final bool isLoading;
  final bool isInitializing;

  const AuthState({
    this.userId,
    this.user,
    this.isLoading = false,
    this.isInitializing = false,
  });

  bool get isLoggedIn => userId != null && user != null;

  AuthState copyWith({
    String? userId,
    UserEntity? user,
    bool? isLoading,
    bool? isInitializing,
  }) {
    return AuthState(
      userId: userId ?? this.userId,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      isInitializing: isInitializing ?? this.isInitializing,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  StreamSubscription<DocumentSnapshot>? _userDocSub;
  bool _isAuthInProgress = false;

  AuthNotifier() : super(const AuthState(isInitializing: true)) {
    _initAndRestore();
  }

  @override
  void dispose() {
    _userDocSub?.cancel();
    super.dispose();
  }

  Future<void> _initAndRestore() async {
    // Allow minimal time for UI tree to mount before reading auth state
    await Future.delayed(const Duration(milliseconds: 50));

    // Setup listener for auth state changes to auto-restore
    _firebaseAuth.authStateChanges().listen((User? firebaseUser) async {
      if (firebaseUser != null) {
        // Enforce a strict timeout on the network call to prevent hanging
        try {
          // IMPORTANT: Re-fetch user to get latest emailVerified status
          await firebaseUser.reload();

          if (!firebaseUser.emailVerified) {
            if (_isAuthInProgress) return; // Wait for auth flow to complete
            // User hasn't verified email, treat as logged out internally
            await _firebaseAuth.signOut();
            state = const AuthState(isInitializing: false);
            return;
          }

          await _userDocSub?.cancel();
          _userDocSub = _firestore
              .collection('users')
              .doc(firebaseUser.uid)
              .snapshots()
              .listen(
                (doc) {
                  if (doc.exists && doc.data() != null) {
                    final user = UserEntity.fromJson({
                      'id': doc.id,
                      ...doc.data()!,
                    });
                    state = AuthState(
                      userId: firebaseUser.uid,
                      user: user,
                      isInitializing: false,
                    );
                  } else {
                    state = const AuthState(isInitializing: false);
                  }
                },
                onError: (e) {
                  debugPrint('[Auth] Firestore stream error: $e');
                  state = const AuthState(isInitializing: false);
                },
              );
        } catch (e) {
          debugPrint('[Auth] Restore error: $e');
          state = const AuthState(isInitializing: false);
        }
      } else {
        await _userDocSub?.cancel();
        state = const AuthState(isInitializing: false);
      }
    });

    // Fallback if the listener doesn't trigger quickly
    await Future.delayed(const Duration(milliseconds: 250));
    if (state.isInitializing && _firebaseAuth.currentUser == null) {
      state = state.copyWith(isInitializing: false);
    }
  }

  Future<void> refreshSession() async {
    state = state.copyWith(isLoading: true);
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser != null) {
      try {
        await firebaseUser.reload();
        if (!firebaseUser.emailVerified) {
          await _firebaseAuth.signOut();
          state = const AuthState(isLoading: false);
          return;
        }
        final doc = await _firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .get();
        if (doc.exists) {
          final user = UserEntity.fromJson({'id': doc.id, ...doc.data()!});
          state = AuthState(
            userId: firebaseUser.uid,
            user: user,
            isLoading: false,
          );
        } else {
          state = const AuthState(isLoading: false);
        }
      } catch (e) {
        state = const AuthState(isLoading: false);
      }
    } else {
      state = const AuthState(isLoading: false);
    }
  }

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true);
    _isAuthInProgress = true;
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        state = state.copyWith(isLoading: false);
        return 'err_invalid_login_response';
      }

      if (!firebaseUser.emailVerified) {
        // Send it again just in case they lost the first one
        await firebaseUser.sendEmailVerification();
        await _firebaseAuth.signOut();
        state = state.copyWith(isLoading: false);
        return 'err_verify_email';
      }

      final doc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      UserEntity user;

      if (!doc.exists) {
        // Heal the database: The user authenticated successfully but their profile
        // was interrupted during creation. Recreate it securely.
        user = UserEntity(
          id: firebaseUser.uid,
          businessId: '',
          name: firebaseUser.displayName ?? email.split('@').first,
          email: firebaseUser.email ?? email.trim().toLowerCase(),
          passwordHash: '',
          role: 'user',
          status: 'pending',
          createdAt: DateTime.now(),
        );

        await _firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .set(user.toJson());
      } else {
        user = UserEntity.fromJson({'id': doc.id, ...doc.data()!});
      }

      state = AuthState(userId: firebaseUser.uid, user: user, isLoading: false);
      return null;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(isLoading: false);
      return AppException.fromFirebase(e).message;
    } on FirebaseException catch (e) {
      state = state.copyWith(isLoading: false);
      debugPrint(
        '[Auth] FirebaseException during login: ${e.code} - ${e.message}',
      );
      return e.message ?? 'err_something_went_wrong';
    } catch (e) {
      state = state.copyWith(isLoading: false);
      debugPrint('[Auth] Unknown exception during login: $e');
      return 'err_something_went_wrong';
    } finally {
      _isAuthInProgress = false;
    }
  }

  Future<String?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true);
    _isAuthInProgress = true;
    try {
      final emailLower = email.trim().toLowerCase();

      if (password.length < 6) {
        state = state.copyWith(isLoading: false);
        return 'err_password_too_short';
      }

      // Create Firebase Auth User
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: emailLower,
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        state = state.copyWith(isLoading: false);
        return 'err_registration_failed';
      }

      // Send verification email
      firebaseUser.sendEmailVerification().ignore();

      // Store in Firestore
      final user = UserEntity(
        id: firebaseUser.uid,
        businessId: '', // Empty until they create or join a business
        name: name.trim(),
        email: emailLower,
        passwordHash: '', // No longer need to manually hash/store password
        role: 'user',
        status: 'pending',
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .set(user.toJson());

      // Sign out immediately because they need to verify their email
      await _firebaseAuth.signOut();

      state = state.copyWith(isLoading: false);
      return null; // Return null on success
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'Registration FirebaseAuthException: ${e.code} - ${e.message}',
      );
      state = state.copyWith(isLoading: false);
      if (e.code == 'email-already-in-use') {
        return 'err_email_in_use';
      }
      return 'err_registration_failed';
    } catch (e) {
      debugPrint('Registration generic error: $e');
      state = state.copyWith(isLoading: false);
      return 'err_registration_failed';
    } finally {
      _isAuthInProgress = false;
    }
  }

  Future<String?> forgotPassword(String email) async {
    state = state.copyWith(isLoading: true);
    try {
      await _firebaseAuth.sendPasswordResetEmail(
        email: email.trim().toLowerCase(),
      );
      state = state.copyWith(isLoading: false);
      return null;
    } on FirebaseAuthException {
      state = state.copyWith(isLoading: false);
      return 'err_send_reset_failed';
    } catch (e) {
      state = state.copyWith(isLoading: false);
      return 'err_unexpected';
    }
  }

  Future<String?> updatePassword(String newPassword) async {
    state = state.copyWith(isLoading: true);
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        state = state.copyWith(isLoading: false);
        return 'err_not_logged_in';
      }
      
      await user.updatePassword(newPassword);
      state = state.copyWith(isLoading: false);
      return null;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(isLoading: false);
      if (e.code == 'requires-recent-login') {
        return 'requiresRecentLogin';
      }
      return 'passwordChangeError';
    } catch (e) {
      state = state.copyWith(isLoading: false);
      return 'passwordChangeError';
    }
  }

  void updateUser(UserEntity user) {
    state = state.copyWith(user: user);
  }

  Future<void> logout() async {
    await _userDocSub?.cancel();
    await _firebaseAuth.signOut();
    state = const AuthState();
  }

  Future<void> updateProfile({
    String? name,
    String? email,
    String? phone,
    String? avatarPath,
    bool removeAvatar = false,
  }) async {
    final current = state.user;
    if (current == null) return;

    final updated = current.copyWith(
      name: name ?? current.name,
      email: email ?? current.email,
      phone: phone ?? current.phone,
      imageUrl: removeAvatar ? null : (avatarPath ?? current.imageUrl),
    );

    final Map<String, dynamic> data = updated.toJson();
    if (updated.imageUrl == null) {
      data['imageUrl'] = FieldValue.delete();
    }

    await _firestore.collection('users').doc(current.id).update(data);
    state = state.copyWith(user: updated);
  }

  Future<void> seedDemoData() async {
    final businessId = state.user?.businessId;
    if (businessId == null || businessId.isEmpty) {
      throw Exception('noBusinessAttached');
    }
    await DatabaseSeeder.seedRealisticData(businessId);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
