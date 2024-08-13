import 'dart:convert';
import 'dart:ffi';

import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:my_research/data/data_store.dart';

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
  Future<void> currentUsageTest(String packageName, int usageAllTime, int timer) async {
    final String? selectedDurationJson = await DataStore()
        .getSharedPreferencesString(KeyValue().SELECTEDDURATION);

    if (selectedDurationJson != null) {
      try {
        final Map<String, dynamic> selectedDurationMap = json.decode(selectedDurationJson);
        if (selectedDurationMap.containsKey('hours') && selectedDurationMap.containsKey('minutes')) {
          var selectedDuration = Duration(
              hours: selectedDurationMap['hours'],
              minutes: selectedDurationMap['minutes']);
          final int savedMinutes = selectedDuration.inMinutes;
          final int savedDurationInMinutes = savedMinutes;
          print("----------------------------------");
          print("savedMinutes: $savedMinutes");
          print("usageAllTime: $usageAllTime");
          print("savedDurationInMinutes: $savedDurationInMinutes");
          print("----------------------------------");

          if (timer > savedDurationInMinutes) {
            Fluttertoast.showToast(
              msg: "현재 앱 사용시간이 설정된 시간을 초과했습니다! $timer $savedDurationInMinutes",
              gravity: ToastGravity.CENTER,
            );
          } else {
            Fluttertoast.showToast(
              msg: "현재 앱 사용시간이 설정된 시간을 초과하지 않았습니다. $timer $savedDurationInMinutes",
              gravity: ToastGravity.CENTER,
            );
          }
        } else {
          print("selectedDurationMap에 'hours' 또는 'minutes' 키가 없습니다.");
        }
      } catch (e) {
        print("JSON 파싱 중 오류 발생: $e");
      }
    } else {
      print("selectedDurationJson이 null입니다.");
    }
  }
  // 추가된 메서드: 모든 앱 사용 통계 가져오기
  Future<List<Map<String, dynamic>>> getAllAppsUsage() async {
    try {
      final List<dynamic> result = await platform.invokeMethod('getAllAppsUsage');
      return result.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } on PlatformException catch (e) {
      if (e.code == "PERMISSION_DENIED") {
        Fluttertoast.showToast(msg: "Usage Stats permission is denied. Please grant the permission in settings.");
      } else {
        print("Failed to get all apps usage: '${e.message}'.");
      }
      return [];
    }
  }
}
