import 'dart:async';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:health/health.dart';
import 'package:my_research/data/data_store.dart';
import 'package:my_research/data/server_data_listener.dart';
import 'package:pedometer/pedometer.dart';

class BackgroundServiceTest extends StatefulWidget {
  const BackgroundServiceTest({super.key});

  @override
  State<BackgroundServiceTest> createState() => _BackgroundServiceState();
}

class _BackgroundServiceState extends State<BackgroundServiceTest> {

  @override
  void initState() {
    super.initState();
    initPedoState();
    // fetchData();
  }
// The callback function should always be a top-level function.
  StreamSubscription<StepCount>? _stepCountStream;
  int _steps = 0;
  int _oldSteps = 0;

  void initPedoState() {
    _stepCountStream = Pedometer.stepCountStream.listen(
          (StepCount stepCount) { // 변경된 부분
        setState(() {

          _steps = int.parse('${stepCount.steps}');
          if(_oldSteps != _steps) {
            ServerDataListener().sendMessage('$_steps');
            DataStore().saveSharedPreferencesInt("step", _steps);
          }
          _oldSteps=_steps;
        });
      },
      onError: (error) => setState(() => _steps = -1),
      cancelOnError: true,
    );
  }
  @override
  void dispose() {
    _stepCountStream?.cancel();
    super.dispose();
  }
//
//   //health kit

  @override
  WithForegroundTask build(BuildContext context) => WithForegroundTask(
      child: Scaffold(
        appBar: AppBar(title: Text("Background Test"),),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            TextButton(
              child: Text("서버에 메세지 보내기",textAlign: TextAlign.center,),
              onPressed: () async{
                ServerDataListener().sendMessage("test");
              },
            ),
            // Text(_pedometerService.steps.toString()),
            Center(
              child: Text(_steps != -1 ? '오늘 걸음수: $_steps걸음' : '걸음수를 가져오는 중...'),
            ),
          ]
        ),
      )
  );
}

