import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:my_research/module/local_notification.dart';
import 'package:my_research/page/page_navigation.dart';
import 'package:my_research/data/server_data_listener.dart';


void main() async{
  WidgetsFlutterBinding.ensureInitialized(); // 바인딩 초기화

  //FCM & Firebase
  await Firebase.initializeApp();
  await FirebaseMessaging.instance.subscribeToTopic('weather');
  // subscribe to topic on each app start-up
  FirebaseMessaging.instance.requestPermission(
    badge: true,
    alert: true,
    sound: true,
  );
  //foreground에서 FCM설정
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');

    LocalNotification.showOngoingNotification(
        title: '${message.data["title"]} foreground',
        body: '${message.data["content"]} foreground',
        payload: "background"
    );
    //
    // var healthManager = StepCounterService.instance;
    //
    // // 오늘 날짜를 기준으로 걸음수 데이터를 가져옵니다.
    // DateTime now = DateTime.now();
    // DateTime startDate = DateTime(now.year, now.month, now.day);
    // DateTime endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    //
    // int steps = await healthManager.fetchSteps(startDate, endDate);
    //
    // // 가져온 걸음수 출력
    // print('오늘 걸음수: $steps');
    ServerDataListener().sendMessage("foreground message");
  });
  //background에서 FCM설정
  FirebaseMessaging.onBackgroundMessage(ServerDataListener().FCMbackgroundMessage);

  await LocalNotification.init();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bottom Navigation Demo',
      home: Scaffold(
        body: PageNavigation(),
      )
    );
  }
}
