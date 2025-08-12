import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../habits/presentation/habit_list_screen.dart';

class DashboardScreen extends StatelessWidget {
  static const route = '/';
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TimeWarden Dashboard'),
        actions: [
          IconButton(
              onPressed: () => context.read<AuthBloc>().add(SignOutRequested()),
              icon: const Icon(Icons.logout))
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            title: const Text('Habits'),
            subtitle: const Text('Track and update today\'s habits'),
            onTap: () => Navigator.pushNamed(context, HabitListScreen.route),
          ),
          const SizedBox(height: 12),
          const Placeholder(fallbackHeight: 120, strokeWidth: 1),
          const SizedBox(height: 12),
          const Text('More dashboard widgets coming soon...'),
        ],
      ),
    );
  }
}
