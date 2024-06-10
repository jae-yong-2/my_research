import 'dart:io';

import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:my_research/data/keystring.dart';
import 'package:my_research/module/healthKit.dart';
import 'package:my_research/module/local_notification.dart';
import 'package:my_research/module/pedometerAPI.dart';
import 'package:my_research/package/firebase_options.dart';
import 'package:my_research/page/page_navigation.dart';
import 'package:my_research/data/server_data_listener.dart';
import 'package:my_research/page/profile.dart';
import 'package:permission_handler/permission_handler.dart';

import 'data/data_store.dart';
import 'package/const_key.dart';
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  ServerDataListener().FCMactivce(message);
}

const platform = MethodChannel('com.example.app/foreground_service');

Future<void> startForegroundService() async {
  try {
    await platform.invokeMethod('startForegroundService');
  } on PlatformException catch (e) {
    print("Failed to start foreground service: '${e.message}'.");
  }
}

Future<void> _loadTime()async{
  //
  // final int startHour = await DataStore().getSharedPreferencesInt("startHour") ?? 9;
  // final int startMinute = await DataStore().getSharedPreferencesInt("startMinute") ?? 0;
  // final int endHour = await DataStore().getSharedPreferencesInt("endHour") ?? 18;
  // final int endMinute = await DataStore().getSharedPreferencesInt("endMinute") ?? 0;
  // TimeOfDay? _startTime;
  // TimeOfDay? _endTime;
  // _startTime = TimeOfDay(hour: startHour, minute: startMinute);
  // _endTime = TimeOfDay(hour: endHour, minute: endMinute);
  //
  // Map<String, dynamic> operateTime = {
  //   'startHour': _startTime!.hour,
  //   'startMinute': _startTime!.minute,
  //   'endHour': _endTime!.hour,
  //   'endMinute': _endTime!.minute,
  // };
  //
  // // 'operatetime' 카테고리 아래에 시간 정보를 저장합니다.
  // // 여기서 'id'는 사용자의 고유 식별자입니다.
  // await DataStore().saveData("operatetime", KeyValue().ID, operateTime);
}
Future<void> _requestPermission() async {
  // await [
  //   Permission.activityRecognition,
  //   Permission.location,
  // ].request();
}
Future<bool> _setupFirebaseMessaging() async {
  bool isLaunchedByNotification = await LocalNotification.init();
  print(isLaunchedByNotification);

  List<Future> unsubscribeFutures = [];
  for (int i = 0; i < 10; i++) {
    unsubscribeFutures.add(FirebaseMessaging.instance.unsubscribeFromTopic('$i'));
  }
  await Future.wait(unsubscribeFutures);
  await FirebaseMessaging.instance.subscribeToTopic(KeyValue().ID);
  await FirebaseMessaging.instance.subscribeToTopic("update");
  FirebaseMessaging.instance.requestPermission(
    badge: true,
    alert: true,
    sound: true,
  );
  FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    badge: true,
    alert: true,
    sound: true,
  );
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    ServerDataListener().FCMactivce(message);
  });
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  return isLaunchedByNotification;
}
Future<void> _saveInitialData() async {
  var now = DateTime.now();
  var formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
  String time = formatter.format(now);
  await DataStore().saveData(KeyValue().ID, "${KeyValue().CHAT_PAGE_ACCESS_COUNT}/$time", {
    KeyValue().OPEN_STATE: "start",
    KeyValue().TIMESTAMP: time,
  });
  _loadTime();

}
void main() async{
  WidgetsFlutterBinding.ensureInitialized(); // 바인딩 초기화
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Firebase Messaging 설정
  await _setupFirebaseMessaging();
  //FCM & Firebase
  await _requestPermission();
  await _saveInitialData();
  startForegroundService();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Bottom Navigation Demo',
      home: Scaffold(
        body: PageNavigation(initialIndex: 0),
      )
    );
  }
}
