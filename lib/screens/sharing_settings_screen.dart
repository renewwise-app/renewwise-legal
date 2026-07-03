import 'package:flutter/material.dart';

import 'package:renew_wise/theme/app_theme.dart';

class SharingSettingsScreen extends StatelessWidget {
  const SharingSettingsScreen({super.key});

  static Future<void> push(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const SharingSettingsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sharing')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            color: AppColors.teal.withValues(alpha: 0.08),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Version 1.0',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.teal,
                        ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Local Sharing Ready — invite members, set permissions, and '
                    'track shared activity on this device.',
                    style: TextStyle(height: 1.45),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: Icon(Icons.check_circle_outline, color: AppColors.primary),
            title: Text('Local Sharing Ready'),
            subtitle: Text('Events, members, and permissions stored on-device'),
          ),
          ListTile(
            leading: Icon(Icons.cloud_off_outlined, color: Theme.of(context).colorScheme.onSurfaceVariant),
            title: const Text('Cloud Collaboration'),
            subtitle: const Text('Coming Soon'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'Coming Soon',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Your reminders stay private by default. When you share an event, '
            'only invited members see it — and only with the permission you choose.',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.45),
          ),
        ],
      ),
    );
  }
}
