
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DurationPickerDialog extends StatefulWidget {
  final Duration initialDuration;

  DurationPickerDialog({required this.initialDuration});

  @override
  _DurationPickerDialogState createState() => _DurationPickerDialogState();
}

class _DurationPickerDialogState extends State<DurationPickerDialog> {
  late int _hours;
  late int _minutes;

  @override
  void initState() {
    super.initState();
    _hours = widget.initialDuration.inHours;
    _minutes = widget.initialDuration.inMinutes % 60;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('시간 선택하기'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text('시간'),
                    NumberPicker(
                      value: _hours,
                      minValue: 0,
                      maxValue: 23,
                      onChanged: (value) => setState(() => _hours = value),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text('분'),
                    NumberPicker(
                      value: _minutes,
                      minValue: 0,
                      maxValue: 59,
                      onChanged: (value) => setState(() => _minutes = value),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('취소'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(Duration(hours: _hours, minutes: _minutes)),
          child: Text('확인'),
        ),
      ],
    );
  }
}

class NumberPicker extends StatelessWidget {
  final int value;
  final int minValue;
  final int maxValue;
  final ValueChanged<int> onChanged;

  const NumberPicker({
    required this.value,
    required this.minValue,
    required this.maxValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton(
          onPressed: () {
            if (value < maxValue) {
              onChanged(value + 1);
            }
          },
          icon: Icon(Icons.arrow_drop_up),
        ),
        Text('$value', style: TextStyle(fontSize: 18)),
        IconButton(
          onPressed: () {
            if (value > minValue) {
              onChanged(value - 1);
            }
          },
          icon: Icon(Icons.arrow_drop_down),
        ),
      ],
    );
  }
}