import 'package:flutter/material.dart';
import 'package:flutter_foreground_service/flutter_foreground_service.dart';
import 'package:pedometer/pedometer.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _stepCountValue = 'Unknown';

  @override
  void initState() {
    super.initState();
    startForegroundService();
    initPedometer();
  }

  void startForegroundService() async {
    ForegroundService().start();
  }
  void stopForegroundService() async {
    ForegroundService().stop();
  }

  void initPedometer() {
    Pedometer.stepCountStream.listen((event) {
      setState(() {
        _stepCountValue = event.steps.toString();
      });
    }).onError((error) {
      setState(() {
        _stepCountValue = 'Step Count not available';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      'Steps: $_stepCountValue',
      style: Theme.of(context).textTheme.headline4
    );
  }
}
