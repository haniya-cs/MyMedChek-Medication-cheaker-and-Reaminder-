import 'package:flutter/material.dart';
import 'medication.dart';
import 'recurrence.dart';

class AddMedDialog extends StatefulWidget {
  final Function(Medicine) onAdd;
  final Medicine? existingMed;
  const AddMedDialog({super.key, required this.onAdd,this.existingMed});
  @override
  State<AddMedDialog> createState() => _AddMedDialogState();
}

class _AddMedDialogState extends State<AddMedDialog> {
  final nameController = TextEditingController();
  final doseController = TextEditingController();

  List<TimeOfDay> selectedTimes = [];
  RecurrenceType selectedRecurrence = RecurrenceType.daily;

  final int uniqueId = DateTime.now().millisecondsSinceEpoch.remainder(100000);
  List<int> selectedDaysOfWeek = [];
  int? intervalDays = 1;
  int? dayOfMonth = DateTime.now().day;
  DateTime? targetDate;
  //
  @override
  void initState() {
    super.initState();
    final med = widget.existingMed;
    if (med != null) {
      nameController.text = med.name;
      doseController.text = med.dose;
      selectedTimes = List.from(med.times);
      selectedRecurrence = med.recurrence;
      selectedDaysOfWeek = med.daysOfWeek ?? [];
      intervalDays = med.intervalDays;
      dayOfMonth = med.dayOfMonth ?? DateTime.now().day;
      targetDate = med.targetDate;
    }
  }//

