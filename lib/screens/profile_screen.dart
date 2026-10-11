import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../demo/demo_auth.dart';
import '../demo/demo_config.dart';
import '../demo/demo_data.dart';
import '../demo/demo_store.dart';
import '../providers/auth_provider.dart' as app;
import '../services/notification_service.dart';
import '../services/registration_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (kDemoMode) {
      final demo = context.watch<DemoAuth>();
      final store = context.watch<DemoStore>();
      return Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            const Icon(Icons.account_circle, size: 72),
            const SizedBox(height: 12),
            Text(demo.user?.email ?? 'No email',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium),
            Text('Demo mode — no Firebase needed',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () async {
                final now = DateTime.now();
                final upcoming = demoEvents()
                    .where((e) =>
                        store.isRegistered(e.id) &&
                        e.startDateTime.isAfter(now))
                    .toList();
                await NotificationService.rescheduleAll(upcoming);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                          'Reminders refreshed for ${upcoming.length} event(s).')));
                }
              },
              icon: const Icon(Icons.notifications_active),
              label: const Text('Refresh reminders'),
            ),
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              onPressed: () => context.read<DemoAuth>().signOut(),
              icon: const Icon(Icons.logout),
              label: const Text('Sign out'),
            ),
          ],
        ),
      );
    }
    final user = FirebaseAuth.instance.currentUser;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: ListView(
        children: [
          const Icon(Icons.account_circle, size: 72),
          const SizedBox(height: 12),
          Text(user?.email ?? 'No email',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium),
          Text(user?.uid ?? '',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () async {
              final uid = user?.uid;
              if (uid == null) return;
              final regs = await RegistrationService()
                  .myEventsWithDetails(uid);
              final upcoming = regs
                  .map((r) => r.event)
                  .where((e) => e.startDateTime.isAfter(DateTime.now()))
                  .toList();
              await NotificationService.rescheduleAll(upcoming);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                        'Reminders refreshed for ${upcoming.length} event(s).')));
              }
            },
            icon: const Icon(Icons.notifications_active),
            label: const Text('Refresh reminders'),
          ),
          const SizedBox(height: 8),
          FilledButton.tonalIcon(
            onPressed: () =>
                context.read<app.AuthProvider>().signOut(),
            icon: const Icon(Icons.logout),
            label: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}
