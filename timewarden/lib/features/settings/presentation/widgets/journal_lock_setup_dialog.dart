import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/services/haptic_service.dart';
import '../../../../core/services/security/security_service.dart';

class JournalLockSetupDialog extends StatefulWidget {
  const JournalLockSetupDialog({super.key});

  @override
  State<JournalLockSetupDialog> createState() => _JournalLockSetupDialogState();
}

class _JournalLockSetupDialogState extends State<JournalLockSetupDialog> {
  String _pin = '';
  String _confirmPin = '';
  bool _isConfirmingPin = false;
  bool _isJournalLocked = false;
  final SecurityService _securityService = SecurityService.instance;

  @override
  void initState() {
    super.initState();
    _loadJournalLockStatus();
  }

  Future<void> _loadJournalLockStatus() async {
    try {
      final isLocked = await _securityService.isJournalLockEnabled();
      setState(() {
        _isJournalLocked = isLocked;
      });
    } catch (e) {
      setState(() {
        _isJournalLocked = false;
      });
    }
  }

  void _addDigit(String digit) {
    HapticService.selectionClick();
    setState(() {
      if (_isConfirmingPin) {
        if (_confirmPin.length < 4) {
          _confirmPin += digit;
          if (_confirmPin.length == 4) {
            _verifyPins();
          }
        }
      } else {
        if (_pin.length < 4) {
          _pin += digit;
          if (_pin.length == 4) {
            _isConfirmingPin = true;
          }
        }
      }
    });
  }

  void _removeDigit() {
    HapticService.selectionClick();
    setState(() {
      if (_isConfirmingPin) {
        if (_confirmPin.isNotEmpty) {
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        } else {
          _isConfirmingPin = false;
          if (_pin.isNotEmpty) {
            _pin = _pin.substring(0, _pin.length - 1);
          }
        }
      } else {
        if (_pin.isNotEmpty) {
          _pin = _pin.substring(0, _pin.length - 1);
        }
      }
    });
  }

  Future<void> _verifyPins() async {
    if (_pin == _confirmPin) {
      await _savePinAndEnable();
    } else {
      // Reset and show error
      setState(() {
        _pin = '';
        _confirmPin = '';
        _isConfirmingPin = false;
      });
      _showErrorMessage('PINs do not match. Please try again.');
    }
  }

  Future<void> _savePinAndEnable() async {
    try {
      await _securityService.enableJournalLock(_pin);

      HapticService.heavyImpact();

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Journal lock enabled successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('Failed to enable journal lock. Please try again.');
      }
    }
  }

  Future<void> _disableJournalLock() async {
    try {
      await _securityService.disableJournalLock();

      HapticService.mediumImpact();

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Journal lock disabled')),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('Failed to disable journal lock. Please try again.');
      }
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  Widget _buildPinDisplay() {
    final currentPin = _isConfirmingPin ? _confirmPin : _pin;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index < currentPin.length
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
        );
      }),
    );
  }

  Widget _buildNumberPad() {
    return Column(
      children: [
        for (int row = 0; row < 3; row++)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (int col = 1; col <= 3; col++)
                _buildNumberButton((row * 3 + col).toString()),
            ],
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const SizedBox(width: 72), // Empty space
            _buildNumberButton('0'),
            _buildActionButton(
              icon: Icons.backspace,
              onPressed: _removeDigit,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNumberButton(String number) {
    return GestureDetector(
      onTap: () => _addDigit(number),
      child: Container(
        width: 72,
        height: 72,
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Center(
          child: Text(
            number,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 72,
        height: 72,
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.onSurface,
          size: 24,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Journal Lock',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            if (_isJournalLocked)
              Column(
                children: [
                  const Icon(
                    Icons.lock,
                    size: 48,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Journal is currently protected with a PIN',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _disableJournalLock,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                        foregroundColor: Theme.of(context).colorScheme.onError,
                      ),
                      child: const Text('Disable Journal Lock'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                ],
              )
            else
              Column(
                children: [
                  const Icon(
                    Icons.lock_open,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isConfirmingPin
                        ? 'Confirm your PIN'
                        : 'Set a PIN to protect your journal',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  _buildPinDisplay(),
                  const SizedBox(height: 32),
                  _buildNumberPad(),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
