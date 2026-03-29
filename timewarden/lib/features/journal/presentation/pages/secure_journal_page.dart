import 'package:flutter/material.dart';
import '../../../../core/services/security/security_service.dart';
import 'journal_page.dart';
import '../widgets/journal_lock_screen.dart';

class SecureJournalPage extends StatefulWidget {
  const SecureJournalPage({super.key});

  @override
  State<SecureJournalPage> createState() => _SecureJournalPageState();
}

class _SecureJournalPageState extends State<SecureJournalPage>
    with WidgetsBindingObserver {
  bool _isUnlocked = false;
  bool _isLoading = true;
  final SecurityService _securityService = SecurityService.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkLockStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Lock journal when app goes to background
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _lockJournal();
    }

    // Check lock status when app resumes
    if (state == AppLifecycleState.resumed) {
      _checkLockStatus();
    }
  }

  Future<void> _checkLockStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final isLockEnabled = await _securityService.isJournalLockEnabled();

      if (!isLockEnabled) {
        setState(() {
          _isUnlocked = true;
          _isLoading = false;
        });
        return;
      }

      // Check if currently unlocked (within auto-lock duration)
      final isUnlocked = await _securityService.isJournalUnlocked();
      setState(() {
        _isUnlocked = isUnlocked;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isUnlocked = false;
        _isLoading = false;
      });
    }
  }

  Future<void> _lockJournal() async {
    try {
      await _securityService.lockJournal();
      setState(() {
        _isUnlocked = false;
      });
    } catch (e) {
      // Handle error silently
    }
  }

  void _onUnlocked() {
    setState(() {
      _isUnlocked = true;
    });
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

    if (!_isUnlocked) {
      return JournalLockScreen(
        onUnlocked: _onUnlocked,
      );
    }

    return const JournalPage();
  }
}
