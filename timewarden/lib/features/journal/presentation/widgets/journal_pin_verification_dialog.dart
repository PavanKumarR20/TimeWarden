import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/haptic_service.dart';

class JournalPinVerificationDialog extends StatefulWidget {
  final VoidCallback onUnlocked;

  const JournalPinVerificationDialog({
    super.key,
    required this.onUnlocked,
  });

  @override
  State<JournalPinVerificationDialog> createState() =>
      _JournalPinVerificationDialogState();
}

class _JournalPinVerificationDialogState
    extends State<JournalPinVerificationDialog> {
  String _pin = '';
  String? _errorMessage;

  void _addDigit(String digit) {
    HapticService.selectionClick();
    setState(() {
      if (_pin.length < 4) {
        _pin += digit;
        _errorMessage = null;
        if (_pin.length == 4) {
          _verifyPin();
        }
      }
    });
  }

  void _removeDigit() {
    HapticService.selectionClick();
    setState(() {
      if (_pin.isNotEmpty) {
        _pin = _pin.substring(0, _pin.length - 1);
        _errorMessage = null;
      }
    });
  }

  Future<void> _verifyPin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedPin = prefs.getString('journal_pin');

      if (storedPin == _pin) {
        // Store unlock timestamp
        await prefs.setInt('journal_unlocked_timestamp',
            DateTime.now().millisecondsSinceEpoch);
        HapticService.heavyImpact();
        widget.onUnlocked();
      } else {
        setState(() {
          _pin = '';
          _errorMessage = 'Incorrect PIN. Please try again.';
        });
        HapticService.errorAction();
      }
    } catch (e) {
      setState(() {
        _pin = '';
        _errorMessage = 'Error verifying PIN. Please try again.';
      });
      HapticService.errorAction();
    }
  }

  Widget _buildPinDisplay() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index < _pin.length
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
            const Icon(
              Icons.lock_outline,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Enter PIN to unlock Journal',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildPinDisplay(),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 32),
            _buildNumberPad(),
          ],
        ),
      ),
    );
  }
}
