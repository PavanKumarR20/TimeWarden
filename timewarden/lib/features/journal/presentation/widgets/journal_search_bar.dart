import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/journal_bloc.dart';
import '../bloc/journal_event.dart';
import '../../../../core/services/haptic_service.dart';

class JournalSearchBar extends StatefulWidget {
  const JournalSearchBar({super.key});

  @override
  State<JournalSearchBar> createState() => _JournalSearchBarState();
}

class _JournalSearchBarState extends State<JournalSearchBar> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        hintText: 'Search entries...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  HapticService.buttonTap();
                  _controller.clear();
                  context.read<JournalBloc>().add(const JournalSearchCleared());
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        filled: true,
        fillColor:
            Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
      ),
      onChanged: (value) {
        if (value.isEmpty) {
          context.read<JournalBloc>().add(const JournalSearchCleared());
        }
      },
      onSubmitted: (value) {
        if (value.trim().isNotEmpty) {
          HapticService.lightImpact();
          context.read<JournalBloc>().add(JournalSearchRequested(value.trim()));
        }
      },
    );
  }
}
