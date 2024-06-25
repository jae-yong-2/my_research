import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:my_research/data/keystring.dart';
import 'package:my_research/data/data_store.dart';

import '../module/durationPickerDialog.dart';
import '../module/usageAppservice.dart';

class Profile extends StatefulWidget {
  const Profile({Key? key}) : super(key: key);

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final UsageAppService _usageAppService = UsageAppService();
  final DataStore _dataStore = DataStore();
  List<Map<String, dynamic>> _top10Apps = [];
  List<Map<String, dynamic>> _selectedApps = [];
  Duration? _selectedDuration;
  Duration? _sleepTime;
  String _currentAppName = "";
  int _currentAppUsageTime = 0;

  @override
  void initState() {
    super.initState();
    _loadSelectedApps();
    _getTop10Apps();
    _loadSelectedDuration();
    _loadSleepTime();
  }

  Future<void> _getTop10Apps() async {
    final top10Apps = await _usageAppService.getTop10Apps();
    setState(() {
      _top10Apps = top10Apps;
    });
  }

  Future<void> _loadSelectedApps() async {
    final String? selectedAppsJson = await _dataStore.getSharedPreferencesString(KeyValue().SELECTEDAPP);
    if (selectedAppsJson != null) {
      setState(() {
        _selectedApps = (json.decode(selectedAppsJson) as List<dynamic>)
            .map((app) => Map<String, dynamic>.from(app))
            .toList();
        _removeDuplicateApps();
      });
    }
  }

  Future<void> _loadSelectedDuration() async {
    final String? selectedDurationJson = await _dataStore.getSharedPreferencesString(KeyValue().SELECTEDDURATION);
    if (selectedDurationJson != null) {
      final Map<String, dynamic> selectedDurationMap = json.decode(selectedDurationJson);
      setState(() {
        _selectedDuration = Duration(
          hours: selectedDurationMap['hours'],
          minutes: selectedDurationMap['minutes'],
        );
      });
    }
  }

  Future<void> _loadSleepTime() async {
    final String? sleepTimeJson = await _dataStore.getSharedPreferencesString(KeyValue().SLEEPTIME);
    if (sleepTimeJson != null) {
      final Map<String, dynamic> sleepTimeMap = json.decode(sleepTimeJson);
      setState(() {
        _sleepTime = Duration(
          hours: sleepTimeMap['hours'],
          minutes: sleepTimeMap['minutes'],
        );
      });
    }
  }

  Future<void> _saveSelectedAppsAndDuration() async {
    if (_selectedApps.isEmpty || _selectedDuration == null || _sleepTime == null) {
      Fluttertoast.showToast(msg: "앱, 사용 시간, 그리고 취침 시간을 모두 선택해주세요.", gravity: ToastGravity.CENTER);
      return;
    }

    final String selectedAppsJson = json.encode(_selectedApps);
    final String selectedDurationJson = json.encode({
      'hours': (_selectedDuration!.inHours),
      'minutes': (_selectedDuration!.inMinutes) % 60,
    });
    final String sleepTimeJson = json.encode({
      'hours': (_sleepTime!.inHours),
      'minutes': (_sleepTime!.inMinutes) % 60,
    });

    await _dataStore.saveSharedPreferencesString(KeyValue().SELECTEDAPP, selectedAppsJson);
    await _dataStore.saveSharedPreferencesString(KeyValue().SELECTEDDURATION, selectedDurationJson);
    await _dataStore.saveSharedPreferencesString(KeyValue().SLEEPTIME, sleepTimeJson);

    Map<String, dynamic> firebaseData = {
      KeyValue().SELECTEDAPP: _selectedApps,
      KeyValue().SELECTEDDURATION: {'hours': _selectedDuration!.inHours, 'minutes': _selectedDuration!.inMinutes % 60},
      KeyValue().SLEEPTIME: {'hours': _sleepTime!.inHours, 'minutes': _sleepTime!.inMinutes % 60},
    };

    _dataStore.saveData(KeyValue().ID, KeyValue().SELECTEDAPP, firebaseData).then((_) {
      Fluttertoast.showToast(msg: selectedDurationJson, gravity: ToastGravity.CENTER);
      Fluttertoast.showToast(msg: sleepTimeJson, gravity: ToastGravity.CENTER);
      Fluttertoast.showToast(msg: "저장되었습니다.", gravity: ToastGravity.CENTER);
    }).catchError((error) {
      Fluttertoast.showToast(msg: "저장 실패: $error", gravity: ToastGravity.CENTER);
    });

    print(selectedAppsJson);
    print(selectedDurationJson);
    print(sleepTimeJson);
  }

