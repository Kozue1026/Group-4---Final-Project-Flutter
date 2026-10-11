import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import 'demo/demo_auth.dart';
import 'demo/demo_config.dart';
import 'demo/demo_store.dart';
import 'providers/auth_provider.dart';
import 'providers/events_filter_provider.dart';
import 'screens/auth_gate.dart';
import 'services/notification_service.dart';

/// Demo mode (kDemoMode=true): runs fully in Android Studio with zero
/// Firebase setup. Flip kDemoMode to false when google-services.json exists.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();
  if (!kDemoMode) {
    try {
      await Firebase.initializeApp();
    } catch (e) {
      debugPrint('Firebase init failed (run flutterfire configure): $e');
    }
  }
  try {
    await NotificationService.init();
  } catch (e) {
    debugPrint('Notification init failed: $e');
  }
  runApp(const EventHubApp());
}

class EventHubApp extends StatelessWidget {
  const EventHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DemoAuth()),
        ChangeNotifierProvider(create: (_) => DemoStore()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => EventsFilterProvider()),
      ],
      child: MaterialApp(
        title: 'EventHub',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const AuthGate(),
      ),
    );
  }
}
