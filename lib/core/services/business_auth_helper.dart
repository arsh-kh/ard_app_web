import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final businessAuthHelperProvider = Provider<BusinessAuthHelper>((ref) {
  return BusinessAuthHelper();
});

class BusinessAuthHelper {
  /// Initializes a secondary Firebase app so we don't log out the primary user
  Future<FirebaseAuth> _getSecondaryAuth() async {
    FirebaseApp? secondaryApp;
    try {
      secondaryApp = Firebase.app('BusinessAuthApp');
    } catch (e) {
      secondaryApp = await Firebase.initializeApp(
        name: 'BusinessAuthApp',
        options: Firebase.app().options,
      );
    }
    return FirebaseAuth.instanceFor(app: secondaryApp);
  }

  /// Creates a Firebase Auth account for a new business
  Future<String> createBusinessAccount(String email, String password) async {
    final auth = await _getSecondaryAuth();
    final userCredential = await auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    if (userCredential.user == null) {
      throw Exception('Failed to create business auth account');
    }
    final uid = userCredential.user!.uid;
    // Sign out to clean up the secondary app state
    await auth.signOut();
    return uid;
  }

  /// Verifies credentials by attempting to sign in
  Future<String> verifyBusinessCredentials(String email, String password) async {
    final auth = await _getSecondaryAuth();
    final userCredential = await auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    if (userCredential.user == null) {
      throw Exception('invalidCredentials');
    }
    final uid = userCredential.user!.uid;
    await auth.signOut();
    return uid;
  }

  /// Sends a native Firebase password reset email
  Future<void> sendResetEmail(String email) async {
    // We can use the primary auth instance for this, it doesn't affect auth state
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
  }

  /// Updates the business email by logging into the secondary app
  Future<void> updateBusinessEmail(String oldEmail, String password, String newEmail) async {
    final auth = await _getSecondaryAuth();
    final userCredential = await auth.signInWithEmailAndPassword(
      email: oldEmail.trim(),
      password: password,
    );
    if (userCredential.user == null) {
      throw Exception('invalidCredentials');
    }
    await userCredential.user!.verifyBeforeUpdateEmail(newEmail.trim());
    await auth.signOut();
  }

  /// Updates the business password by logging into the secondary app
  Future<void> updateBusinessPassword(String email, String oldPassword, String newPassword) async {
    final auth = await _getSecondaryAuth();
    final userCredential = await auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: oldPassword,
    );
    if (userCredential.user == null) {
      throw Exception('invalidCredentials');
    }
    await userCredential.user!.updatePassword(newPassword);
    await auth.signOut();
  }
}
