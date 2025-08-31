import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/haptic_service.dart';
import 'journal_pin_verification_dialog.dart';

class JournalLockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;

  const JournalLockScreen({
    super.key,
    required this.onUnlocked,
  });

  @override
  State<JournalLockScreen> createState() => _JournalLockScreenState();
}

class _JournalLockScreenState extends State<JournalLockScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkLockStatus();
  }

  Future<void> _checkLockStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final isLocked = prefs.getBool('journal_locked') ?? false;

      if (!isLocked) {
        widget.onUnlocked();
        return;
      }

      // Check if still unlocked (within auto-lock duration)
      final unlockedTimestamp = prefs.getInt('journal_unlocked_timestamp');
      if (unlockedTimestamp != null) {
        final unlockedTime =
            DateTime.fromMillisecondsSinceEpoch(unlockedTimestamp);
        final now = DateTime.now();
        const autoLockDuration = Duration(minutes: 5);

        if (now.difference(unlockedTime) < autoLockDuration) {
          widget.onUnlocked();
          return;
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showPinDialog() {
    HapticService.buttonTap();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => JournalPinVerificationDialog(
        onUnlocked: widget.onUnlocked,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.book_outlined,
                size: 120,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 32),
              Text(
                'Journal Locked',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Your personal journal is protected.\nEnter your PIN to access your entries.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _showPinDialog,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_open),
                      SizedBox(width: 8),
                      Text('Enter PIN'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
