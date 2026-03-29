import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/journal_bloc.dart';
import '../bloc/journal_event.dart';
import '../bloc/journal_state.dart';
import '../../../../core/services/haptic_service.dart';

class JournalFilterChips extends StatelessWidget {
  const JournalFilterChips({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<JournalBloc, JournalState>(
      builder: (context, state) {
        if (state is! JournalLoaded || state.availableTags.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: state.availableTags.length + 1, // +1 for "All" chip
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: const Text('All'),
                    selected: state.currentFilter == null &&
                        state.searchQuery == null &&
                        !state.showingFavorites,
                    onSelected: (_) {
                      HapticService.buttonTap();
                      context
                          .read<JournalBloc>()
                          .add(const JournalFilterCleared());
                    },
                  ),
                );
              }

              final tag = state.availableTags[index - 1];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(tag),
                  selected: state.currentFilter == tag,
                  onSelected: (_) {
                    HapticService.buttonTap();
                    if (state.currentFilter == tag) {
                      context
                          .read<JournalBloc>()
                          .add(const JournalFilterCleared());
                    } else {
                      context
                          .read<JournalBloc>()
                          .add(JournalFilterByTagRequested(tag));
                    }
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}
