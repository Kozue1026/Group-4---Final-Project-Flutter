import 'package:flutter/material.dart';

import 'discover/event_list_screen.dart';
import 'history_screen.dart';
import 'my_events_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  static const _titles = ['Discover', 'My Events', 'History', 'Profile'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('EventHub — ${_titles[_index]}')),
      body: IndexedStack(
        index: _index,
        children: const [
          EventListScreen(),
          MyEventsScreen(),
          HistoryScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.explore), label: 'Discover'),
          NavigationDestination(
              icon: Icon(Icons.bookmark), label: 'My Events'),
          NavigationDestination(
              icon: Icon(Icons.history), label: 'History'),
          NavigationDestination(
              icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
