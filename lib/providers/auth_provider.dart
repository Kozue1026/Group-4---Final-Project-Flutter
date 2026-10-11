import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _service = AuthService();
  bool _busy = false;
  String? _error;

  bool get busy => _busy;
  String? get error => _error;
  Stream<User?> get authState => _service.authStateChanges();
  User? get user => _service.currentUser;

  void _set(bool busy, [String? error]) {
    _busy = busy;
    _error = error;
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) async {
    _set(true);
    try {
      await _service.signInWithEmail(email.trim(), password);
      _set(false);
      return true;
    } catch (e) {
      _set(false, AuthService.friendlyError(e));
      return false;
    }
  }

  Future<bool> register(String email, String password) async {
    _set(true);
    try {
      await _service.registerWithEmail(email.trim(), password);
      _set(false);
      return true;
    } catch (e) {
      _set(false, AuthService.friendlyError(e));
      return false;
    }
  }

  Future<bool> signInGoogle() async {
    _set(true);
    try {
      await _service.signInWithGoogle();
      _set(false);
      return true;
    } catch (e) {
      _set(false, AuthService.friendlyError(e));
      return false;
    }
  }

  Future<void> signOut() => _service.signOut();
}
