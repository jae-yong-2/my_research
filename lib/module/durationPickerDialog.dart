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
                    Container(
                      height: 200,
                      child: CupertinoPicker(
                        itemExtent: 32.0,
                        onSelectedItemChanged: (value) {
                          setState(() {
                            _hours = value;
                          });
                        },
                        scrollController:
                        FixedExtentScrollController(initialItem: _hours),
                        children: List<Widget>.generate(24, (index) {
                          return Center(
                            child: Text(index.toString()),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text('분'),
                    Container(
                      height: 200,
                      child: CupertinoPicker(
                        itemExtent: 32.0,
                        onSelectedItemChanged: (value) {
                          setState(() {
                            _minutes = value;
                          });
                        },
                        scrollController: FixedExtentScrollController(
                            initialItem: _minutes),
                        children: List<Widget>.generate(60, (index) {
                          return Center(
                            child: Text(index.toString()),
                          );
                        }),
                      ),
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
