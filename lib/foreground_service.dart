import 'package:flutter/material.dart';
import 'package:flutter_foreground_service/flutter_foreground_service.dart';
import 'package:pedometer/pedometer.dart';
import 'dart:async';
import 'dart:io';

import 'package:activity_recognition_flutter/activity_recognition_flutter.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';



class ForegroundServiceAPI extends StatelessWidget {
  const ForegroundServiceAPI({super.key});

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
  String _statusMesssge = '작동안함';

  StreamSubscription<ActivityEvent>? activityStreamSubscription;
  List<ActivityEvent> _events = [];
  ActivityRecognition activityRecognition = ActivityRecognition();

  @override
  void initState() {
    super.initState();
    startForegroundService();
    _init();
    _events.add(ActivityEvent.unknown());
  }

  @override
  void dispose() {
    activityStreamSubscription?.cancel();
    super.dispose();
  }

  void startForegroundService() async {
    ForegroundService().start();
    _statusMesssge = '백그라운드 시작';
  }
  void stopForegroundService() async {
    ForegroundService().stop();
    _statusMesssge = '백그라운드 종료';
  }

  void _init() async {
    // Android requires explicitly asking permission
    if (Platform.isAndroid) {
      if (await Permission.activityRecognition.request().isGranted) {
        _startTracking();
      }
    }

    // iOS does not
    else {
      _startTracking();
    }
  }

  void _startTracking() {
    activityStreamSubscription = activityRecognition
        .activityStream(runForegroundService: true)
        .listen(onData, onError: onError);
  }

  void onData(ActivityEvent activityEvent) {
    print(activityEvent);
    setState(() {
      _events.add(activityEvent);
    });
  }

  void onError(Object error) {
    print('ERROR - $error');
  }

  Icon _activityIcon(ActivityType type) {
    switch (type) {
      case ActivityType.WALKING:
        return Icon(Icons.directions_walk);
      case ActivityType.IN_VEHICLE:
        return Icon(Icons.car_rental);
      case ActivityType.ON_BICYCLE:
        return Icon(Icons.pedal_bike);
      case ActivityType.ON_FOOT:
        return Icon(Icons.directions_walk);
      case ActivityType.RUNNING:
        return Icon(Icons.run_circle);
      case ActivityType.STILL:
        return Icon(Icons.cancel_outlined);
      case ActivityType.TILTING:
        return Icon(Icons.redo);
      default:
        return Icon(Icons.device_unknown);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_statusMesssge),
      ),
      body:
      Center(
        child: Row(
          children: [
            Center(child:Text("인식 중")),
            ListView.builder(
                itemCount: _events.length,
                reverse: true,
                itemBuilder: (_, int idx) {
                  var activity = _events[idx];
                  return ListTile(
                    leading: _activityIcon(activity.type),
                    title: Text(
                        '${activity.type.toString().split('.').last} (${activity.confidence}%)'),
                    trailing: Text(activity.timeStamp
                        .toString()
                        .split(' ')
                        .last
                        .split('.')
                        .first),
                  );
                }),
          ],
        ),
      ),
    );
  }
}
