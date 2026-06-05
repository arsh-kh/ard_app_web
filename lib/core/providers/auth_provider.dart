import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/user_entity.dart';

class AuthState {
  final String? userId;
  final UserEntity? user;
  final bool isLoading;

  const AuthState({this.userId, this.user, this.isLoading = false});

  bool get isLoggedIn => userId != null && user != null;

  AuthState copyWith({String? userId, UserEntity? user, bool? isLoading}) {
    return AuthState(
      userId: userId ?? this.userId,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthNotifier() : super(const AuthState(isLoading: true)) {
    _initAndRestore();
  }

  Future<void> _initAndRestore() async {
    // Enforce a minimum delay to allow the beautiful splash screen animation to complete its filling steps
    await Future.wait([
      _restoreSession(),
      Future.delayed(const Duration(milliseconds: 2500)),
    ]);
    
    if (state.isLoading) {
      state = state.copyWith(isLoading: false);
    }
  }

  static const _keyUserId = 'logged_in_user_id';
  static const _salt = 'ard_bazar_2025_salt';

  String _hash(String input) {
    final bytes = utf8.encode('$_salt:$input');
    return sha256.convert(bytes).toString(); // hex string
  }

  Future<void> _restoreSession() async {
    await Future.any([
      _doRestoreSession(),
      Future.delayed(const Duration(seconds: 6)),
    ]);
    if (state.isLoading) {
      debugPrint('[Auth] _restoreSession timed out — forcing logout state');
      state = const AuthState();
    }
  }

  Future<void> _doRestoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString(_keyUserId);
      if (savedId != null) {
        final doc = await _firestore.collection('users').doc(savedId).get();
        if (doc.exists) {
          final user = UserEntity.fromJson({'id': doc.id, ...doc.data()!});
          state = AuthState(userId: savedId, user: user);
          return;
        }
      }
      state = const AuthState();
    } catch (e) {
      debugPrint('[Auth] _restoreSession failed: $e');
      state = const AuthState();
    }
  }

  Future<String?> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true);
    try {
      final hashed = _hash(password);
      final snapshot = await _firestore.collection('users')
          .where('email', isEqualTo: email.trim().toLowerCase())
          .get();

      if (snapshot.docs.isEmpty) {
        state = state.copyWith(isLoading: false);
        return 'Invalid email or password';
      }

      final doc = snapshot.docs.first;
      final user = UserEntity.fromJson({'id': doc.id, ...doc.data()});

      if (user.passwordHash != hashed) {
        state = state.copyWith(isLoading: false);
        return 'Invalid email or password';
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyUserId, user.id);
      state = AuthState(userId: user.id, user: user);
      return null;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      return 'Something went wrong. Please try again.';
    }
  }

  Future<String?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final emailLower = email.trim().toLowerCase();

      final existing = await _firestore.collection('users')
          .where('email', isEqualTo: emailLower)
          .get();
          
      if (existing.docs.isNotEmpty) {
        state = state.copyWith(isLoading: false);
        return 'An account with this email already exists';
      }

      if (password.length < 6) {
        state = state.copyWith(isLoading: false);
        return 'Password must be at least 6 characters';
      }

      final id = const Uuid().v4();
      final hashed = _hash(password);

      final user = UserEntity(
        id: id,
        name: name.trim(),
        email: emailLower,
        passwordHash: hashed,
        role: 'admin',
        createdAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(id).set(user.toJson());

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyUserId, id);
      state = AuthState(userId: id, user: user);
      return null;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      return 'Registration failed. Please try again.';
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
    state = const AuthState();
  }

  Future<void> updateProfile({
    String? name,
    String? email,
    String? phone,
    String? role,
    String? avatarPath,
  }) async {
    final current = state.user;
    if (current == null) return;
    
    final updated = current.copyWith(
      name: name ?? current.name,
      email: email ?? current.email,
      phone: phone ?? current.phone,
      role: role ?? current.role,
      imageUrl: avatarPath ?? current.imageUrl,
    );
    
    await _firestore.collection('users').doc(current.id).update(updated.toJson());
    state = state.copyWith(user: updated);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
