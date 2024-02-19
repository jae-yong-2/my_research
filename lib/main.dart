import 'package:flutter/material.dart';
import 'package:flutter_foreground_service/flutter_foreground_service.dart';
import 'package:my_research/foreground_service.dart';
import 'package:my_research/local_notification.dart';
import 'package:my_research/page_navigation.dart';
import 'package:workmanager/workmanager.dart';

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
