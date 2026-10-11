import 'package:cloud_firestore/cloud_firestore.dart';

/// Event categories required by spec.
class EventCategory {
  static const academic = 'academic';
  static const sports = 'sports';
  static const seminar = 'seminar';
  static const organization = 'organization';
  static const entertainment = 'entertainment';

  static const all = [
    academic,
    sports,
    seminar,
    organization,
    entertainment,
  ];

  static String label(String value) {
    switch (value) {
      case academic:
        return 'Academic';
      case sports:
        return 'Sports';
      case seminar:
        return 'Seminar';
      case organization:
        return 'Organization';
      case entertainment:
        return 'Entertainment';
      default:
        return value;
    }
  }
}

class EventModel {
  final String id;
  final String name;
  final String description;
  final String category;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final String locationName;
  final double latitude;
  final double longitude;
  final String imageUrl;
  final int capacity;
  final int registeredCount;

  const EventModel({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.startDateTime,
    required this.endDateTime,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.imageUrl,
    required this.capacity,
    required this.registeredCount,
  });

  bool get isFull => registeredCount >= capacity;
  bool get isPast => startDateTime.isBefore(DateTime.now());

  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    DateTime parseDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    return EventModel(
      id: doc.id,
      name: (data['name'] ?? '') as String,
      description: (data['description'] ?? '') as String,
      category: (data['category'] ?? EventCategory.academic) as String,
      startDateTime: parseDate(data['startDateTime'] ?? data['date']),
      endDateTime: parseDate(data['endDateTime'] ?? data['startDateTime'] ?? data['date']),
      locationName: (data['locationName'] ?? data['location'] ?? '') as String,
      latitude: ((data['latitude'] ?? 0) as num).toDouble(),
      longitude: ((data['longitude'] ?? 0) as num).toDouble(),
      imageUrl: (data['imageUrl'] ?? '') as String,
      capacity: ((data['capacity'] ?? 0) as num).toInt(),
      registeredCount: ((data['registeredCount'] ?? 0) as num).toInt(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'category': category,
      'startDateTime': Timestamp.fromDate(startDateTime),
      'endDateTime': Timestamp.fromDate(endDateTime),
      'locationName': locationName,
      'latitude': latitude,
      'longitude': longitude,
      'imageUrl': imageUrl,
      'capacity': capacity,
      'registeredCount': registeredCount,
    };
  }
}
