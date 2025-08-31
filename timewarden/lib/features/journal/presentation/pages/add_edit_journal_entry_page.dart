import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../bloc/journal_bloc.dart';
import '../bloc/journal_event.dart';
import '../bloc/journal_state.dart';
import '../../domain/entities/journal_entry.dart';
import '../../../../core/services/haptic_service.dart';

class AddEditJournalEntryPage extends StatefulWidget {
  final JournalEntry? entry;

  const AddEditJournalEntryPage({super.key, this.entry});

  @override
  State<AddEditJournalEntryPage> createState() =>
      _AddEditJournalEntryPageState();
}

class _AddEditJournalEntryPageState extends State<AddEditJournalEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  final _tagsController = TextEditingController();

  MoodType? _selectedMood;
  bool _isFavorite = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.entry != null) {
      _contentController.text = widget.entry!.content;
      _tagsController.text = widget.entry!.tags.join(', ');
      _selectedMood = widget.entry!.mood;
      _isFavorite = widget.entry!.isFavorite;
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<JournalBloc, JournalState>(
      listener: (context, state) {
        if (state is JournalLoaded) {
          Navigator.of(context).pop();
        } else if (state is JournalError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.entry == null ? 'Add Entry' : 'Edit Entry'),
          actions: [
            TextButton(
              onPressed: _isLoading ? null : _saveEntry,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mood Selection
                const Text(
                  'How are you feeling?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: MoodType.values.map((mood) {
                      final isSelected = _selectedMood == mood;
                      return GestureDetector(
                        onTap: () {
                          HapticService.lightImpact();
                          setState(() {
                            _selectedMood = isSelected ? null : mood;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.transparent,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(mood.emoji,
                                  style: const TextStyle(fontSize: 16)),
                              const SizedBox(width: 4),
                              Text(
                                mood.label,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),

                // Content Field
                TextFormField(
                  controller: _contentController,
                  decoration: const InputDecoration(
                    labelText: 'What\'s on your mind?',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.edit_note),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 8,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter some content';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.newline,
                ),
                const SizedBox(height: 16),

                // Tags Field
                TextFormField(
                  controller: _tagsController,
                  decoration: const InputDecoration(
                    labelText: 'Tags (comma separated)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.tag),
                    hintText: 'work, personal, goals',
                  ),
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 16),

                // Favorite Toggle
                SwitchListTile(
                  title: const Text('Add to favorites'),
                  subtitle: const Text('Mark this entry as a favorite'),
                  value: _isFavorite,
                  onChanged: (value) {
                    HapticService.lightImpact();
                    setState(() {
                      _isFavorite = value;
                    });
                  },
                  secondary: Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorite ? Colors.red : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _saveEntry() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    HapticService.buttonTap();
    setState(() {
      _isLoading = true;
    });

    final tags = _tagsController.text
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();

    final entry = JournalEntry(
      id: widget.entry?.id ?? const Uuid().v4(),
      content: _contentController.text.trim(),
      createdAt: widget.entry?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      tags: tags,
      mood: _selectedMood,
      isFavorite: _isFavorite,
    );

    if (widget.entry == null) {
      context.read<JournalBloc>().add(JournalEntryCreateRequested(entry));
    } else {
      context.read<JournalBloc>().add(JournalEntryUpdateRequested(entry));
    }
  }
}
