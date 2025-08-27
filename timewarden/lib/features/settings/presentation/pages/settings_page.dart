import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../../core/services/theme_service.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/security/security_service.dart';
import '../../../../core/services/haptic_service.dart';
import '../widgets/journal_lock_setup_dialog.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseService().currentUser;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Icon(
                        Icons.person,
                        size: 40,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user?.displayName ?? user?.email ?? 'User',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (user?.email != null)
                      Text(
                        user!.email!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // App Settings
            Text(
              'App Settings',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  Consumer<ThemeService>(
                    builder: (context, themeService, child) {
                      return ListTile(
                        leading: Icon(
                          themeService.themeMode == ThemeMode.dark
                              ? Icons.dark_mode
                              : themeService.themeMode == ThemeMode.light
                                  ? Icons.light_mode
                                  : Icons.brightness_auto,
                        ),
                        title: const Text('Theme'),
                        subtitle:
                            Text(_getThemeModeText(themeService.themeMode)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          HapticService.buttonTap();
                          _showThemeDialog(context, themeService);
                        },
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.notifications),
                    title: const Text('Notifications'),
                    subtitle: const Text('Manage notification preferences'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      HapticService.buttonTap();
                      _showNotificationSettings(context);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Data & Privacy
            Text(
              'Data & Privacy',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.backup),
                    title: const Text('Backup & Sync'),
                    subtitle: const Text('Connected to Firebase'),
                    trailing: Icon(
                      Icons.cloud_done,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const Divider(height: 1),
                  FutureBuilder<bool>(
                    future: SecurityService.instance.isJournalLockEnabled(),
                    builder: (context, snapshot) {
                      final isEnabled = snapshot.data ?? false;
                      return ListTile(
                        leading: const Icon(Icons.lock),
                        title: const Text('Journal Lock'),
                        subtitle: Text(isEnabled
                            ? 'Journal is protected'
                            : 'Protect your journal with PIN/biometrics'),
                        trailing: Switch(
                          value: isEnabled,
                          onChanged: (value) =>
                              _handleJournalLockToggle(context, value),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading:
                        const Icon(Icons.delete_forever, color: Colors.red),
                    title: const Text('Delete Account',
                        style: TextStyle(color: Colors.red)),
                    subtitle: const Text('Permanently delete your account'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showDeleteAccountDialog(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // About
            Text(
              'About',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.secondary,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.watch_later_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    title: ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.secondary,
                        ],
                      ).createShader(bounds),
                      child: Text(
                        'TimeWarden',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                      ),
                    ),
                    subtitle: const Text('Version 1.0.0'),
                    trailing: const Icon(Icons.apps),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Sign Out Button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  _showSignOutDialog(context);
                },
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _getThemeModeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light mode';
      case ThemeMode.dark:
        return 'Dark mode';
      case ThemeMode.system:
        return 'System default';
    }
  }

  void _showThemeDialog(BuildContext context, ThemeService themeService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('Light'),
              value: ThemeMode.light,
              groupValue: themeService.themeMode,
              onChanged: (value) {
                if (value != null) {
                  HapticService.buttonTap();
                  themeService.setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Dark'),
              value: ThemeMode.dark,
              groupValue: themeService.themeMode,
              onChanged: (value) {
                if (value != null) {
                  HapticService.buttonTap();
                  themeService.setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('System Default'),
              value: ThemeMode.system,
              groupValue: themeService.themeMode,
              onChanged: (value) {
                if (value != null) {
                  HapticService.buttonTap();
                  themeService.setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleJournalLockToggle(BuildContext context, bool enabled) async {
    try {
      if (enabled) {
        await _showJournalSetupDialog(context);
      } else {
        await _showDisableLockDialog(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _showJournalSetupDialog(BuildContext context) async {
    final security = SecurityService.instance;
    bool? setupSuccessful = await showDialog<bool>(
      context: context,
      builder: (context) => const JournalLockSetupDialog(),
    );

    if (setupSuccessful == true) {
      await security.setJournalLockEnabled(true);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Journal lock enabled successfully!')),
        );
      }
    }
  }

  Future<void> _showDisableLockDialog(BuildContext context) async {
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disable Journal Lock'),
        content: const Text(
          'Are you sure you want to disable journal protection? Your journal will no longer require authentication to access.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Disable'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await SecurityService.instance.setJournalLockEnabled(false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Journal lock disabled')),
        );
      }
    }
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(AuthSignOutRequested());
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This action cannot be undone. All your data will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement account deletion
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Feature coming soon!')),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showNotificationSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('Habit Reminders'),
              subtitle: const Text('Daily habit completion reminders'),
              trailing: Switch(
                value: true,
                onChanged: (value) {
                  HapticService.buttonTap();
                  // For now, just show it's working
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(value
                          ? 'Habit reminders enabled'
                          : 'Habit reminders disabled'),
                    ),
                  );
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.timer),
              title: const Text('Pomodoro Alerts'),
              subtitle: const Text('Session start/end notifications'),
              trailing: Switch(
                value: true,
                onChanged: (value) {
                  HapticService.buttonTap();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(value
                          ? 'Pomodoro alerts enabled'
                          : 'Pomodoro alerts disabled'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              HapticService.buttonTap();
              Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}
