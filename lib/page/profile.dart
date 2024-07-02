import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:my_research/data/keystring.dart';
import 'package:my_research/data/data_store.dart';

import '../module/durationPickerDialog.dart';
import '../module/usageAppservice.dart';

//TODO 각 어플에 대한 시간도 설정해야함.

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
            .map((app) {
          final appMap = Map<String, dynamic>.from(app);
          appMap['usageDuration'] = Duration(
            hours: appMap['usageDuration']['hours'],
            minutes: appMap['usageDuration']['minutes'],
          );
          return appMap;
        })
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

    final String selectedAppsJson = json.encode(_selectedApps.map((app) {
      final appMap = Map<String, dynamic>.from(app);
      appMap['usageDuration'] = {
        'hours': appMap['usageDuration'].inHours,
        'minutes': appMap['usageDuration'].inMinutes % 60,
      };
      return appMap;
    }).toList());

    final String selectedDurationJson = json.encode({
      'hours': (_selectedDuration!.inHours),
      'minutes': (_selectedDuration!.inMinutes) % 60,
    });
    final String sleepTimeJson = json.encode({
      'hours': (_sleepTime!.inHours),
      'minutes': (_sleepTime!.inMinutes) % 60,
    });

    // Retrieve existing values from shared preferences
    final existingSelectedAppsJson = await _dataStore.getSharedPreferencesString(KeyValue().SELECTEDAPP);
    final existingSelectedDurationJson = await _dataStore.getSharedPreferencesString(KeyValue().SELECTEDDURATION);
    final existingSleepTimeJson = await _dataStore.getSharedPreferencesString(KeyValue().SLEEPTIME);

    // Check if the new values are the same as the existing ones
    if (selectedAppsJson == existingSelectedAppsJson &&
        selectedDurationJson == existingSelectedDurationJson &&
        sleepTimeJson == existingSleepTimeJson) {
      Fluttertoast.showToast(
        msg: "이미 저장된 값이 있습니다.",
        gravity: ToastGravity.CENTER,
      );
      return;
    }else if(
        null != existingSelectedAppsJson &&
        null != existingSelectedDurationJson &&
        null != existingSleepTimeJson){
      Fluttertoast.showToast(
        msg: "내일부터 적용됩니다.",
        gravity: ToastGravity.CENTER,
      );
      DateTime tomorrow = DateTime.now().add(Duration(days: 1));
      String formattedDate = DateFormat('yyyy-MM-dd').format(tomorrow);

      await _dataStore.saveSharedPreferencesString("${KeyValue().SELECTEDAPP}_$formattedDate", selectedAppsJson);
      await _dataStore.saveSharedPreferencesString("${KeyValue().SELECTEDDURATION}_$formattedDate", selectedDurationJson);
      await _dataStore.saveSharedPreferencesString("${KeyValue().SLEEPTIME}_$formattedDate", sleepTimeJson);

      Map<String, dynamic> firebaseData = {
        KeyValue().SELECTEDAPP: _selectedApps.map((app) {
          final appMap = Map<String, dynamic>.from(app);
          appMap['usageDuration'] = {
            'hours': appMap['usageDuration'].inHours,
            'minutes': appMap['usageDuration'].inMinutes % 60,
          };
          return appMap;
        }).toList(),
        KeyValue().SELECTEDDURATION: {'hours': _selectedDuration!.inHours, 'minutes': _selectedDuration!.inMinutes % 60},
        KeyValue().SLEEPTIME: {'hours': _sleepTime!.inHours, 'minutes': _sleepTime!.inMinutes % 60},
      };
      _dataStore.saveData(KeyValue().ID, '${KeyValue().SELECTEDAPP}_change/$formattedDate', firebaseData);
      print(selectedAppsJson);
      print(selectedDurationJson);
      print(sleepTimeJson);

      return;
    }

    await _dataStore.saveSharedPreferencesString(KeyValue().SELECTEDAPP, selectedAppsJson);
    await _dataStore.saveSharedPreferencesString(KeyValue().SELECTEDDURATION, selectedDurationJson);
    await _dataStore.saveSharedPreferencesString(KeyValue().SLEEPTIME, sleepTimeJson);

    Map<String, dynamic> firebaseData = {
      KeyValue().SELECTEDAPP: _selectedApps.map((app) {
        final appMap = Map<String, dynamic>.from(app);
        appMap['usageDuration'] = {
          'hours': appMap['usageDuration'].inHours,
          'minutes': appMap['usageDuration'].inMinutes % 60,
        };
        return appMap;
      }).toList(),
      KeyValue().SELECTEDDURATION: {'hours': _selectedDuration!.inHours, 'minutes': _selectedDuration!.inMinutes % 60},
      KeyValue().SLEEPTIME: {'hours': _sleepTime!.inHours, 'minutes': _sleepTime!.inMinutes % 60},
    };
    var now = DateTime.now();
    var formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    var time = formatter.format(now);

    _dataStore.saveData(KeyValue().ID, KeyValue().SELECTEDAPP, firebaseData).then((_) {
      Fluttertoast.showToast(msg: selectedDurationJson, gravity: ToastGravity.CENTER);
      Fluttertoast.showToast(msg: sleepTimeJson, gravity: ToastGravity.CENTER);
      Fluttertoast.showToast(msg: "저장되었습니다.", gravity: ToastGravity.CENTER);
    }).catchError((error) {
      Fluttertoast.showToast(msg: "저장 실패: $error", gravity: ToastGravity.CENTER);
    });

    _dataStore.saveData(KeyValue().ID, '${KeyValue().SELECTEDAPP}_history/$time', firebaseData);
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
        _selectedApps.add({
          ...app,
          'usageDuration': Duration(hours: 0, minutes: 0), // 초기 사용 시간 설정
        });
      }
      _removeDuplicateApps();
    });
  }

  void _updateAppUsageTime(String packageName, Duration duration) {
    setState(() {
      final index = _selectedApps.indexWhere((app) => app['packageName'] == packageName);
      if (index >= 0) {
        _selectedApps[index]['usageDuration'] = duration;
      }
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

  Future<void> _selectAppUsageDuration(BuildContext context, String packageName) async {
    final Duration? picked = await showDialog<Duration>(
      context: context,
      builder: (context) => DurationPickerDialog(initialDuration: Duration(hours: 0, minutes: 0)),
    );

    if (picked != null) {
      _updateAppUsageTime(packageName, picked);
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
              Text('선택된 시간: ${_selectedDuration!.inHours}시간 ${_selectedDuration!.inMinutes % 60}분( 시간 분 )'),
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
                    onTap: isSelected
                        ? () => _selectAppUsageDuration(context, packageName)
                        : null,
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
                  final usageDuration = app['usageDuration'] as Duration;
                  return ListTile(
                    title: Text(appName),
                    subtitle: Text('Package: $packageName\nUsage: ${usageDuration.inHours}시간 ${usageDuration.inMinutes % 60}분'),
                    trailing: IconButton(
                      icon: Icon(Icons.timer),
                      onPressed: () => _selectAppUsageDuration(context, packageName),
                    ),
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
