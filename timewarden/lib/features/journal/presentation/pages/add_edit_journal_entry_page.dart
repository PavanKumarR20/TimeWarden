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
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagsController = TextEditingController();
  final _moodController = TextEditingController();

  int? _rating;
  bool _isFavorite = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.entry != null) {
      _titleController.text = widget.entry!.title;
      _contentController.text = widget.entry!.content;
      _tagsController.text = widget.entry!.tags.join(', ');
      _moodController.text = widget.entry!.mood;
      _rating = widget.entry!.rating;
      _isFavorite = widget.entry!.isFavorite;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    _moodController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.entry != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Entry' : 'New Entry'),
        actions: [
          BlocListener<JournalBloc, JournalState>(
            listener: (context, state) {
              if (state is JournalEntryCreated ||
                  state is JournalEntryUpdated) {
                Navigator.of(context).pop();
              } else if (state is JournalError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
                setState(() {
                  _isLoading = false;
                });
              }
            },
            child: TextButton(
              onPressed: _isLoading ? null : _saveEntry,
              child: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
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
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Content',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                  alignLabelWithHint: true,
                ),
                maxLines: 10,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter some content';
                  }
                  return null;
                },
                textInputAction: TextInputAction.newline,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _moodController,
                decoration: const InputDecoration(
                  labelText: 'Mood (optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.mood),
                  hintText: 'Happy, Sad, Excited, etc.',
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: 'Tags (optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.tag),
                  hintText: 'work, personal, travel (comma separated)',
                ),
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 24),
              Text(
                'Day Rating (optional)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (int i = 1; i <= 5; i++) ...[
                    GestureDetector(
                      onTap: () {
                        HapticService.lightImpact();
                        setState(() {
                          _rating = _rating == i ? null : i;
                        });
                      },
                      child: Icon(
                        _rating != null && i <= _rating!
                            ? Icons.star
                            : Icons.star_border,
                        color: Colors.amber,
                        size: 32,
                      ),
                    ),
                    if (i < 5) const SizedBox(width: 8),
                  ],
                  const SizedBox(width: 16),
                  if (_rating != null)
                    TextButton(
                      onPressed: () {
                        HapticService.buttonTap();
                        setState(() {
                          _rating = null;
                        });
                      },
                      child: const Text('Clear'),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              SwitchListTile(
                title: const Text('Mark as Favorite'),
                subtitle: const Text('Add this entry to your favorites'),
                value: _isFavorite,
                onChanged: (value) {
                  HapticService.lightImpact();
                  setState(() {
                    _isFavorite = value;
                  });
                },
                secondary: Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color:
                      _isFavorite ? Theme.of(context).colorScheme.error : null,
                ),
              ),
            ],
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

    final now = DateTime.now();
    final tags = _tagsController.text
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();

    final entry = JournalEntry(
      id: widget.entry?.id ?? const Uuid().v4(),
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      createdAt: widget.entry?.createdAt ?? now,
      updatedAt: now,
      tags: tags,
      mood: _moodController.text.trim(),
      rating: _rating,
      isFavorite: _isFavorite,
    );

    if (widget.entry != null) {
      context.read<JournalBloc>().add(JournalEntryUpdateRequested(entry));
    } else {
      context.read<JournalBloc>().add(JournalEntryCreateRequested(entry));
    }
  }
}
