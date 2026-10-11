import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../demo/demo_config.dart';
import '../demo/demo_data.dart';
import '../demo/demo_store.dart';
import '../models/event.dart';
import '../services/registration_service.dart';
import '../widgets/event_card.dart';
import 'discover/event_details_screen.dart';

/// Requirement #8 (Event History — completed events).
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (kDemoMode) {
      final store = context.watch<DemoStore>();
      final now = DateTime.now();
      // Demo: show past registered events + all past events as completed.
      final List<EventModel> past = demoEvents()
          .where((e) =>
              !e.startDateTime.isAfter(now) &&
              (store.isRegistered(e.id) || true))
          .toList()
        ..sort((a, b) => b.startDateTime.compareTo(a.startDateTime));
      if (past.isEmpty) {
        return const Center(child: Text('No completed events yet.'));
      }
      return ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: past.length,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: EventCard(
            event: past[i],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EventDetailsScreen(eventId: past[i].id),
              ),
            ),
            trailing: const Chip(
              label: Text('Completed'),
              avatar: Icon(Icons.check_circle, size: 16),
            ),
          ),
        ),
      );
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Center(child: Text('Not signed in.'));
    return FutureBuilder(
      future: RegistrationService().myEventsWithDetails(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Failed to load.\n${snapshot.error}'));
        }
        final now = DateTime.now();
        final List<EventModel> past = (snapshot.data ?? [])
            .where((r) => !r.event.startDateTime.isAfter(now))
            .map((r) => r.event)
            .toList()
          ..sort((a, b) => b.startDateTime.compareTo(a.startDateTime));
        if (past.isEmpty) {
          return const Center(child: Text('No completed events yet.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: past.length,
          itemBuilder: (_, i) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: EventCard(
              event: past[i],
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EventDetailsScreen(eventId: past[i].id),
                ),
              ),
              trailing: const Chip(
                label: Text('Completed'),
                avatar: Icon(Icons.check_circle, size: 16),
              ),
            ),
          ),
        );
      },
    );
  }
}
