import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:my_research/local_notification.dart';
import 'package:my_research/server_data_controller.dart';
import 'package:my_research/page_navigation.dart';
import 'package:workmanager/workmanager.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

//workmanager
void callbackDispatcher() {

  Workmanager().executeTask((task, inputData) {
    // 여기서 FCM을 받았을때, 백그라운드 작업(서버에 메세지 보내기)을 실행
    var title = inputData?["title"];
    var content = inputData?["content"];
    print("작업이름 : $task $title $content");

    LocalNotification.showOngoingNotification(
        title: '$title',
        body: '$content',
        payload: "background"
    );
    switch (task) {
      case Workmanager.iOSBackgroundTask:
        print("백그라운드 실행 : $task");
        stderr.writeln("The iOS background fetch was triggered");
        break;
    }
    bool success = true;
    return Future.value(success);
    return Future.value(true);
  });
}

void main() async{
  WidgetsFlutterBinding.ensureInitialized(); // 바인딩 초기화
  await Workmanager().initialize(
    callbackDispatcher// 백그라운드 작업을 처리할 함수
  );

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
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');

    LocalNotification.showOngoingNotification(
        title: '${message.data["title"]} foreground',
        body: '${message.data["content"]} foreground',
        payload: "background"
    );
    ServerDataController().sendMessage("fore");
  });
  //background에서 FCM설정
  FirebaseMessaging.onBackgroundMessage(ServerDataController().FCMbackgroundMessage);

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
