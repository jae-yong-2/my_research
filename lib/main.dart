import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_research/chat_page.dart';
import 'package:my_research/page_navigation.dart';
import 'package:my_research/profile.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bottom Navigation Demo',
      home: PageNavigation(),
    );
  }
}
