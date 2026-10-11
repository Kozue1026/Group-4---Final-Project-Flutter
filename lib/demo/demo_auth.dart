import 'package:flutter/material.dart';

/// One-tap fake auth for Android Studio runs. No Firebase needed.
class DemoUser {
  final String uid;
  final String email;
  const DemoUser({required this.uid, required this.email});
}

class DemoAuth extends ChangeNotifier {
  DemoUser? _user;

  DemoUser? get user => _user;
  bool get isSignedIn => _user != null;

  /// Option A: instant login as demo student.
  Future<void> oneTapLogin() async {
    await Future.delayed(const Duration(milliseconds: 400));
    _user = const DemoUser(uid: 'demo-student-1', email: 'student@demo.school');
    notifyListeners();
  }

  /// Keep email/Google buttons working against fake backend.
  Future<void> signInFake() => oneTapLogin();

  Future<void> signOut() async {
    _user = null;
    notifyListeners();
  }
}
