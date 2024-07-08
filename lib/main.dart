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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeApp();
  runApp(const MyApp());
}

Future<void> initializeApp() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await setupFirebaseMessaging();
  startForegroundService();
}

Future<void> setupFirebaseMessaging() async {
  await LocalNotification.init();
  FirebaseMessaging.instance.subscribeToTopic("update");
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
}

Future<void> startForegroundService() async {
  await DataStore().saveSharedPreferencesInt(KeyValue().TIMER, 0);
  await DataStore().saveSharedPreferencesBool(KeyValue().ALARM_CHECKER, false);
  try {
    await platform.invokeMethod('startForegroundService');
    platformFCM.setMethodCallHandler(fcmMethodCallHandler);
  } catch (e) {
    debugPrint("Failed to start foreground service: ${e.toString()}");
  }
}

Future<void> fcmMethodCallHandler(MethodCall call) async {
  if (call.method == "usageStats") {
    final String jsonData = call.arguments;
    Map<String, dynamic> data = jsonDecode(jsonData);
    ServerDataListener().FCMactivce(data);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'My Research App',
      home: Scaffold(body: PageNavigation(initialIndex: 0)),
    );
  }
}
