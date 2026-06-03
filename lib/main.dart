import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/routing/app_router.dart';
import 'core/constants/app_theme.dart'; // Switched to Cairo-based themes
import 'core/services/notification_service.dart';
import 'core/providers/locale_provider.dart';
import 'core/localization/kurdish_localizations.dart';
import 'l10n/app_localizations.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:workmanager/workmanager.dart';
import 'core/providers/theme_provider.dart';
import 'sync/sync_engine.dart';
import 'data/local_database/database.dart';
import 'core/constants/app_constants.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final db = AppDatabase();
    try {
      if (task == 'syncDataTask') {
        final syncEngine = SyncEngine(db);
        final syncedCount = await syncEngine.triggerSync();

        if (syncedCount > 0) {
          final notificationService = NotificationService();
          await notificationService.init();
          await notificationService.showNotification(
            id: 100,
            title: '${AppConstants.appName} - Sync Completed',
            body:
                '$syncedCount local records have been synchronized to the cloud.',
          );
        }
      }
    } catch (err) {
      debugPrint('Background sync task failed: $err');
      return Future.value(false);
    } finally {
      // Guaranteed to run, preventing background database leaks
      await db.close();
    }
    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize System Notifications
  final notificationService = NotificationService();
  await notificationService.init();
  await notificationService.requestPermissions();

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase not configured: $e');
  }

  // Initialize Background Worker
  Workmanager().initialize(callbackDispatcher);

  // Register a periodic task to sync data every 15 minutes (minimum allowed by Android)
  Workmanager().registerPeriodicTask(
    "1",
    "syncDataTask",
    frequency: const Duration(minutes: 15),
    constraints: Constraints(
      networkType: NetworkType.connected, // Only run if internet is available
    ),
  );

  runApp(const ProviderScope(child: ArdApp()));
}

class ArdApp extends ConsumerStatefulWidget {
  const ArdApp({super.key});
  @override
  ConsumerState<ArdApp> createState() => _ArdAppState();
}

class _ArdAppState extends ConsumerState<ArdApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(syncEngineProvider).startMonitoring();
      ref.read(syncEngineProvider).triggerSync();
    });
  }

  @override
  void dispose() {
    ref.read(syncEngineProvider).stopMonitoring();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final currentLocale = ref.watch(localeProvider);

    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'ئارد',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(), 
      darkTheme: buildDarkTheme(), 
      themeMode: themeMode,
      locale: currentLocale,
      localizationsDelegates: const [
        KurdishMaterialLocalizations.delegate,
        KurdishCupertinoLocalizations.delegate,
        KurdishWidgetsLocalizations.delegate,
        ...AppLocalizations.localizationsDelegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }
}
