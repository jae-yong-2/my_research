import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
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
  List<Map<String, dynamic>> _allAppsUsage = [];
  Duration? _selectedDuration;
  Duration? _sleepTime;
  int _currentAppUsageTime = 0;
  bool mode = false;

  @override
  void initState() {
    super.initState();
    _loadSelectedApps();
    _getTop10Apps();
    _loadSelectedDuration();
    _loadSleepTime();
    _loadMode();
  }

  Future<void> _getTop10Apps() async {
    final top10Apps = await _usageAppService.getTop10Apps();
    setState(() {
      _top10Apps = top10Apps;
    });
  }

  Future<void> _getAllAppsUsageAndSave() async {
    final allApps = await _usageAppService.getAllAppsUsage();
    setState(() {
      _allAppsUsage = allApps;  // _top10Apps 변수를 재사용하여 allApps 데이터를 저장
    });

    var now = DateTime.now();
    var formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    String time = formatter.format(now);
    String jsonString = jsonEncode(_allAppsUsage);
    List<dynamic> jsonList = jsonDecode(jsonString);

    await DataStore().saveData(KeyValue().ID, 'twoWeekUsage/$time', {"app": jsonList});
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
    } else if (null != existingSelectedAppsJson &&
        null != existingSelectedDurationJson &&
        null != existingSleepTimeJson) {
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
    var formatter = DateFormat('yyyy-MM-dd');
    var time = formatter.format(now);

    _dataStore.saveData(KeyValue().ID, KeyValue().SELECTEDAPP, firebaseData).then((_) {
      Fluttertoast.showToast(msg: selectedDurationJson, gravity: ToastGravity.CENTER);
      Fluttertoast.showToast(msg: sleepTimeJson, gravity: ToastGravity.CENTER);
      Fluttertoast.showToast(msg: "저장되었습니다.", gravity: ToastGravity.CENTER);
    }).catchError((error) {
      Fluttertoast.showToast(msg: "저장 실패: $error", gravity: ToastGravity.CENTER);
    });

    _dataStore.saveData(KeyValue().ID, '${KeyValue().SELECTEDAPP}_change/$time', firebaseData);
  }

  void _toggleAppSelection(Map<String, dynamic> app) {
    setState(() {
      final existingIndex = _selectedApps.indexWhere((selectedApp) => selectedApp['appName'] == app['appName']);
      if (existingIndex >= 0) {
        _selectedApps.removeAt(existingIndex);
      } else {
        _selectedApps.add({
          ...app,
          'usageDuration': Duration(hours: 0, minutes: 0),
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

  Future<void> _refreshData() async {
    await _loadSelectedApps();
    await _getTop10Apps();
    await _loadSelectedDuration();
    await _loadSleepTime();

    String? selectedApp = await DataStore().getSharedPreferencesString(KeyValue().SELECTEDAPP);
    List<dynamic> selectedAppJson = jsonDecode(selectedApp!);
    List<String> appNames = selectedAppJson.map((selectedAppJson) => selectedAppJson['appName'].toString()).toList();
    for (var appName in appNames) {
      await DataStore().saveSharedPreferencesBool("${KeyValue().ALARM_CHECKER}_${appName}_", false);
      await DataStore().saveSharedPreferencesBool("${KeyValue().ALARM_CHECKER}_$appName", false);
    }
  }

  Future<void> chagneMode() async {
    await DataStore().saveSharedPreferencesBool(KeyValue().MODE, !mode);
    mode = (await DataStore().getSharedPreferencesBool(KeyValue().MODE))!;
    setState(() {});
  }

  Future<void> _loadMode() async {
    mode = (await DataStore().getSharedPreferencesBool(KeyValue().MODE))!;
    mode ??= false;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      child: Scaffold(
        body: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey,
                  width: 1.0,
                ),
                borderRadius: BorderRadius.circular(8.0),
              ),
              padding: EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: () => _selectDuration(context),
                        child: Text('앱 제한 시간 (공통)'),
                      ),
                      if (_selectedDuration != null)
                        Text('선택된 시간: ${_selectedDuration!.inHours}시간 ${_selectedDuration!.inMinutes % 60}분'),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: () => _selectSleepTime(context),
                        child: Text('평소 취침 시간'),
                      ),
                      if (_sleepTime != null)
                        Text('선택된 시간: ${_sleepTime!.inHours}시 ${_sleepTime!.inMinutes % 60}분'),
                    ],
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: _getAllAppsUsageAndSave,  // 기존의 _saveTop10Apps 대신 _getAllAppsUsageAndSave 호출
              style: ButtonStyle(
                minimumSize: MaterialStateProperty.all(Size.fromHeight(10)),
                maximumSize: MaterialStateProperty.all(Size.fromHeight(35)),
                side: MaterialStateProperty.all(BorderSide(color: Colors.black, width: 1)),
                shape: MaterialStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              child: Text(
                "사용을 제한할 앱",
                style: TextStyle(color: Colors.black),
              ),
            ),
            SizedBox(height: 4),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey,
                    width: 1.0,
                  ),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                padding: EdgeInsets.all(8.0),
                child: _top10Apps.isEmpty
                    ? Center(child: CircularProgressIndicator())
                    : ListView.builder(
                  itemCount: _top10Apps.length,
                  itemBuilder: (context, index) {
                    final app = _top10Apps[index];
                    final appName = app['appName'] ?? 'Unknown';
                    final packageName = app['packageName'] ?? 'Unknown';
                    final totalTimeInForeground = app['totalTimeInForeground'] ?? 'Unknown';

                    final isSelected = _selectedApps.any((selectedApp) => selectedApp['packageName'] == packageName);

                    return ListTile(
                      title: Text(appName),
                      subtitle: Text('${((totalTimeInForeground / 7) ~/ 60).toString().padLeft(2, '0')}시 ${((totalTimeInForeground / 7) % 60).toInt()}분 ${(((totalTimeInForeground / 7) * 60) % 60).toInt()}초'),
                      trailing: Checkbox(
                        value: isSelected,
                        onChanged: (bool? value) {
                          _toggleAppSelection({'appName': appName, 'packageName': packageName});
                        },
                      ),
                      onTap: isSelected ? () => _selectAppUsageDuration(context, packageName) : null,
                    );
                  },
                ),
              ),
            ),
            SizedBox(height: 2),
            Container(
              height: 20,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: KeyValue().appOrder.length,
                itemBuilder: (context, index) {
                  final app = KeyValue().appOrder[index];
                  return Text("${index + 1}. $app          ");
                },
              ),
            ),
            SizedBox(height: 4),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey,
                    width: 1.0,
                  ),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                padding: EdgeInsets.all(8.0),
                child: ListView.builder(
                  itemCount: _selectedApps.length,
                  itemBuilder: (context, index) {
                    final app = _selectedApps[index];
                    final appName = app['appName'];
                    final packageName = app['packageName'];
                    final usageDuration = app['usageDuration'] as Duration;

                    return ListTile(
                      title: Text(appName),
                      subtitle: Text('$packageName\n사용 제한 시간 : ${usageDuration.inHours}시간 ${usageDuration.inMinutes % 60}분'),
                      trailing: IconButton(
                        icon: Icon(Icons.timer),
                        onPressed: () => _selectAppUsageDuration(context, packageName),
                      ),
                    );
                  },
                ),
              ),
            ),
            SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: chagneMode,
                  child: Text(mode ? '적용' : '미적용'),
                ),
                Spacer(flex: 1),
                ElevatedButton(
                  onPressed: _saveSelectedAppsAndDuration,
                  child: Text('저장하기'),
                ),
                Spacer(flex: 1),
                IconButton(
                  icon: Icon(Icons.refresh),
                  onPressed: _refreshData,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
