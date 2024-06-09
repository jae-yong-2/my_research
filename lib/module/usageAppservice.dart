import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';

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
}
