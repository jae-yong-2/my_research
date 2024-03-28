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
  var status = await Permission.activityRecognition.status;
  if (!status.isGranted) {
    await Permission.activityRecognition.request();
  }
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
  for(int i =0; i<10 ; i ++) {
    await FirebaseMessaging.instance.unsubscribeFromTopic('$i');
  }
  await FirebaseMessaging.instance.subscribeToTopic(Category().ID);
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
  await _requestPermission();

  final stepCounterService = PedometerAPI();
  stepCounterService.refreshSteps();
  var totalstep = await DataStore().getSharedPreferencesInt(Category().TOTALSTEP_KEY);
  print('저장된 걸음수 : $totalstep');

  FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    badge: true,
    alert: true,
    sound: true,
  );

  var time = DateTime.now().millisecondsSinceEpoch;
  await DataStore().saveData(Category().ID, "${Category().CHAT_PAGE_ACCESS_COUNT}/$time",
      {
        Category().OPEN_STATE:"start",
        Category().TIMESTAMP:"$time",
      }
  );


  //걸음수 초기화
  if(totalstep==null){
    print("걸음수 저장이 안됐습니다.");
    DataStore().saveData(Category().ID, Category().CURRENTSTEP, {
      Category().TOTALSTEP_KEY: '0',
      Category().FIRSTSTEP_KEY : '0',
    });

    //FCM이 들어왔을때, 파이어베이스에 값(FCM을 잘 받았는지, 현재까지 걸은것, 어플을 켰을때 초기 걸음수) 저장함.
    //FCM을 받았는지 확인하는 코드
    // await DataStore().saveData(Category().ID, Category().ISFCM, {Category().ISFCM: "true"});
    await DataStore().saveSharedPreferencesInt(Category().FIRSTSTEP_KEY,0);
  } else if((totalstep!.toInt()!=0) ) {
    print("걸음수 저장이 됐습니다.");
    if(await DataStore().getSharedPreferencesInt(Category().FIRSTSTEP_KEY) != null) {
      print("최초걸음수가 저장이 됐습니다.");
      DataStore().saveData(Category().ID, Category().CURRENTSTEP, {
        Category().TOTALSTEP_KEY: '$totalstep',
        Category().FIRSTSTEP_KEY: '$totalstep',
      });

    }else{
      print("최초걸음수가 저장이 안됐습니다.");

      await DataStore().saveSharedPreferencesInt(
          Category().FIRSTSTEP_KEY, totalstep.toInt());
      }
      DataStore().saveData(Category().ID, Category().CURRENTSTEP, {
        Category().TOTALSTEP_KEY: '$totalstep',
        Category().FIRSTSTEP_KEY: '$totalstep',
      });
    }

    //FCM이 들어왔을때, 파이어베이스에 값(FCM을 잘 받았는지, 현재까지 걸은것, 어플을 켰을때 초기 걸음수) 저장함.
    //FCM을 받았는지 확인하는 코드
    // await DataStore().saveData(Category().ID, Category().ISFCM, {Category().ISFCM: "true"});

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
