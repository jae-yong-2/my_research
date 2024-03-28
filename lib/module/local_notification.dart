import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/state_manager.dart';
import 'package:my_research/page/feedback.dart';

import '../main.dart';


class LocalNotification {
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    final DarwinInitializationSettings initializationSettingsDarwin =
    DarwinInitializationSettings(onDidReceiveLocalNotification: (id, title, body, payload) => null);
    final InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid, iOS: initializationSettingsDarwin);

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse details) async {
          // 액션 클릭 처리
          print("notification 클릭했습니다.");
            // 컨텍스트 없이 네비게이션하기 위해 navigatorKey 사용
          navigatorKey.currentState?.push(MaterialPageRoute(builder: (context) => FeedbackPage()));

        });
    print("notification 을 초기화했습니다.");
  }

  static Future<void> showOngoingNotification({
    required String title,
    required String body,
    required String payload,
  }) async {
    const AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
      'ongoing',
      'ongoing',
      channelDescription: 'ongoing',
      importance: Importance.max,
      priority: Priority.max,
      ongoing: false,
      autoCancel: false,
      actions: <AndroidNotificationAction>[
      ],
    );

    const NotificationDetails notificationDetails = NotificationDetails(android: androidNotificationDetails);

    final int notificationId = DateTime.now().hashCode;
    await _flutterLocalNotificationsPlugin.show(int.parse(payload), title, body, notificationDetails, payload: payload);
  }
}
