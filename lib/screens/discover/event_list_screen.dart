import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../demo/demo_config.dart';
import '../../demo/demo_data.dart';
import '../../models/event.dart';
import '../../providers/events_filter_provider.dart';
import '../../services/event_service.dart';
import '../../widgets/category_chips.dart';
import '../../widgets/event_card.dart';
import 'event_details_screen.dart';

/// Requirement #2 (Event List) + #3 (Categories).
/// Demo mode: local list. Firebase mode: Firestore stream.
class EventListScreen extends StatelessWidget {
  const EventListScreen({super.key});

  List<EventModel> _applyFilter(
      List<EventModel> events, String category, String query) {
    var out = events;
    if (category != 'all') {
      out = out.where((e) => e.category == category).toList();
    }
    if (query.isNotEmpty) {
      out = out
          .where((e) =>
              e.name.toLowerCase().contains(query) ||
              e.description.toLowerCase().contains(query))
          .toList();
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search events…',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (v) =>
                context.read<EventsFilterProvider>().setQuery(v),
          ),
        ),
        const CategoryChips(),
        Expanded(
          child: kDemoMode
              ? _DemoList(applyFilter: _applyFilter)
              : _FirebaseList(applyFilter: _applyFilter),
        ),
      ],
    );
  }
}

class _DemoList extends StatelessWidget {
  final List<EventModel> Function(List<EventModel>, String, String) applyFilter;
  const _DemoList({required this.applyFilter});

  @override
  Widget build(BuildContext context) {
    final filter = context.watch<EventsFilterProvider>();
    final now = DateTime.now();
    var events =
        demoEvents().where((e) => !e.startDateTime.isBefore(now)).toList()
          ..sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
    events = applyFilter(events, filter.category, filter.query);
    if (events.isEmpty) {
      return const Center(
          child: Text('No events found.\nTry another category.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: events.length,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: EventCard(
          event: events[i],
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EventDetailsScreen(eventId: events[i].id),
            ),
          ),
        ),
      ),
    );
  }
}

class _FirebaseList extends StatelessWidget {
  final List<EventModel> Function(List<EventModel>, String, String) applyFilter;
  const _FirebaseList({required this.applyFilter});

  @override
  Widget build(BuildContext context) {
    final service = EventService();
    return StreamBuilder(
      stream: service.upcomingEventsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
              child: Text(
                  'Failed to load events.\n${snapshot.error}\n\nAdd events in Firestore console.'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        var events =
            snapshot.data!.docs.map(EventModel.fromFirestore).toList();
        final filter = context.watch<EventsFilterProvider>();
        events = applyFilter(events, filter.category, filter.query);
        if (events.isEmpty) {
          return const Center(
              child: Text('No events found.\nTry another category.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: events.length,
          itemBuilder: (_, i) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: EventCard(
              event: events[i],
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EventDetailsScreen(eventId: events[i].id),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
