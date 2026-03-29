import 'package:flutter/material.dart';
import '../../domain/entities/habit.dart';

class FrequencySelector extends StatefulWidget {
  final HabitFrequency initialFrequency;
  final ValueChanged<HabitFrequency> onChanged;

  const FrequencySelector({
    super.key,
    required this.initialFrequency,
    required this.onChanged,
  });

  @override
  State<FrequencySelector> createState() => _FrequencySelectorState();
}

class _FrequencySelectorState extends State<FrequencySelector> {
  late HabitFrequency _selectedFrequency;
  final TextEditingController _targetController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedFrequency = widget.initialFrequency;
    _targetController.text = _selectedFrequency.target.toString();
  }

  @override
  void dispose() {
    _targetController.dispose();
    super.dispose();
  }

  void _updateFrequency(HabitFrequencyType type, {int? target}) {
    final newTarget = target ?? _selectedFrequency.target;
    final newFrequency = HabitFrequency(
      type: type,
      target: newTarget,
    );
    setState(() {
      _selectedFrequency = newFrequency;
      _targetController.text = newTarget.toString();
    });
    widget.onChanged(newFrequency);
  }

  void _updateTarget(String value) {
    final target = int.tryParse(value) ?? 1;
    if (target != _selectedFrequency.target) {
      _updateFrequency(_selectedFrequency.type, target: target);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Frequency',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 16),

        // Preset frequency options
        _buildFrequencyOption(
          'Every day',
          HabitFrequencyType.daily,
          target: 1,
        ),

        _buildFrequencyOption(
          'Every 2 days',
          HabitFrequencyType.everyNDays,
          target: 2,
        ),

        _buildFrequencyOption(
          'Every 3 days',
          HabitFrequencyType.everyNDays,
          target: 3,
        ),

        // Custom every N days option
        _buildCustomFrequencyOption(
          'Every',
          'days',
          HabitFrequencyType.everyNDays,
        ),

        // Times per week option
        _buildCustomFrequencyOption(
          '',
          'times per week',
          HabitFrequencyType.timesPerWeek,
        ),

        // Times per month option
        _buildCustomFrequencyOption(
          '',
          'times per month',
          HabitFrequencyType.timesPerMonth,
        ),
      ],
    );
  }

  Widget _buildFrequencyOption(
    String title,
    HabitFrequencyType type, {
    int? target,
  }) {
    final isSelected = _selectedFrequency.type == type &&
        (target == null || _selectedFrequency.target == target);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: RadioListTile<bool>(
        title: Text(title),
        value: true,
        groupValue: isSelected,
        onChanged: (_) => _updateFrequency(type, target: target ?? 1),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  Widget _buildCustomFrequencyOption(
    String prefix,
    String suffix,
    HabitFrequencyType type,
  ) {
    final isSelected = _selectedFrequency.type == type;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Radio<HabitFrequencyType>(
              value: type,
              groupValue: _selectedFrequency.type,
              onChanged: (value) {
                if (value != null) {
                  _updateFrequency(value);
                }
              },
            ),
            if (prefix.isNotEmpty) ...[
              Text(prefix),
              const SizedBox(width: 8),
            ],
            SizedBox(
              width: 60,
              child: TextFormField(
                controller: isSelected ? _targetController : null,
                initialValue: isSelected ? null : '1',
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                ),
                enabled: isSelected,
                onChanged: isSelected ? _updateTarget : null,
                onTap: () {
                  if (!isSelected) {
                    _updateFrequency(type);
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: () => _updateFrequency(type),
                child: Text(
                  suffix,
                  style: TextStyle(
                    color: isSelected
                        ? Theme.of(context).textTheme.bodyMedium?.color
                        : Theme.of(context).disabledColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