  InputDecoration fieldStyle(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.blue),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.blue, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.blue, width: 1.5),
      ),
    );
  }

  Future<void> _pickDate() async {
    final DateTime? d = await showDatePicker(
      context: context,
      initialDate: targetDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              onSurface: Colors.blue,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Colors.blue),
            ),
          ),
          child: child!,
        );
      },
    );
    if (d != null) {
      setState(() {
        targetDate = d;
      });
    }
  }

  Future<void> pickTime() async {
    final TimeOfDay initialTime = selectedTimes.isNotEmpty
        ? selectedTimes.last
        : TimeOfDay.now();

    final t = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              secondaryContainer: Colors.blue,
              secondary: Colors.blue,
              onSurface: Colors.blue,

            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Colors.blue),
            ),
          ),
          child: child!,
        );
      },
    );
    if (t != null) {
      setState(() {
        if (!selectedTimes.contains(t)) {
          selectedTimes.add(t);
          selectedTimes.sort((a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
        }
      });
    }
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message))
    );
  }

  String _weekdayName(int day) {
    switch(day) {
      case 1: return "Mon";
      case 2: return "Tue";
      case 3: return "Wed";
      case 4: return "Thu";
      case 5: return "Fri";
      case 6: return "Sat";
      case 7: return "Sun";
      default: return "";
    }
  }

  Widget _buildDaySelector() {
    return Wrap(
      spacing: 4.0,
      runSpacing: 4.0,
      children: List.generate(7, (index) {
        final day = index + 1;
        final isSelected = selectedDaysOfWeek.contains(day);
        return ChoiceChip(
          label: Text(_weekdayName(day)),
          selected: isSelected,
          selectedColor: Colors.blue,
          backgroundColor: Colors.white,
          onSelected: (bool selected) {
            setState(() {
              if (selected) {
                selectedDaysOfWeek.add(day);
              } else {
                selectedDaysOfWeek.remove(day);
              }
              selectedDaysOfWeek.sort();
            });
          },
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.blue,
            fontWeight: FontWeight.bold,
          ),
        );
      }),
    );
  }

  Widget _buildIntervalInput() {
    return TextField(
      cursorColor: Colors.blue,
      keyboardType: TextInputType.number,
      decoration: fieldStyle("Repeat Every (Days)"),

      onChanged: (value) {
        final int? parsedValue = int.tryParse(value);
        setState(() {
          if (parsedValue != null && parsedValue > 0) {
            intervalDays = parsedValue;
          } else if (value.isEmpty) {
            intervalDays = null;
          }
        });
      },
      controller: TextEditingController(text: intervalDays?.toString() ?? ''),
    );
  }

  Widget _buildDayOfMonthInput() {
    return TextField(
      cursorColor: Colors.blue,
      keyboardType: TextInputType.number,
      decoration: fieldStyle("Day of Month (1-31)"),
      controller: TextEditingController(text: dayOfMonth?.toString() ?? ''),
      onChanged: (value) {
        final int? parsedValue = int.tryParse(value);
        setState(() {
          if (parsedValue != null && parsedValue >= 1 && parsedValue <= 31) {
            dayOfMonth = parsedValue;
          } else if (value.isEmpty) {
            dayOfMonth = null;
          }
        });
      },
    );
  }

  Widget _buildDatePicker() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _pickDate,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        child: Text(
          targetDate == null
              ? "Select Target Date"
              : "Date: ${targetDate!.month}/${targetDate!.day}/${targetDate!.year}",
        ),
      ),
    );
  }

  Widget _buildTimeList() {
    if (selectedTimes.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Scheduled Times:",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
        ),
        const SizedBox(height: 5),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: selectedTimes.map((time) {
            return Chip(
              label: Text(time.format(context)),
              backgroundColor: Colors.lightBlue.shade50,
              onDeleted: () {
                setState(() {
                  selectedTimes.remove(time);
                });
              },
              deleteIcon: const Icon(Icons.close, size: 18, color: Colors.blue),
              labelStyle: const TextStyle(color: Colors.blue),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget? recurrenceDetailWidget;
    if (selectedRecurrence == RecurrenceType.dayOfWeek) {
      recurrenceDetailWidget = _buildDaySelector();
    } else if (selectedRecurrence == RecurrenceType.everyXDays) {
      recurrenceDetailWidget = _buildIntervalInput();
    }
    else if (selectedRecurrence == RecurrenceType.monthly) {
      recurrenceDetailWidget = _buildDayOfMonthInput();
    }
    else if (selectedRecurrence == RecurrenceType.once) {
      recurrenceDetailWidget = _buildDatePicker();
    }

    final contentChildren = [
      TextField(
        controller: nameController,
        cursorColor: Colors.blue,
        decoration: fieldStyle("Medicine name"),
      ),
      const SizedBox(height: 15),
      TextField(
        controller: doseController,
        cursorColor: Colors.blue,
        decoration: fieldStyle("Dose (e.g.,1 tablet)"),
      ),
      const SizedBox(height: 15),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(

          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue, width: 1),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<RecurrenceType>(
            isExpanded: true,
            value: selectedRecurrence,
            icon: const Icon(Icons.arrow_downward, color: Colors.blue),
            dropdownColor: Colors.white,
            style: const TextStyle(color: Colors.blue, fontSize: 16),
            onChanged: (RecurrenceType? newValue) {
              setState(() {
                selectedRecurrence = newValue!;
                if (newValue != RecurrenceType.dayOfWeek) selectedDaysOfWeek = [];
                if (newValue != RecurrenceType.everyXDays) intervalDays = null;
                if (newValue != RecurrenceType.monthly) {
                  dayOfMonth = null;
                } else {
                  dayOfMonth = DateTime.now().day;
                }
                if (newValue != RecurrenceType.once) {
                  targetDate = null;
                }
              });
            },
            items: RecurrenceType.values.map<DropdownMenuItem<RecurrenceType>>((RecurrenceType value) {
              return DropdownMenuItem<RecurrenceType>(
                value: value,
                child: Text(value.name.toUpperCase()),
              );
            }).toList(),
          ),
        ),
      ),
      const SizedBox(height: 15),
      if (recurrenceDetailWidget != null) ...[
        recurrenceDetailWidget,
        const SizedBox(height: 15),
      ],

      _buildTimeList(),
      if (selectedTimes.isNotEmpty)
        const SizedBox(height: 15),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: pickTime,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: Text(
            selectedTimes.isEmpty ? "Add First Reminder Time" : "Add Another Time",
          ),
        ),
      ),
    ];
    return AlertDialog(
      backgroundColor: Colors.white,
      title: const Text(
        "Add Medication",
        style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: contentChildren,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(foregroundColor: Colors.blue),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () {
            if (nameController.text.trim().isEmpty || doseController.text.trim().isEmpty || selectedTimes.isEmpty) {
              _showValidationError('Please fill all required fields and add at least one reminder time.');
              return;
            }
            if (selectedRecurrence == RecurrenceType.dayOfWeek && selectedDaysOfWeek.isEmpty) {
              _showValidationError('Please select at least one day of the week.');
              return;
            }
            if (selectedRecurrence == RecurrenceType.everyXDays && (intervalDays == null || intervalDays! < 1)) {
              _showValidationError('Please specify a valid repeat interval (1 or more days).');
              return;
            }
            if (selectedRecurrence == RecurrenceType.monthly && (dayOfMonth == null || dayOfMonth! < 1 || dayOfMonth! > 31)) {
              _showValidationError('Please specify a valid day of the month (1-31).');
              return;
            }
            if (selectedRecurrence == RecurrenceType.once && targetDate == null) {
              _showValidationError('Please select the specific date for this one-time dose.');
              return;
            }

            widget.onAdd(
                Medicine(
                  id: uniqueId,
                  name: nameController.text.trim(),
                  dose: doseController.text.trim(),
                  recurrence: selectedRecurrence,
                  times: selectedTimes,
                  daysOfWeek: selectedRecurrence == RecurrenceType.dayOfWeek
                      ? selectedDaysOfWeek
                      : null,
                  intervalDays: selectedRecurrence == RecurrenceType.everyXDays
                      ? intervalDays
                      : null,
                  dayOfMonth: selectedRecurrence == RecurrenceType.monthly
                      ? dayOfMonth
                      : null,
                  targetDate: selectedRecurrence == RecurrenceType.once
                      ? targetDate
                      : null,
                ));
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: Text(widget.existingMed != null ? "Save" : "Add"),
        ),
      ],
    );
  }
}