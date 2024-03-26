import 'dart:io';

import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:my_research/data/keystring.dart';
import 'package:my_research/module/local_notification.dart';
import 'package:my_research/module/pedometerAPI.dart';
import 'package:my_research/package/firebase_options.dart';
import 'package:my_research/page/page_navigation.dart';
import 'package:my_research/data/server_data_listener.dart';

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

void main() async{
  WidgetsFlutterBinding.ensureInitialized(); // 바인딩 초기화
  await LocalNotification.init();

  //FCM & Firebase
  if (Platform.isIOS) {
    await Firebase.initializeApp();
  }
  if (Platform.isAndroid) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform
    );
  }
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

    ServerDataListener().FCMactivce(message);
  });
  //background에서 FCM설정
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  final stepCounterService = PedometerAPI();
  stepCounterService.refreshSteps();
  var step = await DataStore().getSharedPreferencesInt(Category().TOTALSTEP_KEY);
  print('저장된 걸음수 : $step');

  FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    badge: true,
    alert: true,
    sound: true,
  );

  if(step!.toInt()!=0) {
    DataStore().saveData(Category().ID, Category().FCM, {
      Category().TOTALSTEP_KEY: '$step',
      Category().FIRSTSTEP_KEY : '$step',
    });

    //FCM이 들어왔을때, 파이어베이스에 값(FCM을 잘 받았는지, 현재까지 걸은것, 어플을 켰을때 초기 걸음수) 저장함.
    //FCM을 받았는지 확인하는 코드
    await DataStore().saveData(Category().ID, Category().ISFCM, {Category().ISFCM: "true"});
    DataStore().saveSharedPreferencesInt(Category().FIRSTSTEP_KEY,step.toInt());
  }
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
        body: PageNavigation(),
      )
    );
  }
}
