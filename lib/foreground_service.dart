import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';

class ForegroundServiceAPI extends StatefulWidget {
  const ForegroundServiceAPI({super.key});

  @override
  State<ForegroundServiceAPI> createState() => _ForegroundServiceAPIState();
}

class _ForegroundServiceAPIState extends State<ForegroundServiceAPI> {
  String text = "Stop Service";
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(onPressed: (){
              FlutterBackgroundService().invoke("setAsForeground");
            }, child: const Text("Foreground Service")),
            ElevatedButton(onPressed: (){
              FlutterBackgroundService().invoke("setAsBackground");
            }, child: const Text("Background Service")),
            ElevatedButton(onPressed: () async {
              final service = FlutterBackgroundService();
              bool isRunning = await service.isRunning();
              if(isRunning){

                service.invoke("stopService");
              }else{
                service.startService();
              }
              if(!isRunning){
                text="Stop Service";
              }{
                text= "Start Service";
              }
              setState(() {});
            }, child: Text(text)),
          ],
        ),
      ),

    );
  }

}

Future<void> initializeService() async{
  final service = FlutterBackgroundService();
  await service.configure(iosConfiguration: IosConfiguration(
    autoStart: true,
    onForeground: onStart,
    onBackground: onIosBackground,
  ),
      androidConfiguration: AndroidConfiguration(onStart: onStart, isForegroundMode: true, autoStart: true));
}

@pragma('vm:entry-point')
FutureOr<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized(); // 필요한 경우 주석 처리
  return true;
}
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  if( service is AndroidServiceInstance){
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });
    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }
  service.on('stopService').listen((event) {
    service.stopSelf();
  });
  Timer.periodic(Duration(seconds:  1), (timer) async {
    if(service is AndroidServiceInstance){
      if (await service.isForegroundService()){
        service.setForegroundNotificationInfo(title: "Script ACADEMY", content: "sub my cahnnel");
      }
    }
    //사용자가 모르게 백그라운드 실행됨
    print('background service running');
    service.invoke('update');
  });
}