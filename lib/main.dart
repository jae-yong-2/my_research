import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_research/module/local_notification.dart';
import 'package:my_research/package/firebase_options.dart';
import 'package:my_research/page/page_navigation.dart';
import 'package:my_research/data/server_data_listener.dart';

import 'data/data_store.dart';
import 'data/keystring.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
const platform = MethodChannel('com.example.app/foreground_service');
const platformFCM = MethodChannel('com.example.my_research/fcm');

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // ServerDataListener().FCMactivce(message);
}
Future<void> startForegroundService() async {
  await DataStore().saveSharedPreferencesInt(KeyValue().TIMER, 0);
  try {
    await platform.invokeMethod('startForegroundService');

    platformFCM.setMethodCallHandler((MethodCall call) async {
      if (call.method == "usageStats") {
        final String jsonData = call.arguments;
        Map<String, dynamic> data = jsonDecode(jsonData);
        ServerDataListener().FCMactivce(data);
      }
    });
  } on PlatformException catch (e) {
    print("Failed to start foreground service: '${e.message}'.");
  }
}


Future<void> _setupFirebaseMessaging() async {
  await LocalNotification.init();
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
  // FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
  //   // ServerDataListener().FCMactivce(message);
  // });
  // FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
}


void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // 바인딩 초기화
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await _setupFirebaseMessaging();
  startForegroundService();
  runApp(const MyApp());
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
      ),
    );
  }
}
