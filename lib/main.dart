import 'package:flutter/material.dart';
import 'package:flutter_foreground_service/flutter_foreground_service.dart';
import 'package:my_research/foreground_service.dart';
import 'package:my_research/local_notification.dart';
import 'package:my_research/page_navigation.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await LocalNotification.init();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {

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
