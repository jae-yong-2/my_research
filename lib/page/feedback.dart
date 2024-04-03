import 'dart:async';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:health/health.dart';
import 'package:my_research/data/data_store.dart';
import 'package:my_research/data/server_data_listener.dart';
import 'package:pedometer/pedometer.dart';

import '../data/keystring.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _BackgroundServiceState();
}

class _BackgroundServiceState extends State<FeedbackPage> {

  @override
  void initState() {
    super.initState();
    // initPedoState();
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
            // ServerDataListener().sendMessage('$_steps');
            DataStore().saveSharedPreferencesInt(Category().TOTALSTEP_KEY, _steps);
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
  var content1;
  bool check1=false;
  var content2;
  bool check2=false;

  @override
  WithForegroundTask build(BuildContext context) => WithForegroundTask(
      child: Scaffold(
        appBar: AppBar(title: Text("Feedback Page"),),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            FutureBuilder<String?>(
              future: DataStore().getSharedPreferencesString(
                  "${Category().CONVERSATION}1"),
              builder: (BuildContext context, AsyncSnapshot<String?> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator(); // 로딩 중인 경우
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  content1= snapshot.data;
                  return
                    Column(children: [
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
                              if(!check1) {
                                check1= !check1;
                                await DataStore().saveData(
                                    Category().ID,
                                    Category().ISPREDICTIONCORRECT,
                                    {
                                      Category().CONVERSATION: content1,
                                      Category().ISPREDICTIONCORRECT: "true",
                                      Category().TIMESTAMP: await DataStore()
                                          .getSharedPreferencesString(
                                          "${Category().TIMESTAMP}1")
                                    }
                                );
                                //저장하는 코드
                                SystemNavigator.pop();
                              }else{
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
                              if(!check1){
                                check1=!check1;
                              // ServerDataListener().sendMessage("test");
                                print(content1);
                                await DataStore().saveData(
                                      Category().ID,
                                      Category().ISPREDICTIONCORRECT,
                                      {
                                        Category().CONVERSATION:content1,
                                        Category().ISPREDICTIONCORRECT:"false",
                                        Category().TIMESTAMP: await DataStore().getSharedPreferencesString("${Category().TIMESTAMP}1")
                                      }
                                  );
                                  //저장하는 코드
                                SystemNavigator.pop();
                                }else{
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
                    ],); // 'snapshot.data'는 'String?'입니다.
                }
              },
            ),
            SizedBox(height: 20),
            FutureBuilder<String?>(
              future: DataStore().getSharedPreferencesString(
                  "${Category().CONVERSATION}1"),
              builder: (BuildContext context, AsyncSnapshot<String?> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator(); // 로딩 중인 경우
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  content2= snapshot.data;
                  return
                    Column(children: [
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
                              if(!check2) {
                                check2 = !check2;
                                print(content2);
                                await DataStore().saveData(
                                    Category().ID,
                                    Category().ISPREDICTIONCORRECT, {
                                    Category().CONVERSATION: content2,
                                    Category().ISPREDICTIONCORRECT: "true",
                                    Category().TIMESTAMP: await DataStore().getSharedPreferencesString("${Category().TIMESTAMP}2")
                                });
                                  //저장하는 코드
                                  SystemNavigator.pop();
                                }else{
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
                              if(!check2) {
                                check2 = !check2;
                                // ServerDataListener().sendMessage("test");
                                print(content2);
                                await DataStore().saveData(
                                    Category().ID,
                                    Category().ISPREDICTIONCORRECT, {
                                    Category().CONVERSATION: content2,
                                    Category().ISPREDICTIONCORRECT: "false",
                                    Category().TIMESTAMP: await DataStore().getSharedPreferencesString("${Category().TIMESTAMP}2")
                                });
                                //저장하는 코드
                                SystemNavigator.pop();
                              }else{
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
                    ],); // 'snapshot.data'는 'String?'입니다.
                }
              },
            ),
            // Text(_pedometerService.steps.toString()),
            Center(
            ),
          ]
        ),
      )
  );
}

