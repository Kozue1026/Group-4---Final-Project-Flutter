import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../demo/demo_config.dart';
import '../demo/demo_data.dart';
import '../demo/demo_store.dart';
import '../models/event.dart';
import '../services/notification_service.dart';
import '../services/registration_service.dart';
import '../widgets/event_card.dart';
import 'discover/event_details_screen.dart';

/// Requirement #6 (My Events) + #7 (Cancel Registration).
class MyEventsScreen extends StatelessWidget {
  const MyEventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (kDemoMode) return const _DemoMyEvents();
    return const _FirebaseMyEvents();
  }
}

class _DemoMyEvents extends StatelessWidget {
  const _DemoMyEvents();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<DemoStore>();
    final now = DateTime.now();
    final List<EventModel> upcoming = demoEvents()
        .where((e) =>
            store.isRegistered(e.id) && e.startDateTime.isAfter(now))
        .toList()
      ..sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
    if (upcoming.isEmpty) {
      return const Center(
          child: Text('No upcoming registrations.\nDiscover events to join!'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: upcoming.length,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: EventCard(
          event: upcoming[i],
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EventDetailsScreen(eventId: upcoming[i].id),
            ),
          ),
          trailing: FilledButton.tonal(
            onPressed: () async {
              context.read<DemoStore>().cancel(upcoming[i].id);
              await NotificationService.cancelEventReminders(
                  upcoming[i].id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Registration cancelled.')));
              }
            },
            child: const Text('Cancel registration'),
          ),
        ),
      ),
    );
  }
}

class _FirebaseMyEvents extends StatefulWidget {
  const _FirebaseMyEvents();

  @override
  State<_FirebaseMyEvents> createState() => _FirebaseMyEventsState();
}

class _FirebaseMyEventsState extends State<_FirebaseMyEvents> {
  final _service = RegistrationService();
  bool _busy = false;

  Future<void> _cancel(String eventId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel registration?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Cancel')),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _busy = true);
    try {
      await _service.cancel(uid, eventId);
      await NotificationService.cancelEventReminders(eventId);
      if (mounted) setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registration cancelled.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Center(child: Text('Not signed in.'));
    return FutureBuilder(
      future: _service.myEventsWithDetails(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Failed to load.\n${snapshot.error}'));
        }
        final now = DateTime.now();
        final List<EventModel> upcoming = (snapshot.data ?? [])
            .where((r) => r.event.startDateTime.isAfter(now))
            .map((r) => r.event)
            .toList()
          ..sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
        if (upcoming.isEmpty) {
          return const Center(
              child:
                  Text('No upcoming registrations.\nDiscover events to join!'));
        }
        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: upcoming.length,
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: EventCard(
                event: upcoming[i],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        EventDetailsScreen(eventId: upcoming[i].id),
                  ),
                ).then((_) => setState(() {})),
                trailing: FilledButton.tonal(
                  onPressed:
                      _busy ? null : () => _cancel(upcoming[i].id),
                  child: const Text('Cancel registration'),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
