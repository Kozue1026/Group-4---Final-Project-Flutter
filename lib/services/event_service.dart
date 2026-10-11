import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/event.dart';

/// Direct Firestore access for `events` collection.
class EventService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  /// Upcoming events stream, ordered by start time.
  Stream<QuerySnapshot<Map<String, dynamic>>> upcomingEventsStream() {
    return _db
        .collection('events')
        .where('startDateTime',
            isGreaterThanOrEqualTo: Timestamp.now())
        .orderBy('startDateTime')
        .snapshots();
  }

  /// All events stream (used for History which needs past events too).
  Stream<QuerySnapshot<Map<String, dynamic>>> allEventsStream() {
    return _db.collection('events').orderBy('startDateTime').snapshots();
  }

  Future<EventModel?> getEvent(String eventId) async {
    final doc = await _db.collection('events').doc(eventId).get();
    if (!doc.exists) return null;
    return EventModel.fromFirestore(doc);
  }

  Future<List<EventModel>> getEventsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    // Firestore whereIn limited to 10 — chunk it.
    final List<EventModel> out = [];
    for (var i = 0; i < ids.length; i += 10) {
      final chunk = ids.sublist(
          i, i + 10 > ids.length ? ids.length : i + 10);
      final snap = await _db
          .collection('events')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      out.addAll(snap.docs.map(EventModel.fromFirestore));
    }
    return out;
  }
}
