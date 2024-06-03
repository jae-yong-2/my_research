import 'dart:async';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:my_research/data/data_store.dart';
import 'package:pedometer/pedometer.dart';

import '../data/keystring.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _BackgroundServiceState();
}

class _BackgroundServiceState extends State<FeedbackPage> {
  static const platform = MethodChannel('com.example.app/usage_stats');
  List<Map<String, dynamic>> _usageStats = [];

  Future<void> _getUsageStats() async {
    try {
      final List<dynamic> result = await platform.invokeMethod('getUsageStats');
      setState(() {
        _usageStats = result.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        print(_usageStats);  // 디버깅을 위해 추가
      });
    } on PlatformException catch (e) {
      if (e.code == "PERMISSION_DENIED") {
        Fluttertoast.showToast(msg: "Usage Stats permission is denied. Please grant the permission in settings.");
      } else {
        print("Failed to get usage stats: '${e.message}'.");
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // 초기화는 버튼 클릭 시 수행되도록 변경했습니다.
    // _getUsageStats();
  }

  // The callback function should always be a top-level function.
  StreamSubscription<StepCount>? _stepCountStream;
  int _steps = 0;
  int _oldSteps = 0;

  void initPedoState() {
    _stepCountStream = Pedometer.stepCountStream.listen(
          (StepCount stepCount) {
        setState(() {
          _steps = int.parse('${stepCount.steps}');
          if (_oldSteps != _steps) {
            // ServerDataListener().sendMessage('$_steps');
            DataStore().saveSharedPreferencesInt(KeyValue().TOTALSTEP_KEY, _steps);
          }
          _oldSteps = _steps;
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

  // health kit
  var content1;
  bool check1 = false;

  @override
  WithForegroundTask build(BuildContext context) => WithForegroundTask(
    child: Scaffold(
      appBar: AppBar(
        title: Text("Feedback Page"),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          FutureBuilder<String?>(
            future: DataStore().getSharedPreferencesString("${KeyValue().CONVERSATION}1"),
            builder: (BuildContext context, AsyncSnapshot<String?> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator(); // 로딩 중인 경우
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else {
                content1 = snapshot.data;
                return Column(
                  children: [
                    Text('ChatGPT에게 답장했습니다.\n${snapshot.data}\n\n'),
                    SizedBox(
                      height: 50,
                      width: 300,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.lightBlueAccent, // 배경색을 회색으로 설정
                          borderRadius: BorderRadius.zero, // 모서리를 90도로 각지게 설정
                        ),
                        child: TextButton(
                          style: TextButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero, // 버튼 내부의 모서리도 90도로 설정
                            ),
                          ),
                          onPressed: () async {
                            // ServerDataListener().sendMessage("test");
                            print(content1);
                            if (!check1) {
                              check1 = !check1;
                              await DataStore().saveData(
                                KeyValue().ID,
                                KeyValue().ISPREDICTIONCORRECT,
                                {
                                  KeyValue().CONVERSATION: content1,
                                  KeyValue().ISPREDICTIONCORRECT: "true",
                                  KeyValue().TIMESTAMP: await DataStore()
                                      .getSharedPreferencesString("${KeyValue().TIMESTAMP}1")
                                },
                              );
                              // 저장하는 코드
                              SystemNavigator.pop();
                            } else {
                              Fluttertoast.showToast(msg: "현재 질문은 피드백이 완료되었습니다.");
                            }
                          },
                          child: Text(
                            "맞습니다.",
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    SizedBox(
                      height: 50,
                      width: 300,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.redAccent, // 배경색을 회색으로 설정
                          borderRadius: BorderRadius.zero, // 모서리를 90도로 각지게 설정
                        ),
                        child: TextButton(
                          style: TextButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero, // 버튼 내부의 모서리도 90도로 설정
                            ),
                          ),
                          onPressed: () async {
                            if (!check1) {
                              check1 = !check1;
                              // ServerDataListener().sendMessage("test");
                              print(content1);
                              await DataStore().saveData(
                                KeyValue().ID,
                                KeyValue().ISPREDICTIONCORRECT,
                                {
                                  KeyValue().CONVERSATION: content1,
                                  KeyValue().ISPREDICTIONCORRECT: "false",
                                  KeyValue().TIMESTAMP: await DataStore()
                                      .getSharedPreferencesString("${KeyValue().TIMESTAMP}1")
                                },
                              );
                              // 저장하는 코드
                              SystemNavigator.pop();
                            } else {
                              Fluttertoast.showToast(msg: "현재 질문은 피드백이 완료되었습니다.");
                            }
                          },
                          child: Text(
                            "틀렸습니다.",
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ],
                ); // 'snapshot.data'는 'String?'입니다.
              }
            },
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              await _getUsageStats();
              print(_usageStats);
            },
            child: Text("Get Usage Stats"),
          ),
          SizedBox(height: 20),
          // Text(_pedometerService.steps.toString()),
          Center(),
          Expanded(
            child: _usageStats.isEmpty
                ? Center(child: Text("데이터 없음"))
                : ListView.builder(
              itemCount: _usageStats.length,
              itemBuilder: (context, index) {
                final usageStat = _usageStats[index];
                final totalTimeInForeground = int.tryParse(usageStat['totalTimeInForeground'].toString()) ?? 0;
                return ListTile(
                  title: Text(usageStat['packageName'] ?? 'Unknown'),
                  subtitle: Text(
                      'Usage: ${(totalTimeInForeground / 1000 / 60).toStringAsFixed(1)} mins'),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}
