import 'package:datn/features/auth/screens/root_dispatcher.dart';
import 'package:datn/core/services/translation_service.dart';
import 'package:datn/features/auth/services/user_seeder.dart';
import 'package:datn/core/services/data_seeder.dart';
import 'package:datn/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:datn/l10n/generated/app_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:datn/core/services/push_notification_service.dart';
import 'package:datn/core/theme/app_theme.dart';
import 'package:datn/core/providers/theme_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    debugPrint("DEBUG: Starting App Init");
    debugPrint("DEBUG: kIsWeb = $kIsWeb");

    // Load environment variables
    await dotenv.load(fileName: ".env");

    debugPrint("DEBUG: Initializing Supabase...");
    await Supabase.initialize(
      url: 'https://dklvrzwvayhtcjslsnzr.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRrbHZyend2YXlodGNqc2xzbnpyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ4NzAyNjUsImV4cCI6MjA5MDQ0NjI2NX0.cVSM2dpbqLyI80T0NFYH5o9RGoo6Ret70Rn1VntvVS8',
    );
    debugPrint("DEBUG: Supabase successfully initialized.");

    // Force logout on every app start for testing purposes
    await Supabase.instance.client.auth.signOut();
    debugPrint("DEBUG: Forced Supabase sign out on startup.");

    // Check if any apps are already initialized (e.g. from hot restart)
    if (Firebase.apps.isNotEmpty) {
      debugPrint("DEBUG: Firebase apps already exist: ${Firebase.apps.length}");
      var app = Firebase.app();
      debugPrint("DEBUG: Default app name: ${app.name}");
      debugPrint("DEBUG: Default app options: ${app.options.asMap}");
    } else {
      debugPrint("DEBUG: No Firebase apps found. Initializing...");
      try {
        debugPrint(
          "DEBUG: Using Config = ${DefaultFirebaseOptions.currentPlatform.asMap}",
        );
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        debugPrint("DEBUG: Firebase.initializeApp() completed.");
      } catch (initErr) {
        debugPrint("CRITICAL: Firebase.initializeApp() FAILED: $initErr");
        rethrow;
      }
    }

    debugPrint(
      "Firebase initialized successfully. Apps: ${Firebase.apps.length}",
    );

    // Double check the default app exists
    try {
      final defaultApp = Firebase.app();
      debugPrint("DEBUG: Verified Default App exists: ${defaultApp.name}");
    } catch (e) {
      debugPrint("CRITICAL: Firebase.app() failed after success log: $e");
      throw Exception("Firebase Initialized but [DEFAULT] app is missing.");
    }

    try {
      if (Firebase.apps.isNotEmpty) {
        debugPrint("DEBUG: Seeding users...");
        await UserSeeder().seedUsers();
        debugPrint("DEBUG: Seeding data...");
        await DataSeeder.seed();
        debugPrint("DEBUG: Seeding complete.");
      } else {
        debugPrint("CRITICAL: Firebase initialized but app list is empty!");
      }
    } catch (e) {
      debugPrint("Error seeding users/data: $e");
    }

    try {
      if (!kIsWeb) {
        debugPrint("DEBUG: Initializing Push Notification Service...");
        await PushNotificationService().initialize();
      }
    } catch (e) {
      debugPrint("Error init Push Notifications: $e");
    }

    runApp(const ProviderScope(child: MyApp()));
  } catch (e) {
    debugPrint("Firebase Initialization Error: $e");
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    "Startup Error",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Firebase failed to initialize.\n\nChanges are high you are running on Web without 'firebase_options.dart'.\n\nError: $e",
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "To fix this:\n1. Run `flutterfire configure` in your terminal.\n2. Select your project and ensure 'Web' is checked.\n3. Import `firebase_options.dart` in `main.dart` and pass `DefaultFirebaseOptions.currentPlatform` to `initializeApp`.",
                    textAlign: TextAlign.left,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return AnimatedBuilder(
      animation: TranslationService(),
      builder: (context, child) {
        return MaterialApp(
          title: 'Role Based App',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          locale: TranslationService().locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const RootDispatcher(),
        );
      },
    );
  }
}
