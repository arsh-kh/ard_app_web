import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminProfile {
  final String name;
  final String email;
  final String role;
  final String? avatarPath;

  AdminProfile({
    required this.name,
    required this.email,
    required this.role,
    this.avatarPath,
  });

  AdminProfile copyWith({
    String? name,
    String? email,
    String? role,
    String? avatarPath,
  }) {
    return AdminProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      avatarPath: avatarPath ?? this.avatarPath,
    );
  }
}

class AdminProfileNotifier extends StateNotifier<AdminProfile> {
  AdminProfileNotifier()
      : super(AdminProfile(
          name: 'Admin',
          email: 'admin@ardapp.com',
          role: 'Administrator',
        )) {
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('admin_name') ?? 'Admin';
    final email = prefs.getString('admin_email') ?? 'admin@ardapp.com';
    final role = prefs.getString('admin_role') ?? 'Administrator';
    final avatarPath = prefs.getString('admin_avatar_path');

    state = AdminProfile(
      name: name,
      email: email,
      role: role,
      avatarPath: avatarPath,
    );
  }

  Future<void> updateProfile({
    String? name,
    String? email,
    String? role,
    String? avatarPath,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (name != null) await prefs.setString('admin_name', name);
    if (email != null) await prefs.setString('admin_email', email);
    if (role != null) await prefs.setString('admin_role', role);
    if (avatarPath != null) await prefs.setString('admin_avatar_path', avatarPath);

    state = state.copyWith(
      name: name,
      email: email,
      role: role,
      avatarPath: avatarPath,
    );
  }
}

final adminProfileProvider = StateNotifierProvider<AdminProfileNotifier, AdminProfile>((ref) {
  return AdminProfileNotifier();
});

