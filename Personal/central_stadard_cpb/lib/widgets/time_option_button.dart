import 'package:flutter/material.dart';

class TimeOptionsRow extends StatefulWidget {
  const TimeOptionsRow({super.key});

  @override
  State<TimeOptionsRow> createState() => _TimeOptionsRowState();
}

class _TimeOptionsRowState extends State<TimeOptionsRow> {
  String selectedOption = 'Week';

  @override
  Widget build(BuildContext context) {
    final options = ['Day', 'Week', 'Month', 'Year'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: options.map((option) {
        final isSelected = selectedOption == option;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: ChoiceChip(
            label: Text(option),
            selected: isSelected,
            selectedColor: Colors.teal,
            backgroundColor: Colors.grey[100],
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            onSelected: (bool selected) {
              if (selected) {
                setState(() {
                  selectedOption = option;
                });
              }
            },
          ),
        );
      }).toList(),
    );
  }
}
