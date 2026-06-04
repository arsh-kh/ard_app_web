import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../data/local_database/database.dart';

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
  final AppDatabase _db;

  AuthNotifier(this._db) : super(const AuthState(isLoading: true)) {
    _restoreSession();
  }

  static const _keyUserId = 'logged_in_user_id';
  static const _salt = 'ard_bazar_2025_salt';

  /// Real SHA-256 hash with a static salt.
  String _hash(String input) {
    final bytes = utf8.encode('$_salt:$input');
    return sha256.convert(bytes).toString(); // hex string
  }

  Future<void> _restoreSession() async {
    // Hard 6-second timeout — ensures we NEVER stay stuck on the loading screen
    // even if the database migration or SharedPreferences hangs.
    await Future.any([
      _doRestoreSession(),
      Future.delayed(const Duration(seconds: 6)),
    ]);
    // If timeout fired and we're still loading, force to logged-out state
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
        final user = await (_db.select(_db.users)
              ..where((u) => u.id.equals(savedId))
              ..where((u) => u.isDeleted.equals(false)))
            .getSingleOrNull();
        if (user != null) {
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

  /// Returns null on success, or an error message string.
  Future<String?> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true);
    try {
      final hashed = _hash(password);
      final users = await (_db.select(_db.users)
            ..where((u) => u.email.equals(email.trim().toLowerCase()))
            ..where((u) => u.isDeleted.equals(false)))
          .get();

      // First try new passwordHash column
      UserEntity? match = users.where((u) => u.passwordHash == hashed).firstOrNull;

      // Fallback: legacy pw: prefix in phone column (for accounts that haven't been migrated yet)
      match ??= users.where((u) {
        final ph = u.phone ?? '';
        return ph.startsWith('pw:') && ph.substring(3) == _legacyHash(password);
      }).firstOrNull;

      if (match == null) {
        state = state.copyWith(isLoading: false);
        return 'Invalid email or password';
      }

      // Silently upgrade legacy hash to SHA-256 on next login
      if (match.passwordHash == null || match.passwordHash!.isEmpty) {
        await (_db.update(_db.users)..where((u) => u.id.equals(match!.id))).write(
          UsersCompanion(
            passwordHash: Value(hashed),
            phone: const Value(null),
          ),
        );
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyUserId, match.id);
      state = AuthState(userId: match.id, user: match);
      return null;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      return 'Something went wrong. Please try again.';
    }
  }

  /// Legacy hash used by old accounts before the crypto upgrade.
  String _legacyHash(String input) {
    final bytes = utf8.encode('ard_salt_$input');
    return base64Url.encode(bytes);
  }

  /// Returns null on success, or an error message string.
  Future<String?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final emailLower = email.trim().toLowerCase();

      // Check for duplicate email
      final existing = await (_db.select(_db.users)
            ..where((u) => u.email.equals(emailLower))
            ..where((u) => u.isDeleted.equals(false)))
          .get();
      if (existing.isNotEmpty) {
        state = state.copyWith(isLoading: false);
        return 'An account with this email already exists';
      }

      if (password.length < 6) {
        state = state.copyWith(isLoading: false);
        return 'Password must be at least 6 characters';
      }

      final id = const Uuid().v4();
      final hashed = _hash(password);

      await _db.into(_db.users).insert(UsersCompanion.insert(
        id: id,
        name: name.trim(),
        email: Value(emailLower),
        passwordHash: Value(hashed), // use new column — no phone hack
        role: 'admin',
      ));

      final user = await (_db.select(_db.users)..where((u) => u.id.equals(id))).getSingle();
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
      email: Value(email ?? current.email),
      phone: Value(phone ?? current.phone),
      role: role ?? current.role,
      imageUrl: Value(avatarPath ?? current.imageUrl),
    );
    
    await (_db.update(_db.users)..where((u) => u.id.equals(current.id))).write(updated);
    state = state.copyWith(user: updated);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(databaseProvider));
});
