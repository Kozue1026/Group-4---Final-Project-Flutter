import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../demo/demo_auth.dart';
import '../demo/demo_config.dart';
import '../providers/auth_provider.dart' as app;
import 'auth/login_screen.dart';
import 'home_screen.dart';

/// Demo (kDemoMode=true): routes on DemoAuth — runs with zero Firebase setup.
/// Firebase path preserved for later when kDemoMode=false.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    if (kDemoMode) {
      final demo = context.watch<DemoAuth>();
      if (demo.isSignedIn) return const HomeScreen();
      return const LoginScreen();
    }
    final auth = context.watch<app.AuthProvider>();
    Stream<User?>? stream;
    try {
      stream = auth.authState;
    } catch (_) {
      return const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'EventHub\n\nFirebase not configured yet.\nRun "flutterfire configure" to add google-services.json.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    return StreamBuilder<User?>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) return const HomeScreen();
        return const LoginScreen();
      },
    );
  }
}
