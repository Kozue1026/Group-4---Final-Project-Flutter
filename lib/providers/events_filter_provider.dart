import 'package:flutter/material.dart';

/// Category + search filter state for Discover tab.
class EventsFilterProvider extends ChangeNotifier {
  String _category = 'all';
  String _query = '';

  String get category => _category;
  String get query => _query;

  void setCategory(String value) {
    _category = value;
    notifyListeners();
  }

  void setQuery(String value) {
    _query = value.toLowerCase();
    notifyListeners();
  }
}
