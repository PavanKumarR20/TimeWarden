import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/services/security/security_service.dart';

class JournalLockSetupDialog extends StatefulWidget {
  const JournalLockSetupDialog({super.key});

  @override
  State<JournalLockSetupDialog> createState() => _JournalLockSetupDialogState();
}

class _JournalLockSetupDialogState extends State<JournalLockSetupDialog> {
  final SecurityService _securityService = SecurityService.instance;
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();

  bool _useBiometrics = false;
  bool _hasBiometrics = false;
  bool _isLoading = false;
  String? _errorMessage;
  bool _showPinInput = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometricAvailability() async {
    final available = await _securityService.isBiometricAvailable();
    setState(() {
      _hasBiometrics = available;
      _useBiometrics = available;
      _showPinInput = !available;
    });
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_useBiometrics && _hasBiometrics) {
        // Enable biometric authentication
        await _securityService.setBiometricEnabledForJournal(true);
      } else if (_showPinInput) {
        // Validate PIN
        if (_pinController.text.isEmpty) {
          setState(() {
            _errorMessage = 'Please enter a PIN';
            _isLoading = false;
          });
          return;
        }

        if (_pinController.text.length != 6) {
          setState(() {
            _errorMessage = 'PIN must be 6 digits';
            _isLoading = false;
          });
          return;
        }

        if (_pinController.text != _confirmPinController.text) {
          setState(() {
            _errorMessage = 'PINs do not match';
            _isLoading = false;
          });
          return;
        }

        // Set PIN
        await _securityService.setJournalPin(_pinController.text);
      }

      // Return success
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Setup failed: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: const Text('Setup Journal Lock'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose how you want to protect your journal:',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),

            // Biometric Option
            if (_hasBiometrics) ...[
              Card(
                color: _useBiometrics ? colorScheme.primaryContainer : null,
                child: ListTile(
                  leading: Icon(
                    Icons.fingerprint,
                    color:
                        _useBiometrics ? colorScheme.onPrimaryContainer : null,
                  ),
                  title: Text(
                    'Biometric Authentication',
                    style: TextStyle(
                      color: _useBiometrics
                          ? colorScheme.onPrimaryContainer
                          : null,
                    ),
                  ),
                  subtitle: Text(
                    'Use fingerprint or face unlock',
                    style: TextStyle(
                      color: _useBiometrics
                          ? colorScheme.onPrimaryContainer.withOpacity(0.7)
                          : null,
                    ),
                  ),
                  trailing: Radio<bool>(
                    value: true,
                    groupValue: _useBiometrics,
                    onChanged: (value) {
                      setState(() {
                        _useBiometrics = true;
                        _showPinInput = false;
                      });
                    },
                  ),
                  onTap: () {
                    setState(() {
                      _useBiometrics = true;
                      _showPinInput = false;
                    });
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],

            // PIN Option
            Card(
              color: (!_useBiometrics || _showPinInput)
                  ? colorScheme.primaryContainer
                  : null,
              child: ListTile(
                leading: Icon(
                  Icons.pin,
                  color: (!_useBiometrics || _showPinInput)
                      ? colorScheme.onPrimaryContainer
                      : null,
                ),
                title: Text(
                  'PIN Protection',
                  style: TextStyle(
                    color: (!_useBiometrics || _showPinInput)
                        ? colorScheme.onPrimaryContainer
                        : null,
                  ),
                ),
                subtitle: Text(
                  'Use a 6-digit PIN',
                  style: TextStyle(
                    color: (!_useBiometrics || _showPinInput)
                        ? colorScheme.onPrimaryContainer.withOpacity(0.7)
                        : null,
                  ),
                ),
                trailing: Radio<bool>(
                  value: false,
                  groupValue: _useBiometrics,
                  onChanged: _hasBiometrics
                      ? (value) {
                          setState(() {
                            _useBiometrics = false;
                            _showPinInput = true;
                          });
                        }
                      : null,
                ),
                onTap: _hasBiometrics
                    ? () {
                        setState(() {
                          _useBiometrics = false;
                          _showPinInput = true;
                        });
                      }
                    : null,
              ),
            ),

            // PIN Input Fields
            if (_showPinInput || !_hasBiometrics) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: const InputDecoration(
                  labelText: 'Enter 6-digit PIN',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _confirmPinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: const InputDecoration(
                  labelText: 'Confirm PIN',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
              ),
            ],

            // Error Message
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: colorScheme.onErrorContainer,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _saveSettings,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Enable'),
        ),
      ],
    );
  }
}
