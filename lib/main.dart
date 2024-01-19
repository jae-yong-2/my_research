import 'package:flutter/material.dart';
import 'package:my_research/home_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}): super(key:key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        //앱의 테마 컬러를 뭘로해줄까?
        primarySwatch: Colors.amber,

        visualDensity: VisualDensity.adaptivePlatformDensity
      ),
      home:HomePage()
    );
  }
}
