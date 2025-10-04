import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/theme_service.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/haptic_service.dart';
import '../widgets/journal_lock_setup_dialog.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseService().currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
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
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Privacy & Security
              Text(
                'Privacy & Security',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.lock),
                      title: const Text('Journal Lock'),
                      subtitle: const Text('Secure your journal with PIN'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        HapticService.buttonTap();
                        _showJournalLockSettings(context);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // About Section
              Text(
                'About',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: const Text('Version'),
                      subtitle: const Text('1.0.0'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        HapticService.buttonTap();
                        _showAboutDialog(context);
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.person),
                      title: const Text('Developer'),
                      subtitle: const Text('Pavan'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        HapticService.buttonTap();
                        _showAboutDialog(context);
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.email),
                      title: const Text('Contact'),
                      subtitle: const Text('r.pavankumarr20@gmail.com'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        HapticService.buttonTap();
                        _showAboutDialog(context);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Sign Out Button
              Center(
                child: FilledButton.icon(
                  onPressed: () {
                    HapticService.buttonTap();
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
        title: Text(
          'Choose Theme',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('Light'),
              value: ThemeMode.light,
              groupValue: themeService.themeMode,
              onChanged: (value) {
                if (value != null) {
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
                  themeService.setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('System'),
              value: ThemeMode.system,
              groupValue: themeService.themeMode,
              onChanged: (value) {
                if (value != null) {
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

  void _showJournalLockSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => JournalLockSetupDialog(),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () {
              HapticService.buttonTap();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              HapticService.buttonTap();
              Navigator.pop(context);
              FirebaseService().signOut();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            const Text('About TimeWarden'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'TimeWarden - Your All-in-One Productivity Hub',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            _buildAboutRow(Icons.info, 'Version', '1.0.0'),
            const SizedBox(height: 12),
            _buildAboutRow(Icons.person, 'Developer', 'Pavan'),
            const SizedBox(height: 12),
            _buildAboutRow(Icons.email, 'Contact', 'r.pavankumarr20@gmail.com'),
            const SizedBox(height: 16),
            const Text(
              'A comprehensive productivity application featuring Pomodoro timer, habit tracking, secure journaling, and goal management.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              HapticService.buttonTap();
              Navigator.pop(context);
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
