import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:my_research/data/category.dart';
import 'package:my_research/module/local_notification.dart';
import 'package:my_research/module/pedometerAPI.dart';
import 'package:my_research/page/page_navigation.dart';
import 'package:my_research/data/server_data_listener.dart';

import 'data/data_store.dart';


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

    ServerDataListener().FCMactivce(message);
  });
  //background에서 FCM설정
  FirebaseMessaging.onBackgroundMessage(ServerDataListener().FCMbackgroundMessage);

  await LocalNotification.init();
  final stepCounterService = PedometerAPI();
  stepCounterService.refreshSteps();
  var step = await DataStore().getSharedPreferencesInt(Category().STEP_KEY);

  if(step!.toInt()!=0) {

    DataStore().saveData(Category().ID, Category().FCM, {
      Category().ISFCM: "true",
      Category().STEP_KEY: '$step',
      Category().FIRSTSTEP_KEY : '$step',
    });
    DataStore().saveSharedPreferencesInt(Category().FIRSTSTEP_KEY,step!.toInt());
  }
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
