import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:my_research/local_notification.dart';
import 'package:my_research/page_navigation.dart';
import 'package:workmanager/workmanager.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

//FCM
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp();

  print("Handling a background message: ${message.messageId}");
  // LocalNotification.showOngoingNotification(
  //     title: '${message.notification?.title}',
  //     body: '${message.notification?.body}',
  //     payload: "background"
  // );
}
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

  //FCM
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // subscribe to topic on each app start-up
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
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  //firebase
  await Firebase.initializeApp();

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
