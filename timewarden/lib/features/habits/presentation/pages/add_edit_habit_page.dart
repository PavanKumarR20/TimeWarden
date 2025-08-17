import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/habit.dart';
import '../bloc/habits_bloc.dart';
import '../widgets/frequency_selector.dart';
import '../../../../core/services/haptic_service.dart';
import '../../../../core/services/notification_service.dart';

class AddEditHabitPage extends StatefulWidget {
  final Habit? habit;

  const AddEditHabitPage({super.key, this.habit});

  bool get isEditing => habit != null;

  @override
  State<AddEditHabitPage> createState() => _AddEditHabitPageState();
}

class _AddEditHabitPageState extends State<AddEditHabitPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();

  HabitCategory _selectedCategory = HabitCategory.health;
  HabitFrequency _selectedFrequency = const HabitFrequency(
    type: HabitFrequencyType.daily,
    target: 1,
  );
  String? _selectedColor;
  String? _selectedIcon;

  // Reminder fields
  bool _reminderEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 9, minute: 0);

  final List<Color> _availableColors = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
  ];

  final List<String> _availableIcons = [
    '💪',
    '📚',
    '🏃',
    '🧘',
    '💻',
    '🎯',
    '🌅',
    '💧',
    '🥗',
    '😴',
    '📱',
    '🎨',
    '🎵',
    '📝',
    '🧹',
    '💡',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.habit != null) {
      _nameController.text = widget.habit!.name;
      _descriptionController.text = widget.habit!.description ?? '';
      _notesController.text = widget.habit!.notes ?? '';
      _selectedCategory = widget.habit!.category;
      _selectedFrequency = widget.habit!.frequency;
      _selectedColor = widget.habit!.color;
      _selectedIcon = widget.habit!.icon;
      _reminderEnabled = widget.habit!.reminderEnabled;
      if (widget.habit!.reminderHour != null &&
          widget.habit!.reminderMinute != null) {
        _reminderTime = TimeOfDay(
          hour: widget.habit!.reminderHour!,
          minute: widget.habit!.reminderMinute!,
        );
      }
    } else {
      _selectedColor = _availableColors.first.value.toRadixString(16);
      _selectedIcon = _availableIcons.first;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _saveHabit() {
    if (_formKey.currentState!.validate()) {
      try {
        final habit = widget.isEditing
            ? widget.habit!.copyWith(
                name: _nameController.text.trim(),
                description: _descriptionController.text.trim().isEmpty
                    ? null
                    : _descriptionController.text.trim(),
                notes: _notesController.text.trim().isEmpty
                    ? null
                    : _notesController.text.trim(),
                category: _selectedCategory,
                frequency: _selectedFrequency,
                color: _selectedColor,
                icon: _selectedIcon,
                reminderEnabled: _reminderEnabled,
                reminderHour: _reminderEnabled ? _reminderTime.hour : null,
                reminderMinute: _reminderEnabled ? _reminderTime.minute : null,
              )
            : Habit(
                id: const Uuid().v4(),
                name: _nameController.text.trim(),
                description: _descriptionController.text.trim().isEmpty
                    ? null
                    : _descriptionController.text.trim(),
                notes: _notesController.text.trim().isEmpty
                    ? null
                    : _notesController.text.trim(),
                category: _selectedCategory,
                frequency: _selectedFrequency,
                createdAt: DateTime.now(),
                isActive: true,
                currentStreak: 0,
                longestStreak: 0,
                completedDates: const [],
                color: _selectedColor,
                icon: _selectedIcon,
                reminderEnabled: _reminderEnabled,
                reminderHour: _reminderEnabled ? _reminderTime.hour : null,
                reminderMinute: _reminderEnabled ? _reminderTime.minute : null,
              );

        print('Creating habit: ${habit.name} with ID: ${habit.id}');

        // Schedule notification if reminder is enabled
        if (_reminderEnabled && !widget.isEditing) {
          NotificationService().scheduleDailyReminder(
            habitId: habit.id,
            habitName: habit.name,
            hour: _reminderTime.hour,
            minute: _reminderTime.minute,
            description: habit.description,
          );
        }

        if (widget.isEditing) {
          context.read<HabitsBloc>().add(HabitUpdated(habit));
        } else {
          context.read<HabitsBloc>().add(HabitAdded(habit));
        }

        Navigator.of(context).pop();
      } catch (e) {
        print('Error creating habit: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving habit: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _deleteHabit() {
    if (widget.habit != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Habit'),
          content: const Text(
              'Are you sure you want to delete this habit? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                context.read<HabitsBloc>().add(HabitDeleted(widget.habit!.id));
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Close edit page
              },
              child: const Text('Delete'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Habit' : 'Add Habit'),
        actions: [
          if (widget.isEditing)
            IconButton(
              onPressed: _deleteHabit,
              icon: const Icon(Icons.delete),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Name field
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Habit Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.label_outline),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a habit name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description field
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description_outlined),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Notes field
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText:
                    'Add detailed instructions, workout routines, or any additional information...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notes_outlined),
              ),
              maxLines: 5,
              minLines: 3,
            ),
            const SizedBox(height: 16),

            // Category selection
            DropdownButtonFormField<HabitCategory>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: HabitCategory.values.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(_getCategoryDisplayName(category)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCategory = value;
                  });
                }
              },
            ),
            const SizedBox(height: 24),

            // Frequency selection
            FrequencySelector(
              initialFrequency: _selectedFrequency,
              onChanged: (frequency) {
                setState(() {
                  _selectedFrequency = frequency;
                });
              },
            ),
            const SizedBox(height: 24),

            // Color selection
            Text(
              'Color',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _availableColors.map((color) {
                final colorValue =
                    '#${color.value.toRadixString(16).padLeft(8, '0')}';
                final isSelected = _selectedColor == colorValue;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedColor = colorValue;
                    });
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(
                              color: Theme.of(context).colorScheme.primary,
                              width: 3,
                            )
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Icon selection
            Text(
              'Icon',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _availableIcons.map((icon) {
                final isSelected = _selectedIcon == icon;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedIcon = icon;
                    });
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected
                          ? Border.all(
                              color: Theme.of(context).colorScheme.primary,
                              width: 2,
                            )
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        icon,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Reminder section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.notifications_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Reminder',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const Spacer(),
                        Switch(
                          value: _reminderEnabled,
                          onChanged: (value) {
                            HapticService.selectionClick();
                            setState(() {
                              _reminderEnabled = value;
                            });
                          },
                        ),
                      ],
                    ),
                    if (_reminderEnabled) ...[
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 12),
                      Text(
                        'Reminder Time',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          HapticService.buttonTap();
                          final TimeOfDay? picked = await showTimePicker(
                            context: context,
                            initialTime: _reminderTime,
                          );
                          if (picked != null) {
                            setState(() {
                              _reminderTime = picked;
                            });
                          }
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _reminderTime.format(context),
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              const Spacer(),
                              Icon(
                                Icons.keyboard_arrow_down,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Save button
            FilledButton(
              onPressed: () {
                HapticService.buttonTap();
                _saveHabit();
              },
              child: Text(widget.isEditing ? 'Update Habit' : 'Create Habit'),
            ),
          ],
        ),
      ),
    );
  }

  String _getCategoryDisplayName(HabitCategory category) {
    switch (category) {
      case HabitCategory.health:
        return 'Health';
      case HabitCategory.learning:
        return 'Learning';
      case HabitCategory.productivity:
        return 'Productivity';
      case HabitCategory.fitness:
        return 'Fitness';
      case HabitCategory.mindfulness:
        return 'Mindfulness';
      case HabitCategory.social:
        return 'Social';
      case HabitCategory.creative:
        return 'Creative';
      case HabitCategory.other:
        return 'Other';
    }
  }
}
