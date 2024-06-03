import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:my_research/data/keystring.dart';
import 'package:my_research/data/data_store.dart';

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
  List<String> _selectedApps = [];

  @override
  void initState() {
    super.initState();
    _loadSelectedApps();
    _getTop10Apps();
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
        _selectedApps = List<String>.from(json.decode(selectedAppsJson));
      });
    }
  }

  Future<void> _saveSelectedApps() async {
    if (_selectedApps.isEmpty) {
      Fluttertoast.showToast(msg: "앱을 선택해주세요.", gravity: ToastGravity.CENTER);
      return;
    }

    final String selectedAppsJson = json.encode(_selectedApps);
    await _dataStore.saveSharedPreferencesString(KeyValue().SELECTEDAPP, selectedAppsJson);

    Map<String, dynamic> firebaseData = {
      KeyValue().SELECTEDAPP: _selectedApps
    };

    _dataStore.saveData(KeyValue().ID, KeyValue().SELECTEDAPP, firebaseData).then((_) {
      Fluttertoast.showToast(msg: "저장되었습니다.", gravity: ToastGravity.CENTER);
    }).catchError((error) {
      Fluttertoast.showToast(msg: "저장 실패: $error", gravity: ToastGravity.CENTER);
    });
  }

  void _toggleAppSelection(String appName) {
    setState(() {
      if (_selectedApps.contains(appName)) {
        _selectedApps.remove(appName);
      } else {
        _selectedApps.add(appName);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      child: Scaffold(
        body: Column(
          children: [
            ElevatedButton(
              onPressed: _saveSelectedApps,
              child: Text('저장하기'),
            ),
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
                  final isSelected = _selectedApps.contains(appName);

                  return ListTile(
                    title: Text(appName),
                    subtitle: Text(
                        'Usage: ${(totalTimeInForeground / 1000 / 60).toStringAsFixed(1)} mins'),
                    trailing: Checkbox(
                      value: isSelected,
                      onChanged: (bool? value) {
                        _toggleAppSelection(appName);
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
                  final appName = _selectedApps[index];
                  return ListTile(
                    title: Text(appName),
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