  void _toggleAppSelection(Map<String, dynamic> app) {
    setState(() {
      final existingIndex = _selectedApps.indexWhere((selectedApp) => selectedApp['appName'] == app['appName']);
      if (existingIndex >= 0) {
        // 이미 선택된 앱이면 목록에서 제거
        _selectedApps.removeAt(existingIndex);
      } else {
        // 선택되지 않은 앱이면 목록에 추가
        _selectedApps.add(app);
      }
      _removeDuplicateApps();
    });
  }

  void _removeDuplicateApps() {
    final uniqueApps = <String, Map<String, dynamic>>{};
    for (var app in _selectedApps) {
      uniqueApps[app['appName']] = app;
    }
    _selectedApps = uniqueApps.values.toList();
  }

  Future<void> _selectDuration(BuildContext context) async {
    final Duration? picked = await showDialog<Duration>(
      context: context,
      builder: (context) => DurationPickerDialog(initialDuration: _selectedDuration ?? Duration(hours: 1, minutes: 0)),
    );

    if (picked != null && picked != _selectedDuration) {
      setState(() {
        _selectedDuration = picked;
      });
    }
  }

  Future<void> _selectSleepTime(BuildContext context) async {
    final Duration? picked = await showDialog<Duration>(
      context: context,
      builder: (context) => DurationPickerDialog(initialDuration: _sleepTime ?? Duration(hours: 8, minutes: 0)),
    );

    if (picked != null && picked != _sleepTime) {
      setState(() {
        _sleepTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      child: Scaffold(
        body: Column(
          children: [
            ElevatedButton(
              onPressed: () => _selectDuration(context),
              child: Text('사용 시간 선택하기'),
            ),
            if (_selectedDuration != null)
              Text('선택된 시간: ${_selectedDuration!.inHours}시간 ${_selectedDuration!.inMinutes % 60}분'),
            ElevatedButton(
              onPressed: () => _selectSleepTime(context),
              child: Text('취침 시간 선택하기'),
            ),
            if (_sleepTime != null)
              Text('선택된 취침 시간: ${_sleepTime!.inHours}시간 ${_sleepTime!.inMinutes % 60}분'),
            Expanded(
              child: _top10Apps.isEmpty
                  ? Center(child: CircularProgressIndicator())
                  : ListView.builder(
                itemCount: _top10Apps.length,
                itemBuilder: (context, index) {
                  final app = _top10Apps[index];
                  final appName = app['appName'] ?? 'Unknown';
                  final packageName = app['packageName'] ?? 'Unknown';
                  final isSelected = _selectedApps.any((selectedApp) => selectedApp['packageName'] == packageName);

                  return ListTile(
                    title: Text(appName),
                    subtitle: Text('Package: $packageName'),
                    trailing: Checkbox(
                      value: isSelected,
                      onChanged: (bool? value) {
                        _toggleAppSelection({'appName': appName, 'packageName': packageName});
                      },
                    ),
                  );
                },
              ),
            ),
            Text('Selected Apps:'),
            Expanded(
              child: ListView.builder(
                itemCount: _selectedApps.length,
                itemBuilder: (context, index) {
                  final app = _selectedApps[index];
                  final appName = app['appName'];
                  final packageName = app['packageName'];
                  return ListTile(
                    title: Text(appName),
                    subtitle: Text('Package: $packageName'),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: _saveSelectedAppsAndDuration,
              child: Text('저장하기'),
            ),
          ],
        ),
      ),
    );
  }
}
