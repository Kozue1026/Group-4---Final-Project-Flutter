import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../demo/demo_config.dart';
import '../../demo/demo_data.dart';
import '../../demo/demo_store.dart';
import '../../models/event.dart';
import '../../services/event_service.dart';
import '../../services/location_service.dart';
import '../../services/notification_service.dart';
import '../../services/registration_service.dart';
import '../../utils/date_format.dart';

/// Requirement #4 (Details) + #5 (Registration) + device features.
/// Demo mode: local lookup + DemoStore. Firebase mode: Firestore.
class EventDetailsScreen extends StatefulWidget {
  final String eventId;
  const EventDetailsScreen({super.key, required this.eventId});

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  final _eventService = EventService();
  final _regService = RegistrationService();
  bool _busy = false;
  bool? _registered;
  double? _distanceKm;
  EventModel? _event;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    NotificationService.requestPermissions();
  }

  Future<void> _load() async {
    if (kDemoMode) {
      final found = demoEvents().where((e) => e.id == widget.eventId);
      _event = found.isEmpty ? null : found.first;
      if (_event != null) {
        _registered =
            context.read<DemoStore>().isRegistered(_event!.id);
        _loadDistance(_event!);
      }
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      _event = await _eventService.getEvent(widget.eventId);
      if (_event != null) {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          _registered = await _regService.isRegistered(uid, widget.eventId);
        }
        _loadDistance(_event!);
      }
    } catch (_) {
      _event = null;
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadDistance(EventModel event) async {
    if (event.latitude == 0 && event.longitude == 0) return;
    try {
      final km = await LocationService.distanceKmTo(
          event.latitude, event.longitude);
      if (mounted) setState(() => _distanceKm = km);
    } catch (_) {}
  }

  Future<void> _register(EventModel event) async {
    if (kDemoMode) {
      setState(() => _busy = true);
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      context.read<DemoStore>().register(event.id);
      await NotificationService.scheduleEventReminders(event);
      setState(() {
        _busy = false;
        _registered = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Registered! Reminders set for 24h + 1h before.')));
      }
      return;
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() => _busy = true);
    try {
      await _regService.register(uid, event);
      await NotificationService.scheduleEventReminders(event);
      final r = await _regService.isRegistered(uid, widget.eventId);
      if (mounted) setState(() => _registered = r);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Registered! Reminders set for 24h + 1h before.')));
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

  Future<void> _cancel(EventModel event) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel registration?'),
        content: Text('Remove your spot for "${event.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Cancel registration')),
        ],
      ),
    );
    if (confirm != true) return;
    if (kDemoMode) {
      if (!mounted) return;
      context.read<DemoStore>().cancel(event.id);
      await NotificationService.cancelEventReminders(event.id);
      setState(() => _registered = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registration cancelled.')));
      }
      return;
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() => _busy = true);
    try {
      await _regService.cancel(uid, event.id);
      await NotificationService.cancelEventReminders(event.id);
      final r = await _regService.isRegistered(uid, widget.eventId);
      if (mounted) setState(() => _registered = r);
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
    // Re-sync demo registration state when store changes (e.g. back nav).
    if (kDemoMode && _event != null) {
      final isReg =
          context.watch<DemoStore>().isRegistered(_event!.id);
      if (_registered != isReg) _registered = isReg;
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Event details')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _event == null
              ? const Center(child: Text('Event not found.'))
              : _body(_event!),
    );
  }

  Widget _body(EventModel event) {
    final spotsLeft = event.capacity - event.registeredCount;
    // In demo, reflect local registration in the count display.
    final extra = (kDemoMode && (_registered == true)) ? 1 : 0;
    final shownCount = event.registeredCount + extra;
    return ListView(
      children: [
        if (event.imageUrl.isNotEmpty)
          CachedNetworkImage(
            imageUrl: event.imageUrl,
            height: 220,
            width: double.infinity,
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) =>
                const Icon(Icons.image_not_supported, size: 64),
          ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(event.name,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Chip(label: Text(EventCategoryLabel.of(event.category))),
              const SizedBox(height: 8),
              _row(Icons.calendar_today,
                  DateFormatUtil.date(event.startDateTime)),
              _row(Icons.access_time,
                  '${DateFormatUtil.time(event.startDateTime)} – ${DateFormatUtil.time(event.endDateTime)}'),
              _row(Icons.place, event.locationName),
              if (_distanceKm != null)
                _row(Icons.directions_walk,
                    '${_distanceKm!.toStringAsFixed(1)} km away'),
              const SizedBox(height: 8),
              Text(
                  'Capacity: $shownCount/${event.capacity} (${spotsLeft - extra <= 0 ? 'Full' : '${spotsLeft - extra} left'})'),
              const SizedBox(height: 12),
              Text(event.description),
              const SizedBox(height: 16),
              if (event.latitude != 0 || event.longitude != 0)
                SizedBox(
                  height: 180,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(event.latitude, event.longitude),
                        zoom: 15,
                      ),
                      markers: {
                        Marker(
                          markerId: const MarkerId('event'),
                          position:
                              LatLng(event.latitude, event.longitude),
                          infoWindow:
                              InfoWindow(title: event.locationName),
                        )
                      },
                      zoomGesturesEnabled: false,
                      scrollGesturesEnabled: false,
                      myLocationButtonEnabled: false,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: (event.latitude == 0 && event.longitude == 0)
                    ? null
                    : () => LocationService.openInMaps(event.latitude,
                        event.longitude, event.locationName),
                icon: const Icon(Icons.map),
                label: const Text('Open in Google Maps'),
              ),
              const SizedBox(height: 16),
              if (_registered == null)
                const Center(child: CircularProgressIndicator())
              else if (_registered == true)
                FilledButton.tonal(
                  onPressed: _busy ? null : () => _cancel(event),
                  child:
                      Text(_busy ? 'Working…' : 'Cancel registration'),
                )
              else
                FilledButton(
                  onPressed:
                      (_busy || event.isFull || event.isPast)
                          ? null
                          : () => _register(event),
                  child: Text(_busy
                      ? 'Working…'
                      : event.isPast
                          ? 'Event ended'
                          : event.isFull
                              ? 'Event full'
                              : 'Register for this event'),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _row(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class EventCategoryLabel {
  static String of(String value) {
    switch (value) {
      case 'academic':
        return 'Academic';
      case 'sports':
        return 'Sports';
      case 'seminar':
        return 'Seminar';
      case 'organization':
        return 'Organization';
      case 'entertainment':
        return 'Entertainment';
      default:
        return value;
    }
  }
}
