import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:my_research/data/data_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/keystring.dart';

class UsageAppService {
  static const platform = MethodChannel('com.example.app/usage_stats');

  Future<List<Map<String, dynamic>>> getUsageStats() async {
    try {
      final List<dynamic> result = await platform.invokeMethod('getUsageStats');
      return result.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } on PlatformException catch (e) {
      if (e.code == "PERMISSION_DENIED") {
        Fluttertoast.showToast(msg: "Usage Stats permission is denied. Please grant the permission in settings.");
      } else {
        print("Failed to get usage stats: '${e.message}'.");
      }
      return [];
    }
  }

  Future<String> getCurrentApp() async {
    try {
      final String result = await platform.invokeMethod('getCurrentApp');
      return result;
    } on PlatformException catch (e) {
      print("Failed to get current app: '${e.message}'.");
      return "Unknown";
    }
  }

  Future<List<Map<String, dynamic>>> getTop10Apps() async {
    try {
      final List<dynamic> result = await platform.invokeMethod('getTop10Apps');
      return result.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } on PlatformException catch (e) {
      if (e.code == "PERMISSION_DENIED") {
        Fluttertoast.showToast(msg: "Usage Stats permission is denied. Please grant the permission in settings.");
      } else {
        print("Failed to get top 10 apps: '${e.message}'.");
      }
      return [];
    }
  }

  Future<int> getAppUsageTime(String packageName) async {
    try {
      final int result = await platform.invokeMethod('getAppUsageTime', {'packageName': packageName});
      return result;
    } on PlatformException catch (e) {
      print("Failed to get app usage time: '${e.message}'.");
      return 0;
    }
  }

  Future<void> currentUsageTest() async {
    final String? selectedDurationJson = await DataStore()
        .getSharedPreferencesString(KeyValue().SELECTEDDURATION);
    if (selectedDurationJson != null) {
      final Map<String, dynamic> selectedDurationMap = json.decode(
          selectedDurationJson);
      var selectedDuration = Duration(
          hours: selectedDurationMap['hours'],
          minutes: selectedDurationMap['minutes']);

      final currentApp = await getCurrentApp();
      final usageTime = await getAppUsageTime(currentApp);

      final int savedHours = selectedDuration?.inHours ?? 0;
      final int savedMinutes = selectedDuration?.inMinutes ?? 0;
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
  }

  // SharedPreferences를 사용한 메서드들 추가
  Future<String> getCurrentAppFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('currentApp') ?? 'Unknown';
  }

  Future<List<Map<String, dynamic>>> getUsageStatsFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final usageStatsString = prefs.getString('usageStats') ?? '[]';
    return List<Map<String, dynamic>>.from(json.decode(usageStatsString));
  }

  Future<List<Map<String, dynamic>>> getTop10AppsFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final top10AppsString = prefs.getString('top10Apps') ?? '[]';
    return List<Map<String, dynamic>>.from(json.decode(top10AppsString));
  }

  Future<int> getAppUsageTimeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('appUsageTime') ?? 0;
  }
}
