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
  Map<String, int> _appUsageTimes = {};
  String _currentAppName = "";
  int _currentAppUsageTime = 0;

  @override
  void initState() {
    super.initState();
    _loadSelectedApps();
    _getTop10Apps();
    _loadSelectedDuration();
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

  Future<void> _saveSelectedAppsAndDuration() async {
    if (_selectedApps.isEmpty || _selectedDuration == null) {
      Fluttertoast.showToast(msg: "앱과 시간을 모두 선택해주세요.", gravity: ToastGravity.CENTER);
      return;
    }

    final String selectedAppsJson = json.encode(_selectedApps);
    final String selectedDurationJson = json.encode({
      'hours': _selectedDuration!.inHours,
      'minutes': _selectedDuration!.inMinutes % 60,
    });

    await _dataStore.saveSharedPreferencesString(KeyValue().SELECTEDAPP, selectedAppsJson);
    await _dataStore.saveSharedPreferencesString(KeyValue().SELECTEDDURATION, selectedDurationJson);

    Map<String, dynamic> firebaseData = {
      KeyValue().SELECTEDAPP: _selectedApps,
      KeyValue().SELECTEDDURATION: {'hours': _selectedDuration!.inHours, 'minutes': _selectedDuration!.inMinutes % 60},
    };

    _dataStore.saveData(KeyValue().ID, KeyValue().SELECTEDAPP, firebaseData).then((_) {
      Fluttertoast.showToast(msg: "저장되었습니다.", gravity: ToastGravity.CENTER);
    }).catchError((error) {
      Fluttertoast.showToast(msg: "저장 실패: $error", gravity: ToastGravity.CENTER);
    });

    print(selectedAppsJson);
    print(selectedDurationJson);
  }

  void _toggleAppSelection(Map<String, dynamic> app) {
    setState(() {
      final existingApp = _selectedApps.firstWhere(
            (selectedApp) => selectedApp['packageName'] == app['packageName'],
        orElse: () => {},
      );

      if (existingApp.isNotEmpty) {
        _selectedApps.remove(existingApp);
      } else {
        _selectedApps.add(app);
      }
    });
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

  Future<void> _currentUsageTest() async {
    final currentApp = await _usageAppService.getCurrentApp();
    final usageTime = await _usageAppService.getAppUsageTime(currentApp);
    print("${usageTime} : 000000000");

    setState(() {
      _currentAppName = currentApp;
      _currentAppUsageTime = usageTime;
    });

    final int savedHours = _selectedDuration?.inHours ?? 0;
    final int savedMinutes = _selectedDuration?.inMinutes ?? 0;
    final int savedDurationInMinutes = savedHours * 60 + savedMinutes;
    final int usageTimeInMinutes = (usageTime / 1000 / 60).toInt();

    if (usageTimeInMinutes > savedDurationInMinutes) {
      Fluttertoast.showToast(
        msg: "현재 앱 사용시간이 설정된 시간을 초과했습니다!",
        gravity: ToastGravity.CENTER,
      );
    } else {
      Fluttertoast.showToast(
        msg: "현재 앱 사용시간이 설정된 시간을 초과하지 않았습니다.",
        gravity: ToastGravity.CENTER,
      );
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
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveSelectedAppsAndDuration,
              child: Text('저장하기'),
            ),
            ElevatedButton(
              onPressed: _currentUsageTest,
              child: Text('현재 앱 테스트'),
            ),
            SizedBox(height: 20),
            Text('Current App: $_currentAppName'),
            Text('Usage Time: ${(_currentAppUsageTime / 1000 / 60).toStringAsFixed(1)} mins'),
            SizedBox(height: 20),
            Expanded(
              child: _top10Apps.isEmpty
                  ? Center(child: CircularProgressIndicator())
                  : ListView.builder(
                itemCount: _top10Apps.length,
                itemBuilder: (context, index) {
                  final app = _top10Apps[index];
                  final totalTimeInForeground = int.tryParse(app['totalTimeInForeground'].toString()) ?? 0;
                  final appName = app['appName'] ?? 'Unknown';
                  final packageName = app['packageName'] ?? 'Unknown';
                  final isSelected = _selectedApps.any((selectedApp) => selectedApp['packageName'] == packageName);

                  return ListTile(
                    title: Text(appName),
                    subtitle: Text(
                        'Usage: ${(totalTimeInForeground / 1000 / 60).toStringAsFixed(1)} mins'),
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
            SizedBox(height: 20),
            Text('Selected Apps:'),
            Expanded(
              child: ListView.builder(
                itemCount: _selectedApps.length,
                itemBuilder: (context, index) {
                  final app = _selectedApps[index];
                  final packageName = app['packageName'];
                  final usageTime = _appUsageTimes[packageName] ?? 0;
                  return ListTile(
                    title: Text(app['appName']),
                    subtitle: Text('Usage Time: ${(usageTime / 1000 / 60).toStringAsFixed(1)} mins'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
