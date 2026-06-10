import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/services/notification_service.dart';
import 'core/providers/locale_provider.dart';
import 'core/localization/kurdish_localizations.dart';
import 'l10n/app_localizations.dart';
import 'core/widgets/global_reveal_manager.dart';

import 'package:firebase_core/firebase_core.dart';

import 'core/providers/theme_provider.dart';
import 'firebase_options.dart';

// Removed Background Worker as app is now fully online via Firebase Firestore natively

class AppScrollBehavior extends ScrollBehavior {
  const AppScrollBehavior();
  
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize System Notifications
  final notificationService = NotificationService();
  await notificationService.init();
  await notificationService.requestPermissions();

  // Configure Edge-to-Edge System UI
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      statusBarColor: Colors.transparent,
    ),
  );
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Enable native offline persistence for Firebase
    // This is currently handled automatically by default, or removed if not using raw Firestore.
  } catch (e) {
    debugPrint('Firebase not configured: $e');
  }

  runApp(const ProviderScope(child: ArdApp()));
}

class ArdApp extends ConsumerStatefulWidget {
  const ArdApp({super.key});
  @override
  ConsumerState<ArdApp> createState() => _ArdAppState();
}

class _ArdAppState extends ConsumerState<ArdApp> {
  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final currentLocale = ref.watch(localeProvider);

    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'ئارد',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme, 
      darkTheme: AppTheme.darkTheme, 
      themeMode: themeMode,
      locale: currentLocale,
      localizationsDelegates: const [
        KurdishMaterialLocalizations.delegate,
        KurdishCupertinoLocalizations.delegate,
        KurdishWidgetsLocalizations.delegate,
        ...AppLocalizations.localizationsDelegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      scrollBehavior: const AppScrollBehavior(),
      routerConfig: router,
      builder: (context, child) {
        return RepaintBoundary(
          key: appBoundaryKey,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

