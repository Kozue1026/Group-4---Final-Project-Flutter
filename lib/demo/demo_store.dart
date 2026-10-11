import 'package:flutter/material.dart';

/// In-memory registrations. No Firestore needed.
class DemoStore extends ChangeNotifier {
  final Set<String> _registeredIds = {};

  bool isRegistered(String eventId) => _registeredIds.contains(eventId);

  void register(String eventId) {
    _registeredIds.add(eventId);
    notifyListeners();
  }

  void cancel(String eventId) {
    _registeredIds.remove(eventId);
    notifyListeners();
  }

  Set<String> get registeredIds => Set.unmodifiable(_registeredIds);
}
