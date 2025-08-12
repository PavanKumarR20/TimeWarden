import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/habit_bloc.dart';

class HabitListScreen extends StatelessWidget {
  static const route = '/habits';
  const HabitListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Habits')),
      body: BlocBuilder<HabitBloc, HabitState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.habits.isEmpty) {
            return const Center(child: Text('No habits yet'));
          }
          return ListView.builder(
            itemCount: state.habits.length,
            itemBuilder: (context, i) {
              final h = state.habits[i];
              return CheckboxListTile(
                title: Text(h.name),
                subtitle: Text(h.category ?? ''),
                value: h.isCompletedToday,
                onChanged: (_) =>
                    context.read<HabitBloc>().add(ToggleHabit(h.id)),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add habit stub
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
