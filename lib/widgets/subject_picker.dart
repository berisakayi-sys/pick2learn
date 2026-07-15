import 'package:flutter/material.dart';

import '../models/subject.dart';

/// A horizontal row of selectable subject chips (Math, Science, English, …).
///
/// Used on the "Type a Question" and "Scan" screens so the AI can tailor its
/// explanation to the right school subject.
class SubjectPicker extends StatelessWidget {
  final Subject selected;
  final ValueChanged<Subject> onChanged;

  const SubjectPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: Subject.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final subject = Subject.values[index];
          final isSelected = subject == selected;
          return ChoiceChip(
            selected: isSelected,
            onSelected: (_) => onChanged(subject),
            avatar: Icon(
              subject.icon,
              size: 18,
              color: isSelected ? Colors.white : subject.color,
            ),
            label: Text(subject.label),
            labelStyle: TextStyle(
              color: isSelected
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
            selectedColor: subject.color,
            showCheckmark: false,
          );
        },
      ),
    );
  }
}
