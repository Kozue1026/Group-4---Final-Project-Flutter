import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/event.dart';
import '../models/registration.dart';

class RegistrationException implements Exception {
  final String message;
  RegistrationException(this.message);
  @override
  String toString() => message;
}

/// Direct Firestore access for `registrations` collection.
/// Schema: { userId, eventId, registeredAt, status: active|cancelled }
class RegistrationService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _regs =>
      _db.collection('registrations');

  Stream<QuerySnapshot<Map<String, dynamic>>> activeRegistrationsStream(
      String uid) {
    return _regs
        .where('userId', isEqualTo: uid)
        .where('status', isEqualTo: 'active')
        .orderBy('registeredAt', descending: true)
        .snapshots();
  }

  Future<bool> isRegistered(String uid, String eventId) async {
    final q = await _regs
        .where('userId', isEqualTo: uid)
        .where('eventId', isEqualTo: eventId)
        .where('status', isEqualTo: 'active')
        .limit(1)
        .get();
    return q.docs.isNotEmpty;
  }

  /// Register with capacity guard. Throws [RegistrationException] on failure.
  Future<void> register(String uid, EventModel event) async {
    // Pre-check duplicate (outside transaction; transaction enforces count).
    final existing = await _regs
        .where('userId', isEqualTo: uid)
        .where('eventId', isEqualTo: event.id)
        .where('status', isEqualTo: 'active')
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) {
      throw RegistrationException('You are already registered.');
    }

    final eventRef = _db.collection('events').doc(event.id);
    final regRef = _regs.doc();

    await _db.runTransaction((tx) async {
      final eventSnap = await tx.get(eventRef);
      if (!eventSnap.exists) {
        throw RegistrationException('Event no longer exists.');
      }
      final data = eventSnap.data() ?? {};
      final count = ((data['registeredCount'] ?? 0) as num).toInt();
      final capacity = ((data['capacity'] ?? 0) as num).toInt();
      if (capacity > 0 && count >= capacity) {
        throw RegistrationException('Event is full.');
      }
      tx.set(regRef, {
        'userId': uid,
        'eventId': event.id,
        'registeredAt': FieldValue.serverTimestamp(),
        'status': 'active',
      });
      tx.update(eventRef, {'registeredCount': FieldValue.increment(1)});
    });
  }

  /// Cancel: mark cancelled (keeps audit trail) + decrement count.
  Future<void> cancel(String uid, String eventId) async {
    final q = await _regs
        .where('userId', isEqualTo: uid)
        .where('eventId', isEqualTo: eventId)
        .where('status', isEqualTo: 'active')
        .limit(1)
        .get();
    if (q.docs.isEmpty) {
      throw RegistrationException('Registration not found.');
    }
    final regRef = q.docs.first.reference;
    final eventRef = _db.collection('events').doc(eventId);
    await _db.runTransaction((tx) async {
      tx.update(regRef, {'status': 'cancelled'});
      tx.update(eventRef, {'registeredCount': FieldValue.increment(-1)});
    });
  }

  /// Join registrations with their events for My Events / History.
  Future<List<({RegistrationModel reg, EventModel event})>> myEventsWithDetails(
      String uid) async {
    final q = await _regs
        .where('userId', isEqualTo: uid)
        .where('status', isEqualTo: 'active')
        .orderBy('registeredAt', descending: true)
        .get();
    final regs = q.docs.map(RegistrationModel.fromFirestore).toList();
    if (regs.isEmpty) return [];
    final ids = regs.map((r) => r.eventId).toSet().toList();
    final Map<String, EventModel> byId = {};
    for (var i = 0; i < ids.length; i += 10) {
      final chunk =
          ids.sublist(i, i + 10 > ids.length ? ids.length : i + 10);
      final snap = await _db
          .collection('events')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final d in snap.docs) {
        byId[d.id] = EventModel.fromFirestore(d);
      }
    }
    final List<({RegistrationModel reg, EventModel event})> out = [];
    for (final r in regs) {
      final e = byId[r.eventId];
      if (e != null) out.add((reg: r, event: e));
    }
    return out;
  }
}
