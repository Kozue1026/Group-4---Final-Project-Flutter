import 'package:cloud_firestore/cloud_firestore.dart';

class RegistrationModel {
  final String id;
  final String userId;
  final String eventId;
  final DateTime registeredAt;
  final String status; // active | cancelled

  const RegistrationModel({
    required this.id,
    required this.userId,
    required this.eventId,
    required this.registeredAt,
    required this.status,
  });

  factory RegistrationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    DateTime parseDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    return RegistrationModel(
      id: doc.id,
      userId: (data['userId'] ?? '') as String,
      eventId: (data['eventId'] ?? '') as String,
      registeredAt: parseDate(data['registeredAt']),
      status: (data['status'] ?? 'active') as String,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'eventId': eventId,
      'registeredAt': Timestamp.fromDate(registeredAt),
      'status': status,
    };
  }
}
