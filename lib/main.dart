import 'dart:io';

import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:my_research/data/keystring.dart';
import 'package:my_research/module/healthKit.dart';
import 'package:my_research/module/local_notification.dart';
import 'package:my_research/module/pedometerAPI.dart';
import 'package:my_research/package/firebase_options.dart';
import 'package:my_research/page/page_navigation.dart';
import 'package:my_research/data/server_data_listener.dart';
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


Future<void> _requestPermission() async {
  await [
    Permission.activityRecognition,
    Permission.location,
  ].request();
}
Future<bool> _setupFirebaseMessaging() async {
  bool isLaunchedByNotification = await LocalNotification.init();
  print(isLaunchedByNotification);

  List<Future> unsubscribeFutures = [];
  for (int i = 0; i < 10; i++) {
    unsubscribeFutures.add(FirebaseMessaging.instance.unsubscribeFromTopic(KeyValue().ID));
  }
  await Future.wait(unsubscribeFutures);
  await FirebaseMessaging.instance.subscribeToTopic(KeyValue().ID);
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

  int totalStep;
  try {
    totalStep = await HealthKit().getSteps();
  } catch (e) {
    totalStep = 0;
  }
  await DataStore().saveData(KeyValue().ID, KeyValue().CURRENTSTEP, {
    KeyValue().TOTALSTEP_KEY: '$totalStep',
  });
}
void main() async{
  WidgetsFlutterBinding.ensureInitialized(); // 바인딩 초기화
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Firebase Messaging 설정
  bool isLaunchedByNotification = await _setupFirebaseMessaging();
  //FCM & Firebase
  await _requestPermission();
  await _saveInitialData();
  runApp(MyApp(isLaunchedByNotification: isLaunchedByNotification));
}

class MyApp extends StatelessWidget {
  final bool isLaunchedByNotification;
  const MyApp({super.key, required this.isLaunchedByNotification});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Bottom Navigation Demo',
      home: Scaffold(
        body: isLaunchedByNotification
            ? PageNavigation(initialIndex: 2) // FeedbackPage가 있는 인덱스
            : PageNavigation(initialIndex: 0,),
      )
    );
  }
}
