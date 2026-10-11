import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;

import '../models/event.dart';

/// Local reminders: 24h + 1h before each registered event.
/// IDs are deterministic from eventId so cancel/reschedule is idempotent.
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String channelId = 'event_reminders';
  static const String channelName = 'Event Reminders';

  static bool _initialized = false;

  static int idFor24h(String eventId) =>
      (eventId.hashCode & 0x7fffffff) % 1000000000;

  static int idFor1h(String eventId) =>
      ((eventId.hashCode & 0x7fffffff) + 1) % 1000000000;

  static Future<void> init() async {
    if (_initialized) return;
    try {
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const settings = InitializationSettings(android: android);
      await _plugin.initialize(settings: settings);
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(const AndroidNotificationChannel(
            channelId,
            channelName,
            importance: Importance.high,
          ));
    } catch (_) {
      // Plugin unavailable on this device — run without notifications.
      return;
    }
    _initialized = true;
  }

  /// Safe on all API levels: POST_NOTIFICATIONS only exists on API 33+,
  /// so every request is guarded — Android 10 just skips it.
  static Future<void> requestPermissions() async {
    try {
      await init();
    } catch (_) {
      return;
    }
    try {
      await Permission.notification.request();
    } catch (_) {
      // Permission plugin may not support this API level — ignore.
    }
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (_) {
      // No-op on API < 33 — ignore.
    }
  }

  static Future<void> scheduleEventReminders(EventModel event) async {
    await init();
    const details = NotificationDetails(
      android: AndroidNotificationDetails(channelId, channelName,
          importance: Importance.high, priority: Priority.high),
    );
    final now = tz.TZDateTime.now(tz.local);
    final t24 = tz.TZDateTime.from(
        event.startDateTime.subtract(const Duration(hours: 24)), tz.local);
    final t1 = tz.TZDateTime.from(
        event.startDateTime.subtract(const Duration(hours: 1)), tz.local);

    if (t24.isAfter(now)) {
      await _safeSchedule(
        id: idFor24h(event.id),
        title: 'Event tomorrow',
        body: '${event.name} @ ${event.locationName}',
        when: t24,
        details: details,
      );
    }
    if (t1.isAfter(now)) {
      await _safeSchedule(
        id: idFor1h(event.id),
        title: 'Event in 1 hour',
        body: '${event.name} starting soon',
        when: t1,
        details: details,
      );
    }
  }

  /// Exact alarms need API 31+ permission; on Android 10 (API 29) exact is
  /// free but the plugin may still throw — fall back to inexact, never crash.
  static Future<void> _safeSchedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime when,
    required NotificationDetails details,
  }) async {
    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: when,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (_) {
      try {
        await _plugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: when,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      } catch (_) {
        // Notifications unavailable — registration still succeeds.
      }
    }
  }

  static Future<void> cancelEventReminders(String eventId) async {
    try {
      await _plugin.cancel(id: idFor24h(eventId));
    } catch (_) {}
    try {
      await _plugin.cancel(id: idFor1h(eventId));
    } catch (_) {}
  }

  /// Re-schedule all upcoming regs (call on login / app start).
  static Future<void> rescheduleAll(
      List<EventModel> upcomingEvents) async {
    for (final e in upcomingEvents) {
      if (e.startDateTime.isAfter(DateTime.now())) {
        await scheduleEventReminders(e);
      }
    }
  }
}
