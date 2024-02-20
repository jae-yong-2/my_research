import 'dart:async';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:my_research/local_notification.dart';
import 'package:workmanager/workmanager.dart';

class ForegroundServiceAPI extends StatefulWidget {
  const ForegroundServiceAPI({super.key});

  @override
  State<ForegroundServiceAPI> createState() => _ForegroundServiceState();
}

class _ForegroundServiceState extends State<ForegroundServiceAPI> {

  static int i=0;
  void _initForegroundTask() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'foreground_service',
        channelName: 'Foreground Service Notification',
        channelDescription: 'This notification appears when the foreground service is running.',
        channelImportance: NotificationChannelImportance.HIGH,
        priority: NotificationPriority.HIGH,
        iconData: const NotificationIconData(
          resType: ResourceType.mipmap,
          resPrefix: ResourcePrefix.ic,
          name: 'launcher',
        ),
        buttons: [
          const NotificationButton(id: 'sendButton', text: 'Send'),
          const NotificationButton(id: 'testButton', text: 'Test'),
        ],
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: const ForegroundTaskOptions(
        interval: 5000,
        isOnceEvent: false,
        autoRunOnBoot: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _initForegroundTask();
    Future.microtask(() async{
      isRun = await FlutterForegroundTask.isRunningService;
      if(mounted) return;
      setState(() {});
    });
    // Workmanager().registerPeriodicTask(
    //   "test2",
    //   "backup",
    //   frequency: Duration(minutes: 15),
    // );
  }

  bool isRun =false;

  @override
  WithForegroundTask build(BuildContext context) => WithForegroundTask(
      child: Scaffold(
        appBar: AppBar(title: Text("Foreground Task 2023"),),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            TextButton(
            child: Text("주기적 실행",textAlign: TextAlign.center,),
            onPressed: () async{
                _scheduleWork();
              },
            ),
            TextButton(
              child: Text("주기적 실행 종료",textAlign: TextAlign.center,),
              onPressed: () async{
                print("실행 종료");
                Workmanager().cancelAll();
              },
            ),
            ElevatedButton.icon(
              icon: Icon(Icons.notifications),
              onPressed: (){
                LocalNotification.showOngoingNotification(
                    title: "onging",
                    body: "onging",
                    payload: "onging"
                );
              },
              label: Text("ongoing Notification"),
            ),
          ]
        ),
        floatingActionButton: FloatingActionButton(
          child: !isRun
              ?Icon(Icons.play_arrow)
              :Icon(Icons.stop,color: Colors.red,),
          onPressed: () async{
            if(await FlutterForegroundTask.isRunningService) {
              await FlutterForegroundTask.clearAllData();
              await FlutterForegroundTask.stopService();
              print('종료');
            }else{
              await FlutterForegroundTask.startService(
                  notificationTitle: "test",
                  notificationText: "foreground task",
                  callback: startCallback
              );
            }
            isRun = await FlutterForegroundTask.isRunningService;
            setState(() {
            });
          },
        ),
      )
  );

  //스케줄 코드
  void _scheduleWork() {

    // Workmanager().registerOneOffTask(
    //   "simpleTaskOne",
    //   "simpleTaskOne",
    //   initialDelay: Duration(seconds: 10),
    // );
    Workmanager().registerPeriodicTask(
      "simpleTask",
      "simpleTask",
      frequency: Duration(minutes: 15),
    );
  }
}

// The callback function should always be a top-level function.
@pragma('vm:entry-point')
void startCallback() {
  // The setTaskHandler function must be called to handle the task in the background.
  print('실행');
  FlutterForegroundTask.setTaskHandler(FirstTaskHandler());
}

class FirstTaskHandler extends TaskHandler {
  SendPort? _sendPort;

  // Called when the task is started.
  @override
  void onStart(DateTime timestamp, SendPort? sendPort) async {
    _sendPort = sendPort;

    // You can use the getData function to get the stored data.
    final customData =
    await FlutterForegroundTask.getData<String>(key: 'customData');
    print('customData: $customData');
  }

  // Called every [interval] milliseconds in [ForegroundTaskOptions].
  @override
  void onRepeatEvent(DateTime timestamp, SendPort? sendPort) async {
    // Send data to the main isolate.
    sendPort?.send(timestamp);
    // print("안녕");
  }

  // Called when the notification button on the Android platform is pressed.
  @override
  void onDestroy(DateTime timestamp, SendPort? sendPort) async {

  }

  // Called when the notification button on the Android platform is pressed.
  @override
  void onNotificationButtonPressed(String id) {
    print('onNotificationButtonPressed >> $id');
  }


  @override
  void onNotificationPressed() {

    //FlutterForegroundTask.launchApp("/resume-route");
    _sendPort?.send('onNotificationPressed');
  }

}