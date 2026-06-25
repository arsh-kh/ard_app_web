import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../main.dart'; // To access global sharedPrefs

class OnboardingNotifier extends Notifier<bool> {
  static const _key = 'has_seen_onboarding';

  @override
  bool build() {
    return sharedPrefs.getBool(_key) ?? false;
  }

  Future<void> completeOnboarding() async {
    await sharedPrefs.setBool(_key, true);
    state = true;
  }

  // Debug helper
  Future<void> resetOnboarding() async {
    await sharedPrefs.setBool(_key, false);
    state = false;
  }
}

final onboardingProvider = NotifierProvider<OnboardingNotifier, bool>(() {
  return OnboardingNotifier();
});
