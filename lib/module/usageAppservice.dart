import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:my_research/data/data_store.dart';
import 'package:native_shared_preferences/native_shared_preferences.dart';

import '../data/keystring.dart';

class UsageAppService {
  static const platform = MethodChannel('com.example.app/usage_stats');

  Future<List<Map<String, dynamic>>> getFlutterUsageStats() async {
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

  Future<String> getFlutterCurrentApp() async {
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
  Future<int> getFlutterAppUsageTime(String packageName) async {
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

      final currentApp = await getFlutterCurrentApp();
      final usageTime = await getFlutterAppUsageTime(currentApp);

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
  Future<String> getCurrentApp() async {
    final prefs = await NativeSharedPreferences.getInstance();
    return prefs.getString('currentApp') ?? 'Unknown';
  }

  Future<String> getCurrentAppName() async {
    final prefs = await NativeSharedPreferences.getInstance();
    return prefs.getString('currentAppName') ?? 'Unknown';
  }
  Future<String> getAppUsageTime() async {
    final prefs = await NativeSharedPreferences.getInstance();
    return prefs.getString('appUsageTime') ?? '0분';
  }

  Future<List<Map<String, dynamic>>> getUsageStats() async {
    final prefs = await NativeSharedPreferences.getInstance();
    String usageStatsString = prefs.getString('usageStats') ?? '[]';
    List<dynamic> usageStatsList = jsonDecode(usageStatsString);
    return usageStatsList.cast<Map<String, dynamic>>();
  }
}
