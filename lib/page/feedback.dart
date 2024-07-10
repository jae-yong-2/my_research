import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:my_research/data/data_store.dart';
import 'package:pedometer/pedometer.dart';

import '../data/keystring.dart';
import '../module/local_notification.dart';
import '../package/const_key.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  List<Map<String, dynamic>> _usageStats = [];
  List<Map<String, dynamic>> _top10Apps = [];
  String _currentApp = 'Unknown';
  int _appUsageTime = 0;
  String? selectedapp;
  String? selectedappNext;
  String? selectedDuration;
  String? selectedDurationNext;
  String? sleeptime;
  String? sleeptimeNext;
  String? result="null";

  @override
  void initState() {
    super.initState();
    todaySetting();
    tomorrowSetting();
  }

  StreamSubscription<StepCount>? _stepCountStream;
  int _steps = 0;
  int _oldSteps = 0;


  @override
  void dispose() {
    _stepCountStream?.cancel();
    super.dispose();
  }

  Future<void> todaySetting() async {
    selectedapp = await DataStore().getSharedPreferencesString(KeyValue().SELECTEDAPP);
    selectedDuration = await DataStore().getSharedPreferencesString(KeyValue().SELECTEDDURATION);
    sleeptime = await DataStore().getSharedPreferencesString(KeyValue().SLEEPTIME);
    setState(() {});
  }

  Future<void> tomorrowSetting() async {
    DateTime today = DateTime.now().add(Duration(days: 1));
    String formattedDate = DateFormat('yyyy-MM-dd').format(today);
    selectedappNext = await DataStore().getSharedPreferencesString("${KeyValue().SELECTEDAPP}_$formattedDate");
    selectedDurationNext = await DataStore().getSharedPreferencesString("${KeyValue().SELECTEDDURATION}_$formattedDate");
    sleeptimeNext = await DataStore().getSharedPreferencesString("${KeyValue().SLEEPTIME}_$formattedDate");
    setState(() {});
  }
  Future<String?> sendGPT() async {
    // Messages 객체 리스트 생성
    String? text = "오류";
    String? sleepTime = await DataStore().getSharedPreferencesString(KeyValue().SLEEPTIME);
    String? appUsageLimitTime = await DataStore().getSharedPreferencesString(KeyValue().SELECTEDDURATION);
    if (sleepTime != null) {
      final Map<String, dynamic> sleepTimeMap = json.decode(sleepTime);
      int hours = sleepTimeMap['hours'];
      int minutes = sleepTimeMap['minutes'];
      sleepTime =  '$hours시 $minutes분';
    }else {
      sleepTime = '시간 정보 없음';
    }

    final Map<String, dynamic> sleepTimeMap = json.decode(appUsageLimitTime!);
    int hours = sleepTimeMap['hours'];
    int minutes = sleepTimeMap['minutes'];
    appUsageLimitTime =  '$hours시 $minutes분';

    var now = DateTime.now();
    String currentTime = DateFormat('HH시 mm분').format(now);
    //완료-----------------------------------------
    //   text = '''
    //   {
    //     "역할" : "나의 $currentApp 사용을 줄이려는 사람",
    //     "상황" : "스마트폰($currentApp) 사용시간이 너무 길어서 사용시간이 많아져서 사용을 중단하라는 알람을 줘야하는 상황",
    //     "평소 취침시간": "$sleepTime",
    //     "현재 시간": "$currentTime",
    //     "목표한 최대 스마트폰($currentApp) 사용시간" : "60분",
    //     "현재 스마트폰($currentApp) 사용시간" : "$currentAppUsageTime",
    //     "요구사항": ["상대방이 스마트폰($currentApp)사용 시간이 '$appUsageLimitTime 이 됐다고 중단해야한다'고 전해줘, 상대방이 기분이 상하지 않도록 '사용시간을 말해주면서 전달'해줘,15~20단어 정도 한글로 문장생성"]
    //   }
    //     ''';
    //
      final nonStopReason = [
        [
          "지인들의 일상생활을 실시간으로 더 보고싶다는",
          "내 일상생활을 실시간으로 더 공유하고 싶다는",
          "지금 알고리즘이 좋은 정보들을 잘 알려주고 있다는",
        ],
        [
          "알고리즘에 의해 노출되는 추천영상으로 더 큰 재미를 찾기 위해 계속 영상을 시청하게 됨",
          "대체할 수 있는 흥미로운 플랫폼이 없음",
          "프리미엄 서비스를 사용하는 입장에서 앱을 사용 안하면 돈 아까운 느낌이 듦",
        ]
      ];
      final stopReason = [
        [
          "일상의 기록을 위함인지 과시를 위함인지 생각",
          "불필요하고 단발적인 컨텐츠에 시간을 쏟지말자 생각",
          "화면속 이미 지나간일들의 기록보다 현재의 세상을 보자고 생각",
        ],
        [
          "자기전에는 최소한의 영상시청으로 늦은 시간에 잠들지 않게 함",
          "업무중 휴식시간에는 앱 사용을 줄여 일에 대한 집중력을 떨어지지 않게 함"
        ],
      ];
    // if(purposeRandomValue==0){
    //   purpose = '${stopReason[index][stopReasonRandomValue]} 이유로 $currentApp 사용을 "지금 사용을 멈추겠다"고 말하는 거야';
    // }else{
    //   purpose = '${nonStopReason[index][nonStopReasonRandomValue]}한 이유로 $currentApp 사용"조금만 더 사용"한다고 말하는 거야';
    // }
    //

    var currentApp = "카카오톡";
    var currentAppUsageTime = "60";
      text = '''
      {
        "역할" : "나를 대신해서 나인 척하는 사람.",  
        "방금 받은 알람" : "지금 스마트폰($currentApp) 사용 시간이 벌써 $currentAppUsageTime이 되었어요. 잠시 휴식을 취하는 것은 어떨까요? 좋은 휴식이 필요한 시간입니다.", 
        "평소 취침시간" : "$sleepTime",  
        "현재 시간" : "15시",  
        "목표한 최대 스마트폰($currentApp) 사용시간" : "60분",  
        "현재 스마트폰($currentApp) 사용시간" : "$currentAppUsageTime분",
        "요구사항" : 
        ["나는 '방금 받은 알람'에 대해 '좀 과한 이야기를이 나와서 사용을 그만하겠다'고 전달하려해, 20~30단어 정도 한글로 문장 생성해줘, 답변 형식은 다른 형태없이 그냥 문장만"]
      }
      ''';
    //
    // text = '''
    // {
    //   "역할" : "나의 $currentApp 사용을 줄이려는 사람",
    //   "상황" : "스마트폰($currentApp) 사용시간이 너무 길어서 졌지만 사용을 종료한 상황",
    //   "방금 받은 알람": "${await DataStore().getSharedPreferencesString(KeyValue().REPLY)}",
    //   "평소 취침시간": "$sleepTime",
    //   "현재 시간": "$currentTime",
    //   "목표 최대 스마트폰($currentApp) 사용시간": "$appUsageLimitTime",
    //   “현재 스마트폰($currentApp) 사용시간”: “$currentAppUsageTime분”,
    //   "요구사항":
    //     ["
    //       방금 받은 알람을 받고 스마트폰($currentApp) 사용을 멈췄어. 잘 했다고 격려의 말을 전달해줘,20~30단어 정도로 한글로 응답
    //     ]"
    //  }
    //   ''';
    //   text = '''
    //   {
    //     "역할" : "나를 대신해서 나인 척하는 사람.",
    //     "상황" : "알람을 받고 스마트폰($currentApp) 사용을 종료한 상황",
    //     "방금 받은 알람": "${await DataStore().getSharedPreferencesString(KeyValue().REPLY)}",
    //     "평소 취침시간": "$sleepTime",
    //     "현재 시간": "$currentTime",
    //     "목표 최대 스마트폰($currentApp) 사용시간": "$appUsageLimitTime",
    //     “현재 스마트폰($currentApp) 사용시간”: “$currentAppUsageTime분”,
    //     "요구사항":
    //       ["방금 받은 알람을 확인했다고 5단어 정도로 말하려면 뭐라고 말해야해? 한글 문장으로만 생성해줘.]"
    //    }
    //     ''';
    //
    //
    //   text = '''
    //   {
    //     "역할" : "나의 $currentApp 사용을 줄이려는 사람",
    //     "상황" : "스마트폰($currentApp) 사용시간이 너무 길어서 져서 사용을 종료하지 않은 상황",
    //     "방금 받은 알람": "${await DataStore().getSharedPreferencesString(KeyValue().REPLY)}",
    //     "평소 취침시간": "$sleepTime",
    //     "현재 시간": "$currentTime",
    //     "목표 최대 스마트폰($currentApp) 사용시간": "$appUsageLimitTime",
    //     “현재 스마트폰($currentApp) 사용시간”: “$currentAppUsageTime분”,
    //     "요구사항":
    //       ["
    //         방금 받은 알람을 받고도 아직 $currentApp 사용을 멈추지 않았어. 앱을 5분 더 초과해서 사용했으니 얼른 $currentApp사용을 멈추라고 전달해줘,20~30단어 정도로 한글로 문장생성
    //       ]"
    //    }
    //     ''';
    //   text = '''
    //   {
    //     "역할" : "나를 대신해서 나인 척하는 사람.",
    //     "상황" : "스마트폰($currentApp) 사용시간이 너무 길어서 져서 사용을 종료하지 않은 상황",
    //     "방금 받은 알람": "${await DataStore().getSharedPreferencesString(KeyValue().REPLY)}",
    //     "평소 취침시간": "$sleepTime",
    //     "현재 시간": "$currentTime",
    //     "목표 최대 스마트폰($currentApp) 사용시간": "$appUsageLimitTime",
    //     “현재 스마트폰($currentApp) 사용시간”: “$currentAppUsageTime분”,
    //     "요구사항":
    //       ["
    //         방금 받은 알람을 받고 확인했다고 5단어 정도로 할말을 추천해줘. 한글 문장으로만 출력해
    //       ]"
    //   }
    //     ''';

    final _openAI = OpenAI.instance.build(
      token: API_KEY,
      baseOption: HttpSetup(
        receiveTimeout: const Duration(
          seconds: 30,
        ),
        sendTimeout: const Duration(
          seconds: 30,
        ),
        connectTimeout: const Duration(
          seconds: 30,
        ),
      ),
      enableLog: true,
    );

    List<Messages> messagesHistory = [
      Messages(
        role: Role.user,
        content: text,
      ),
    ];
    final request = ChatCompleteText(
      model: Gpt4ChatModel(),
      messages: messagesHistory,
      maxToken: 100,
      temperature: 0.9,
    );
    final response = await _openAI.onChatCompletion(request: request);
    for (var element in response!.choices) {
      final message = element.message;
      if (message != null) {
        try {
          // 응답 메시지 출력
          String messageContent = message.content.replaceAll('"', '');
          print("Received message: $messageContent");

          return messageContent;

        } catch (e) {
          // JSON 파싱 오류 발생 시 전체 메시지를 반환합니다.
          print("Error decoding message: $e");
          return message.content;
        }
      }
    }
    return null;

  }


  var content1;
  bool check1 = false;

  void _refreshPage() {
    todaySetting();
    tomorrowSetting();
  }

  String formatDuration(String durationJson) {
    Map<String, dynamic> duration = jsonDecode(durationJson);
    return '${duration['hours']}h ${duration['minutes']}m';
  }

  List<Widget> parseUsageStats(String statsJson) {
    List<dynamic> stats = jsonDecode(statsJson);
    return stats.map((stat) {
      String appName = stat['appName'];
      String packageName = stat['packageName'];
      Map<String, dynamic> usageDuration = stat['usageDuration'];
      return ListTile(
        title: Text(appName),
        subtitle: Text(packageName),
        trailing: Text('${usageDuration['hours']}h ${usageDuration['minutes']}m'),
      );
    }).toList();
  }
  Future<void> sendAlarm(String title, String content,
      String payload, String who) async {
    LocalNotification.showOngoingNotification(
      title: "",
      body: "$title : $content",
      payload: payload,
    );
  }
  Future<void> pressButton() async {
    result = "test";
    sendAlarm("나", result!, "5",KeyValue().AGENT);
  }
  @override
  WithForegroundTask build(BuildContext context) => WithForegroundTask(
    child: Scaffold(
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            Center(),
            // Variables display
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 기존 설정 Section
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    padding: EdgeInsets.all(16.0), // Increase padding for larger size
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('기존 설정:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Divider(color: Colors.grey,),
                        if (selectedapp != null) ...parseUsageStats(selectedapp!),
                        Divider(color: Colors.grey,),
                        if (selectedDuration != null) Text('기본 제한 시간: ${formatDuration(selectedDuration!)}'),
                        if (sleeptime != null) Text('수면 시간: ${formatDuration(sleeptime!)}'),
                      ],
                    ),
                  ),
                  SizedBox(height: 2,),
                  // 변경될 설정 Section
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    padding: EdgeInsets.all(16.0), // Increase padding for larger size
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('변경될 설정:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Divider(color: Colors.grey,),
                        if (selectedappNext != null) ...parseUsageStats(selectedappNext!),
                        Divider(color: Colors.grey,),
                        if (selectedDurationNext != null) Text('기본 제한 시간: ${formatDuration(selectedDurationNext!)}'),
                        if (sleeptimeNext != null) Text('수면 시간: ${formatDuration(sleeptimeNext!)}'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            TextButton(onPressed: pressButton, child: Text(result!)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _refreshPage,
        child: Icon(Icons.refresh),
        tooltip: '페이지 새로고침',
      ),
    ),
  );

}
