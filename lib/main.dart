import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:my_research/local_notification.dart';
import 'package:my_research/message_connector.dart';
import 'package:my_research/page_navigation.dart';
import 'package:workmanager/workmanager.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

//workmanager
void callbackDispatcher() {

  Workmanager().executeTask((task, inputData) {
    // 여기서 백그라운드 작업을 실행
    print("작업이름 : $task");
    LocalNotification.showOngoingNotification(
        title: "background",
        body: "background",
        payload: "background"
    );
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
  // subscribe to topic on each app start-up
  FirebaseMessaging.instance.requestPermission(
    badge: true,
    alert: true,
    sound: true,
  );
  await FirebaseMessaging.instance.subscribeToTopic('weather');
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');

    if (message.notification != null) {
      print('Message also contained a notification: ${message.notification?.title}');
      print('Message also contained a notification: ${message.notification?.body}');
      // LocalNotification.showOngoingNotification(
      //     title: '${message.notification?.title}',
      //     body: '${message.notification?.body}',
      //     payload: "background"
      // );
    }
  });
  FirebaseMessaging.onBackgroundMessage(Message_Connector().FCMbackgroundMessage);

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
