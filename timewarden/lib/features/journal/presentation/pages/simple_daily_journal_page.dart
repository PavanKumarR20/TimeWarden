import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../bloc/journal_bloc.dart';
import '../bloc/journal_event.dart';
import '../bloc/journal_state.dart';
import '../../domain/entities/journal_entry.dart';
import '../../../../core/services/haptic_service.dart';

class SimpleDailyJournalPage extends StatefulWidget {
  final JournalEntry? entry;

  const SimpleDailyJournalPage({super.key, this.entry});

  @override
  State<SimpleDailyJournalPage> createState() => _SimpleDailyJournalPageState();
}

class _SimpleDailyJournalPageState extends State<SimpleDailyJournalPage> {
  final _contentController = TextEditingController();
  final _focusNode = FocusNode();

  MoodType? _selectedMood;
  bool _isFavorite = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.entry != null) {
      _contentController.text = widget.entry!.content;
      _selectedMood = widget.entry!.mood;
      _isFavorite = widget.entry!.isFavorite;
    }
    // Auto-focus for immediate typing
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _contentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<JournalBloc, JournalState>(
      listener: (context, state) {
        if (state is JournalLoaded) {
          Navigator.of(context).pop();
        } else if (state is JournalError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: theme.colorScheme.error,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              HapticService.buttonTap();
              Navigator.of(context).pop();
            },
          ),
          actions: [
            // Quick mood selector
            if (_selectedMood != null)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_selectedMood!.emoji,
                        style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 4),
                    Text(
                      _selectedMood!.label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

            // Save button
            TextButton.icon(
              onPressed: _contentController.text.trim().isEmpty || _isLoading
                  ? null
                  : _saveEntry,
              icon: _isLoading
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.primary,
                      ),
                    )
                  : const Icon(Icons.check, size: 20),
              label: Text(_isLoading ? 'Saving...' : 'Save'),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            // Simple mood selector (only show if not selected)
            if (_selectedMood == null) ...[
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How are you feeling?',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: MoodType.values.map((mood) {
                        return GestureDetector(
                          onTap: () {
                            HapticService.buttonTap();
                            setState(() {
                              _selectedMood = mood;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color:
                                    theme.colorScheme.outline.withOpacity(0.2),
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  mood.emoji,
                                  style: const TextStyle(fontSize: 24),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  mood.label,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],

            // Main writing area
            Expanded(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.1),
                  ),
                ),
                child: TextField(
                  controller: _contentController,
                  focusNode: _focusNode,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    height: 1.6,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    hintText: _selectedMood != null
                        ? 'What\'s on your mind?'
                        : 'Select your mood first, then start writing...',
                    hintStyle: theme.textTheme.bodyLarge?.copyWith(
                      color:
                          theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                      height: 1.6,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  enabled: _selectedMood != null,
                  onChanged: (text) {
                    setState(() {}); // Rebuild to update save button state
                  },
                ),
              ),
            ),

            // Bottom actions
            if (_selectedMood != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Change mood button
                    OutlinedButton.icon(
                      onPressed: () {
                        HapticService.buttonTap();
                        setState(() {
                          _selectedMood = null;
                        });
                      },
                      icon: Text(_selectedMood!.emoji),
                      label: Text('Change mood'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.onSurfaceVariant,
                        side: BorderSide(
                          color: theme.colorScheme.outline.withOpacity(0.3),
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Favorite toggle
                    IconButton(
                      onPressed: () {
                        HapticService.buttonTap();
                        setState(() {
                          _isFavorite = !_isFavorite;
                        });
                      },
                      icon: Icon(
                        _isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: _isFavorite
                            ? theme.colorScheme.error
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      tooltip: _isFavorite
                          ? 'Remove from favorites'
                          : 'Add to favorites',
                    ),
                  ],
                ),
              ),
            ],

            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }

  void _saveEntry() {
    if (_contentController.text.trim().isEmpty) return;

    HapticService.buttonTap();
    setState(() {
      _isLoading = true;
    });

    final entry = JournalEntry(
      id: widget.entry?.id ?? const Uuid().v4(),
      content: _contentController.text.trim(),
      createdAt: widget.entry?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      tags: [], // Simplified - no tags for now
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
