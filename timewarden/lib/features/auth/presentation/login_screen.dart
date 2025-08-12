import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/auth_repository.dart';
import 'bloc/auth_bloc.dart';

class LoginScreen extends StatefulWidget {
  static const route = '/login';
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegister = false;
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final repo = context.read<IAuthRepository>();
    try {
      if (_isRegister) {
        await repo.registerWithEmail(
            _emailController.text.trim(), _passwordController.text.trim());
      } else {
        await repo.signInWithEmail(
            _emailController.text.trim(), _passwordController.text.trim());
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted)
        setState(() {
          _loading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TimeWarden Auth')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email')),
            TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true),
            const SizedBox(height: 12),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: Text(_loading
                  ? 'Please wait...'
                  : _isRegister
                      ? 'Register'
                      : 'Login'),
            ),
            TextButton(
              onPressed: () => setState(() => _isRegister = !_isRegister),
              child: Text(_isRegister
                  ? 'Have an account? Login'
                  : 'Need an account? Register'),
            )
          ],
        ),
      ),
    );
  }
}
