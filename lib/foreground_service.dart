import 'package:flutter/material.dart';
import 'package:flutter_foreground_service/flutter_foreground_service.dart';
import 'package:pedometer/pedometer.dart';



class MyBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyTask(),
    );
  }
}

class MyTask extends StatefulWidget {
  @override
  _MyTaskState createState() => _MyTaskState();
}

class _MyTaskState extends State<MyTask> {
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
    ForegroundService().start();
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Pedometer in Foreground Service'),
      ),
      body: Center(
        child: Text(
          'Steps: $_stepCountValue',
          style: Theme.of(context).textTheme.headline4,
        ),
      ),
    );
  }
}
