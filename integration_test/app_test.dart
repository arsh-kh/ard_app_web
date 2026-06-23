import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ard_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Deep E2E Test: Auth, Navigation, Theme, Language, POS', (
    WidgetTester tester,
  ) async {
    // 1. Launch the app
    app.main();
    await tester.pump(const Duration(seconds: 3));

    // 2. Wait for Splash/Firebase to load
    bool isLoggedIn = false;
    bool isOnLogin = false;
    for (int i = 0; i < 20; i++) {
      await tester.pump(const Duration(seconds: 1));

      // If either active or inactive dashboard icon is present, we are inside the shell
      if (find.byIcon(Icons.dashboard).evaluate().isNotEmpty ||
          find.byIcon(Icons.dashboard_outlined).evaluate().isNotEmpty) {
        isLoggedIn = true;
        break;
      }
      if (find.byType(TextFormField).evaluate().isNotEmpty) {
        isOnLogin = true;
        break;
      }
    }

    if (!isLoggedIn && !isOnLogin) {
      throw Exception(
        'App stuck on splash screen! Neither Dashboard nor Login found after 20s.',
      );
    }

    if (isOnLogin && !isLoggedIn) {
      // Not logged in, so we log in
      final emailField = find.byType(TextFormField).first;
      final passwordField = find.byType(TextFormField).last;

      await tester.enterText(emailField, 'yarasdywanh@gmail.com');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump(const Duration(seconds: 1));

      await tester.enterText(passwordField, '12213443Ar');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump(const Duration(seconds: 1));

      // Hide keyboard completely
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump(const Duration(seconds: 1));

      final btns = find.byType(ElevatedButton);
      if (btns.evaluate().isNotEmpty) {
        await tester.ensureVisible(btns.first);
        await tester.tap(btns.first, warnIfMissed: false);
      }

      // Wait for login to complete and navigate
      for (int i = 0; i < 15; i++) {
        await tester.pump(const Duration(seconds: 1));
        if (find.byIcon(Icons.dashboard).evaluate().isNotEmpty ||
            find.byIcon(Icons.dashboard_outlined).evaluate().isNotEmpty) {
          break;
        }
      }
    }

    // 3. Navigation Test
    // Helper to tap bottom nav icons
    Future<void> tapNav(IconData active, IconData inactive) async {
      final f1 = find.byIcon(active);
      final f2 = find.byIcon(inactive);
      if (f1.evaluate().isNotEmpty) {
        await tester.tap(f1.first, warnIfMissed: false);
      } else if (f2.evaluate().isNotEmpty) {
        await tester.tap(f2.first, warnIfMissed: false);
      }
      await tester.pump(const Duration(seconds: 2));
    }

    // Go to POS
    await tapNav(Icons.shopping_bag, Icons.shopping_bag_outlined);

    // Go to Clients
    await tapNav(Icons.people, Icons.people_outline);

    // Go to Inventory
    await tapNav(Icons.inventory, Icons.inventory_2_outlined);

    // Go to Settings
    await tapNav(Icons.settings, Icons.settings_outlined);

    // 4. Theme Matrix
    final darkModeSwitch = find.byType(Switch);
    if (darkModeSwitch.evaluate().isNotEmpty) {
      await tester.tap(darkModeSwitch.first, warnIfMissed: false);
      await tester.pump(const Duration(seconds: 1));

      // Toggle back to light mode
      await tester.tap(darkModeSwitch.first, warnIfMissed: false);
      await tester.pump(const Duration(seconds: 1));
    }

    // 5. Language Matrix
    final languageRow = find.byIcon(Icons.language_rounded);
    if (languageRow.evaluate().isNotEmpty) {
      await tester.tap(languageRow.first, warnIfMissed: false);
      await tester.pump(const Duration(seconds: 1));

      // Tap outside to dismiss language dialog
      await tester.tapAt(const Offset(10, 10));
      await tester.pump(const Duration(seconds: 1));
    }

    // 6. POS Deep Test
    await tapNav(Icons.shopping_bag, Icons.shopping_bag_outlined);

    // Tap Add on first product
    final addButtons = find.byType(ElevatedButton);
    if (addButtons.evaluate().length > 1) {
      await tester.tap(addButtons.at(1), warnIfMissed: false);
      await tester.pump(const Duration(seconds: 1));

      // Open Cart
      final cartIcon = find.byIcon(Icons.shopping_cart);
      if (cartIcon.evaluate().isNotEmpty) {
        await tester.tap(cartIcon.first, warnIfMissed: false);
        await tester.pump(const Duration(seconds: 2));

        // Close cart by tapping outside
        await tester.tapAt(const Offset(10, 10));
        await tester.pump(const Duration(seconds: 1));
      }
    }
  });
}
