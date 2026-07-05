import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/locale_provider.dart';
import 'core/localization/kurdish_localizations.dart';
import 'l10n/app_localizations.dart';
import 'core/widgets/global_reveal_manager.dart';
import 'core/widgets/connectivity_banner.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'core/providers/theme_provider.dart';
import 'core/services/database_sanitization_service.dart';
import 'firebase_options.dart';

late final SharedPreferences sharedPrefs;

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
  sharedPrefs = await SharedPreferences.getInstance();

  // Configure Edge-to-Edge System UI
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      statusBarColor: Colors.transparent,
    ),
  );
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await DatabaseSanitizationService.run();
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  } catch (e) {
    debugPrint('Firebase not configured: $e');
  }

  // Global Error Handlers for Production
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.exception}');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Async Error: $error\n$stack');
    return true;
  };

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
      themeAnimationDuration: Duration.zero,
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
        return ConnectivityBanner(
          child: RepaintBoundary(
            key: appBoundaryKey,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}
