import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/services/security/security_service.dart';

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
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();
  late SecurityService _securityService;
  bool _isLoading = true;
  bool _showPinInput = false;
  bool _isAuthenticating = false;
  String? _errorMessage;
  List<bool> _pinDigits = [false, false, false, false, false, false];

  @override
  void initState() {
    super.initState();
    _securityService = SecurityService.instance;
    _initializeAuth();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _pinFocusNode.dispose();
    super.dispose();
  }

  Future<void> _initializeAuth() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Check if biometric authentication is available
      final hasBiometrics = await _securityService.isBiometricAvailable();

      if (hasBiometrics) {
        // Try biometric authentication first
        await _authenticateWithBiometrics();
      } else {
        // Show PIN input if biometrics are not available
        setState(() {
          _showPinInput = true;
          _isLoading = false;
        });
        // Auto-focus the PIN input
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _pinFocusNode.requestFocus();
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Authentication initialization failed: ${e.toString()}';
        _showPinInput = true;
        _isLoading = false;
      });
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    if (_isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
      _errorMessage = null;
    });

    try {
      final authenticated = await _securityService.authenticateWithBiometrics();

      if (authenticated) {
        widget.onUnlocked();
      } else {
        // Show PIN input as fallback
        setState(() {
          _showPinInput = true;
          _isLoading = false;
          _isAuthenticating = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _pinFocusNode.requestFocus();
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Biometric authentication failed: ${e.toString()}';
        _showPinInput = true;
        _isLoading = false;
        _isAuthenticating = false;
      });
    }
  }

  Future<void> _authenticateWithPin() async {
    if (_pinController.text.length != 6) return;

    setState(() {
      _isAuthenticating = true;
      _errorMessage = null;
    });

    try {
      final authenticated =
          await _securityService.verifyJournalPin(_pinController.text);

      if (authenticated) {
        widget.onUnlocked();
      } else {
        setState(() {
          _errorMessage = 'Incorrect PIN. Please try again.';
          _isAuthenticating = false;
        });
        _clearPin();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'PIN authentication failed: ${e.toString()}';
        _isAuthenticating = false;
      });
      _clearPin();
    }
  }

  void _clearPin() {
    _pinController.clear();
    setState(() {
      _pinDigits = [false, false, false, false, false, false];
    });
    _pinFocusNode.requestFocus();
  }

  void _onPinChanged(String value) {
    setState(() {
      for (int i = 0; i < 6; i++) {
        _pinDigits[i] = i < value.length;
      }
      _errorMessage = null;
    });

    if (value.length == 6) {
      _authenticateWithPin();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Lock Icon
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.primaryContainer,
                ),
                child: Icon(
                  Icons.lock_outline,
                  size: 64,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),

              const SizedBox(height: 32),

              // Title
              Text(
                'Journal Locked',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),

              const SizedBox(height: 12),

              // Subtitle
              Text(
                'Your journal is protected. Please authenticate to continue.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              if (_isLoading) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                Text(
                  'Initializing authentication...',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ] else if (_showPinInput) ...[
                // PIN Input Section
                Text(
                  'Enter your 6-digit PIN',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),

                const SizedBox(height: 24),

                // PIN Dots Display
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(6, (index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _pinDigits[index]
                            ? colorScheme.primary
                            : colorScheme.outline.withOpacity(0.3),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 32),

                // Hidden PIN Input Field
                Container(
                  width: 0,
                  height: 0,
                  child: TextField(
                    controller: _pinController,
                    focusNode: _pinFocusNode,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    obscureText: true,
                    onChanged: _onPinChanged,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: const InputDecoration(
                      counterText: '',
                      border: InputBorder.none,
                    ),
                  ),
                ),

                // Number Pad
                _buildNumberPad(),

                const SizedBox(height: 24),

                // Biometric Button
                FutureBuilder<bool>(
                  future: _securityService.isBiometricAvailable(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data == true) {
                      return TextButton.icon(
                        onPressed: _isAuthenticating
                            ? null
                            : _authenticateWithBiometrics,
                        icon: const Icon(Icons.fingerprint),
                        label: const Text('Use Biometric Authentication'),
                        style: TextButton.styleFrom(
                          foregroundColor: colorScheme.primary,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
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

              // Loading Indicator
              if (_isAuthenticating) ...[
                const SizedBox(height: 24),
                const CircularProgressIndicator(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberPad() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      child: Column(
        children: [
          // Rows 1-3
          for (int row = 0; row < 3; row++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (int col = 1; col <= 3; col++)
                    _buildNumberButton(row * 3 + col),
                ],
              ),
            ),

          // Row 4 (0, backspace)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                const SizedBox(width: 64), // Empty space
                _buildNumberButton(0),
                _buildBackspaceButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberButton(int number) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isAuthenticating
            ? null
            : () {
                if (_pinController.text.length < 6) {
                  _pinController.text += number.toString();
                  _onPinChanged(_pinController.text);
                }
              },
        borderRadius: BorderRadius.circular(32),
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
          ),
          child: Center(
            child: Text(
              number.toString(),
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackspaceButton() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isAuthenticating
            ? null
            : () {
                if (_pinController.text.isNotEmpty) {
                  _pinController.text = _pinController.text
                      .substring(0, _pinController.text.length - 1);
                  _onPinChanged(_pinController.text);
                }
              },
        borderRadius: BorderRadius.circular(32),
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
          ),
          child: Center(
            child: Icon(
              Icons.backspace_outlined,
              color: colorScheme.onSurface,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
