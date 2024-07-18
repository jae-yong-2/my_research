import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:my_research/data/keystring.dart';
import 'package:my_research/data/data_store.dart';
import 'package:my_research/module/usageAppservice.dart';

import '../module/local_notification.dart';
import '../package/const_key.dart';
class ServerDataListener {

  //ChatGPT API사용:
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

  Future<void> feedback() async {
    var duration = 10;
    await Future.delayed(Duration(seconds: duration));

    String? feedbackContent = await DataStore().getSharedPreferencesString("${KeyValue().ISFEEDBACK}_agentContent");
    String? feedbackTime = await DataStore().getSharedPreferencesString("${KeyValue().ISFEEDBACK}_time");
    int? feedbackMillitime = await DataStore().getSharedPreferencesInt("${KeyValue().ISFEEDBACK}_millitime");
    sendAlarm("나", feedbackContent!, feedbackTime, feedbackMillitime, "5",KeyValue().AGENT);
  }
//GPT에게 원하는 내용 생성
  Future<String?> sendGPT(category, currentApp, currentAppUsageTime,appUsageLimitTime, index ) async {
    // Messages 객체 리스트 생성
    String? text = "오류";
    String? sleepTime = await DataStore().getSharedPreferencesString(KeyValue().SLEEPTIME);
    if (sleepTime != null) {
      final Map<String, dynamic> sleepTimeMap = json.decode(sleepTime);
      int hours = sleepTimeMap['hours'];
      int minutes = sleepTimeMap['minutes'];
      sleepTime =  '$hours시 $minutes분';
    } else {
      sleepTime = '시간 정보 없음';
    }

    // final Map<String, dynamic> sleepTimeMap = json.decode(appUsageLimitTime!);
    // int hours = sleepTimeMap['hours'];
    // int minutes = sleepTimeMap['minutes'];
    // appUsageLimitTime =  '$hours시 $minutes분';

    var now = DateTime.now();
    String currentTime = DateFormat('HH시 mm분').format(now);
    //완료-----------------------------------------
    if(category =="GPTFirstResponse"){
      text = '''
      {
        "역할" : "나의 $currentApp 사용을 줄이려는 사람",
        "상황" : "스마트폰($currentApp) 사용시간이 너무 길어서 사용시간이 많아져서 사용을 중단하라는 알람을 줘야하는 상황",  
        "평소 취침시간": "$sleepTime",
        "현재 시간": "$currentTime",
        "목표한 최대 스마트폰($currentApp) 사용시간" : "${(appUsageLimitTime ~/ 60)}시간 ${appUsageLimitTime % 60}분",  
        "현재 스마트폰($currentApp) 사용시간" : "${currentAppUsageTime ~/ 60}시간 ${currentAppUsageTime % 60}분",  
        "요구사항": ["상대방이 스마트폰($currentApp)사용 시간이 '${appUsageLimitTime ~/ 60}시간 ${appUsageLimitTime % 60}분이 됐다고 중단해야한다'고 전해줘, 상대방이 기분이 상하지 않도록 '사용시간을 말해주면서 전달'해줘,15~20단어 정도 Json형태 말고 한글로 존댓말 문장생성"]
      }
        ''';
    }

    if(category =="PCAFirstResponse"){
      final Random random = Random();
      final nonStopReason = KeyValue().nonStopReason;
      final stopReason = KeyValue().stopReason;
      // 0 또는 1을 랜덤으로 출력하는 변수
      int purposeRandomValue = random.nextInt(2);
      int nonStopReasonRandomValue = random.nextInt(nonStopReason.length);
      int stopReasonRandomValue = random.nextInt(stopReason.length);
      String purpose;
      //Todo 각 어플에 대한 reason, purpose 를 작성.

      if(purposeRandomValue==0){
        purpose = '${stopReason[index][stopReasonRandomValue]} 이유로 $currentApp 사용을 "지금 사용을 멈추겠다"고 말하는 거야';
      }else{
        purpose = '${nonStopReason[index][nonStopReasonRandomValue]}한 이유로 $currentApp 사용"조금만 더 사용"한다고 말하는 거야';
      }
      text = '''
      {
        "역할" : "나를 대신해서 나인 척하는 사람.",  
        "방금 받은 알람" : "${await DataStore().getSharedPreferencesString(KeyValue().REPLY)}", 
        "평소 취침시간" : "$sleepTime",  
        "현재 시간" : "$currentTime",  
        "목표한 최대 스마트폰($currentApp) 사용시간" : "$appUsageLimitTime분",  
        "현재 스마트폰($currentApp) 사용시간" : "$currentAppUsageTime분",  
        "요구사항" : 
        ["나는 '방금 받은 알람'에 답장하려 해, 내용은 $purpose. 20~30단어 정도 Json형태 말고 한글 반말로 문장 생성"]
      }
      ''';
    }
    if(category =="GPTAcceptResponse"){
      text = '''
      {
        "역할" : "나의 $currentApp 사용을 줄이려는 사람",
        "상황" : "스마트폰($currentApp) 사용시간이 너무 길어서 졌지만 사용을 종료한 상황",
        "방금 내가 한 말": "${await DataStore().getSharedPreferencesString(KeyValue().REPLY)}",
        "평소 취침시간": "$sleepTime",
        "현재 시간": "$currentTime",
        "목표 최대 스마트폰($currentApp) 사용시간": "$appUsageLimitTime",
        “현재 스마트폰($currentApp) 사용시간”: “$currentAppUsageTime분”,
        "요구사항": 
          ["
            $currentApp 사용을 그만뒀는데. '(방금 내가 한 말)'의 내용을 넣어서 그 앱의 사용을 잘 중단했다고 전달해줘,20~30단어 정도로 Json형태 말고 한글 존댓말로 응답
          ]"
       }
        ''';
    }
    if(category =="PCAAcceptResponse"){
      text = '''
      {
        "역할" : "나를 대신해서 나인 척하는 사람.",
        "상황" : "알람을 받고 스마트폰($currentApp) 사용을 종료한 상황",
        "방금 받은 알람": "${await DataStore().getSharedPreferencesString(KeyValue().REPLY)}",
        "평소 취침시간": "$sleepTime",
        "현재 시간": "$currentTime",
        "목표 최대 스마트폰($currentApp) 사용시간": "$appUsageLimitTime",
        “현재 스마트폰($currentApp) 사용시간”: “$currentAppUsageTime분”,
        "요구사항": 
          ["방금 받은 알람을 확인했다고 하는 말을 전달해줘. 5~10단어 정도로 Json형태 말고 한글 반말로 문장으로만 생성해줘.]"
       }
        ''';
    }


    if(category =="GPTRejectResponse"){
      text = '''
      {
        "역할" : "나의 $currentApp 사용을 줄이려는 사람",
        "상황" : "스마트폰($currentApp) 사용시간이 너무 길어서 져서 사용을 종료하지 않은 상황",
        "방금 받은 알람": "${await DataStore().getSharedPreferencesString(KeyValue().REPLY)}",
        "평소 취침시간": "$sleepTime",
        "현재 시간": "$currentTime",
        "목표 최대 스마트폰($currentApp) 사용시간": "$appUsageLimitTime",
        “현재 스마트폰($currentApp) 사용시간”: “$currentAppUsageTime분”,
        "요구사항": 
          ["
            방금 받은 알람을 받고도 아직 $currentApp 사용을 멈추지 않았어. 앱을 $currentAppUsageTime 사용했으니 얼른 $currentApp사용을 멈추라고 전달해줘,20~30단어 정도로 Json형태 말고 한글 존댓말로 문장생성
          ]"
       }
        ''';
    }
    if(category =="PCARejectResponse"){
      text = '''
      {
        "역할" : "나를 대신해서 나인 척하는 사람.",
        "상황" : "스마트폰($currentApp) 사용시간이 너무 길어서 져서 사용을 종료하지 않은 상황",
        "방금 받은 알람": "${await DataStore().getSharedPreferencesString(KeyValue().REPLY)}",
        "평소 취침시간": "$sleepTime",
        "현재 시간": "$currentTime",
        "목표 최대 스마트폰($currentApp) 사용시간": "$appUsageLimitTime",
        “현재 스마트폰($currentApp) 사용시간”: “$currentAppUsageTime분”,
        "요구사항": 
          ["
            방금 받은 알람을 받고 확인했다고 5단어 정도로 할말을 반말로 추천해줘. Json형태 말고 문장만 출력해줘.
          ]"
      }
        ''';
    }



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
          return "시스템에 문제가 있습니다.";
        }
      }
    }
    return null;

  }

  Future<void> sendAlarm(String title, String content, var time, var millitime,
      String payload, String who) async {
    LocalNotification.showOngoingNotification(
      title: (payload=="5"||payload=="6")?"피드백을 해주세요.":"",
      body: "$title : $content",
      payload: payload,
    );
    //히스토리에 저장
    await DataStore().saveData(KeyValue().ID, '${KeyValue().Chat}/$time', {
      KeyValue().CHAT_ID: who,
      KeyValue().CONTENT: content,
      KeyValue().TIMESTAMP: time,
      KeyValue().MILLITIMESTAMP: millitime,
    });
  }
  bool containsPackageName(List<dynamic> jsonData, String packageName) {
    // jsonData 리스트를 순회하면서 packageName이 일치하는 항목이 있는지 확인
    return jsonData.any((element) => element['packageName'] == packageName);
  }

  int? getAppUsageLimitTime(List<dynamic> jsonData , String packageName) {
    try {
      var data = jsonData.firstWhere((app) => app['packageName'] == packageName, orElse: () => null);
      data = data['usageDuration'];
      var selectedDuration = Duration(
          hours: data['hours'],
          minutes: data['minutes']);
      return selectedDuration.inMinutes;
    } catch (e) {
      return null;
    }
  }

  int getIndexForPackageName(List<dynamic> appUsageData, String packageName) {
    for (int i = 0; i < appUsageData.length; i++) {
      if (appUsageData[i]['packageName'] == packageName) {
        return i;
      }
    }
    // 패키지를 찾지 못한 경우 -1 반환
    return -1;
  }


  //FCM을 통해서 받은 데이터를 휴대폰에서 처리하는 함수.
  Future<void> FCMactivce(Map<String, dynamic> data) async {
    // 네이티브 코드 호출
    print("Flutter FCM");
    String? oldCurrentApp = await DataStore().getSharedPreferencesString(KeyValue().CURRENTAPP);
    String? oldCurrentAppName = await DataStore().getSharedPreferencesString(KeyValue().CURRENTAPPNAME);
    int? oldAppUsageTime = await DataStore().getSharedPreferencesInt(KeyValue().APPUSAGETIME);
    int? timer;

    print("get selected app : ${await DataStore().getSharedPreferencesString(KeyValue().SELECTEDAPP)}");


    var now = DateTime.now();
    var millitime = DateTime
        .now()
        .millisecondsSinceEpoch;
    var formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    String time = formatter.format(now);

    String? currentApp = data['currentApp'];
    if (currentApp != null) {
      await DataStore().saveSharedPreferencesString(KeyValue().CURRENTAPP, currentApp);
    } else {
      print("currentApp가 null입니다");
      return;
    }

    String? currentAppName = data['currentAppName'];
    if (currentAppName != null) {
      await DataStore().saveSharedPreferencesString(KeyValue().CURRENTAPPNAME, currentAppName);
    } else {
      print("currentAppName이 null입니다");
      return;
    }

    int? currentAppUsageTime = data['appUsageTime'];
    if (currentAppUsageTime != null) {
      await DataStore().saveSharedPreferencesInt(KeyValue().APPUSAGETIME, currentAppUsageTime);
    } else {
      print("appUsageTime이 null입니다");
      return;
    }

    List<dynamic> usageStats = data['usageStats'];
    bool isLock = data['lock'];

    print("--------------received data--------------");
    print("App Usage State : $usageStats");
    print("isLock : $isLock");
    print("-----------------------------------------");

    now = DateTime.now();
    formatter = DateFormat('yyyy-MM-dd');
    time = formatter.format(now);
    
    String formattedTime = DateFormat('HH:mm').format(now);

    //하루가 끝나기 전에 스마트폰의 사용 시간을 전체적으로 저장한다.
    if ((formattedTime.compareTo("22:30") >= 0 && formattedTime.compareTo("23:59") <= 0)) {
      await DataStore().saveData(KeyValue().ID, "${KeyValue().APPUSAGETIME}/$time",
          {'usageStats' :usageStats});
    }

    //다음날이 되면 어제 저장했던 값을 업데이트
    if ((formattedTime.compareTo("00:00") >= 0 ) && (formattedTime.compareTo("00:10") <= 0 )) {

      DateTime today = DateTime.now();
      String formattedDate = DateFormat('yyyy-MM-dd').format(today);

      String? selectedapp = await DataStore().getSharedPreferencesString("${KeyValue().SELECTEDAPP}_$formattedDate");
      String? selectedDuration = await DataStore().getSharedPreferencesString("${KeyValue().SELECTEDDURATION}_$formattedDate");
      String? sleeptime = await DataStore().getSharedPreferencesString("${KeyValue().SLEEPTIME}_$formattedDate");

      if(selectedapp != null && selectedDuration!= null && sleeptime!=null) {
        await DataStore().saveSharedPreferencesString(KeyValue().SELECTEDAPP, selectedapp!);
        await DataStore().saveSharedPreferencesString(KeyValue().SELECTEDDURATION, selectedDuration!);
        await DataStore().saveSharedPreferencesString(KeyValue().SLEEPTIME, sleeptime!);
      }
    }

    String? selectedApp = await DataStore().getSharedPreferencesString(KeyValue().SELECTEDAPP);
    List<dynamic> selectedAppJson = jsonDecode(selectedApp!);
    //현재 실행 중인 앱이 선택된 앱 중에 포함이 될때 true 반환
    bool hasPackage = containsPackageName(selectedAppJson, currentApp);
    var currentAppUsageLimitTime = getAppUsageLimitTime(selectedAppJson,currentApp);
    //선택된 앱( 유튜브 or 다른 앱 )이 현재 실행 중인 앱이고, 계속 실행 중이었으면 알고리즘 실행
    if (oldCurrentApp == currentApp && hasPackage) {
      try {
        //현재 앱이 계속 실행중이었으면 시간(1분에 한번씩) +1하여 timer에 저장함.
        Map<String, dynamic>? data = await DataStore().getData(KeyValue().ID,"timer/$currentAppName/$time");
        if (data ==null){
          timer = 1;
        }else{
          timer = data?["time"] + 1;
        }
        if(isLock) {
          timer = data?["time"];
        }
        //timer를 업데이트함.
        if (data != null) {
          timer = timer!<currentAppUsageTime?currentAppUsageTime:timer;
          await DataStore().saveData(KeyValue().ID,"timer/$currentAppName/$time",{"time": timer});
        } else {
          print("No data found at the path: ${KeyValue().ID}/timer/$currentAppName/$time");
        }
        if(data == null){
          await DataStore().saveData(KeyValue().ID,"timer/$currentAppName/$time",{"time":currentAppUsageTime});
        }

      }catch(error){
        await DataStore().saveData(KeyValue().ID,"timer/$currentAppName/$time",{"time":currentAppUsageTime});
        print(error);
      }
      timer ??= 0;
    } else {
      await DataStore().saveSharedPreferencesInt(KeyValue().TIMER, 0);
    }

    String? gptContent = "key가 없거나 오류가 났습니다.";
    String? agentContent = "key가 없거나 오류가 났습니다.";
    now = DateTime.now();
    formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    time = formatter.format(now);
    var duration = 10;
    final String? selectedDurationJson = await DataStore()
        .getSharedPreferencesString(KeyValue().SELECTEDDURATION);

    if (selectedDurationJson != null) {
      try {
        final Map<String, dynamic> selectedDurationMap = json.decode(selectedDurationJson);
        if (selectedDurationMap.containsKey('hours') && selectedDurationMap.containsKey('minutes')) {
          var selectedDuration = Duration(
              hours: selectedDurationMap['hours'],
              minutes: selectedDurationMap['minutes']);
          final int savedMinutes;
          if(currentAppUsageLimitTime!=null &&currentAppUsageLimitTime>0) {
            savedMinutes = currentAppUsageLimitTime;
          }else{
            savedMinutes = selectedDuration.inMinutes;
          }
          bool? checker = await DataStore().getSharedPreferencesBool("${KeyValue().ALARM_CHECKER}_${currentAppName}_");
          if(checker==null) {
            await DataStore().saveSharedPreferencesBool("${KeyValue().ALARM_CHECKER}_${currentAppName}_", false);
          }
          bool? firstchecker = await DataStore().getSharedPreferencesBool("${KeyValue().ALARM_CHECKER}_$currentAppName");
          if(firstchecker==null) {
            await DataStore().saveSharedPreferencesBool("${KeyValue().ALARM_CHECKER}_$currentAppName", false);
          }

          checker = await DataStore().getSharedPreferencesBool("${KeyValue().ALARM_CHECKER}_${currentAppName}_");
          firstchecker = await DataStore().getSharedPreferencesBool("${KeyValue().ALARM_CHECKER}_$currentAppName");


          //현재 실행중인 앱이 사용을 중지하고 싶은 앱리스트의 몇번째 앱리스트인지 출력해줌.
          int index = getIndexForPackageName(selectedAppJson,currentApp);
/**
 *
 *
 *  집단 2
 *
 *
 *
 * */
          bool? mode = await DataStore().getSharedPreferencesBool(KeyValue().MODE);
          mode??=false;
          if(mode==true){
            //알람을 받고 사용을 종료했을때 대답
            checker = await DataStore().getSharedPreferencesBool("${KeyValue().ALARM_CHECKER}_${oldCurrentAppName}_");
            firstchecker = await DataStore().getSharedPreferencesBool("${KeyValue().ALARM_CHECKER}_$oldCurrentAppName");
            print("old app name : $oldCurrentAppName");
            print("old checker : $checker");
            print("old firstchecker : $firstchecker");
            /**
             *
             *
             * 알람을 보고 바로 앱을 종료하는 경우
             *
             *
             */
            if ((oldCurrentApp != currentApp) && checker! && firstchecker!) {
              print("알람을 보고 앱을 종료했습니다.");
              await DataStore().saveSharedPreferencesBool("${KeyValue().ALARM_CHECKER}_${oldCurrentAppName}_", false);

              now = DateTime.now();
              millitime = DateTime.now().millisecondsSinceEpoch;
              formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
              time = formatter.format(now);
              gptContent = await sendGPT("GPTAcceptResponse", oldCurrentAppName, timer, savedMinutes, index);
              // gptContent = "test3 알람보고 앱 종료함";
              await DataStore().saveSharedPreferencesString(KeyValue().REPLY, gptContent!);
              // gptContent = "GPT2 사용 종료하셨군요!";
              sendAlarm("Agent", gptContent!, time, millitime, "3", KeyValue().GPT);

              await Future.delayed(Duration(seconds: duration));
              //PCA의 응답
              now = DateTime.now();
              millitime = DateTime.now().millisecondsSinceEpoch;
              formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
              time = formatter.format(now);

              agentContent = await sendGPT("PCAAcceptResponse", oldCurrentAppName, timer, savedMinutes, index);
              // agentContent="test4 알람보고 앱 종료함";
              await DataStore().saveSharedPreferencesString(KeyValue().REPLY, agentContent!);

              // agentContent = "넹 껐어요";
              sendAlarm("나", agentContent!, time, millitime, "4", KeyValue().AGENT);
              // feedback();
            }

            checker = await DataStore().getSharedPreferencesBool("${KeyValue().ALARM_CHECKER}_${currentAppName}_");
            firstchecker = await DataStore().getSharedPreferencesBool("${KeyValue().ALARM_CHECKER}_$currentAppName");
            print("-----------------------------------------");
            print("current app name : $currentAppName");
            print("current checker : $checker");
            print("current firstchecker : $firstchecker");

            /**
             * 알람이 울리고 사용중인 앱을 중단하고 다른 앱을 사용하게 될 경우
             */
            String? overtimeapp = await DataStore().getSharedPreferencesString(KeyValue().OVERTIMEAPP);
            if(overtimeapp!=null && overtimeapp!="none" && currentAppName!=overtimeapp && currentAppName !="my_research"){
              now = DateTime.now();
              formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
              time = formatter.format(now);

              //히스토리에 저장
              String? alarmTime = await DataStore().getSharedPreferencesString("${KeyValue().OVERTIMEAPP}_time");

              await DataStore().saveData(KeyValue().ID, 'stop_after_alarm/$time', {
                "alarm_time": alarmTime,
              });
              await DataStore().saveSharedPreferencesString(KeyValue().OVERTIMEAPP, "none");
            }
            /**
             *
             *
             * 알람이 울린 후에 알람이 울린 과정을 초기화 하는 알고리즘
             *
             *
             */
            if (((savedMinutes * 2 > timer!) && (savedMinutes + 6 <= timer!) && firstchecker!) ||
                ((savedMinutes * 2 + 6 <= timer) && firstchecker!)) {
              print("알람 설정 초기화");
              await DataStore().saveSharedPreferencesBool("${KeyValue().ALARM_CHECKER}_$currentAppName", false);
              await DataStore().saveSharedPreferencesBool("${KeyValue().ALARM_CHECKER}_${currentAppName}_", false);
              await DataStore().saveSharedPreferencesInt("${KeyValue().OVERTIMEAPP}_timer", 0);
            }



            /**
             *
             *
             * n분 이상 사용했을때 알람.
             *
             *
             */
            print("-----------------------------------------");
            print("$currentAppName 사용 시간 : $timer");
            print("$currentAppName 제한 시간 : $savedMinutes");
            print("사용시간 초과 앱 : $overtimeapp");
            print("-----------------------------------------");
            if (((savedMinutes + 5 >= timer!) && (timer >= savedMinutes) && !checker! && !firstchecker!) ||
                ((savedMinutes * 2 + 5 >= timer!) && (timer >= savedMinutes * 2) && !checker! && !firstchecker!)) {
              await DataStore().saveSharedPreferencesBool("${KeyValue().ALARM_CHECKER}_${currentAppName}_", true);
              await DataStore().saveSharedPreferencesBool("${KeyValue().ALARM_CHECKER}_$currentAppName", true);
              await DataStore().saveSharedPreferencesString(KeyValue().OVERTIMEAPP, currentAppName);
              await DataStore().saveSharedPreferencesInt("${KeyValue().OVERTIMEAPP}_timer", 0);
              //사용을 종료하라는 agent의 메세지
              print("최대 사용시간이 되었습니다.");
              now = DateTime.now();
              millitime = DateTime.now().millisecondsSinceEpoch;
              formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
              time = formatter.format(now);
              //앱을 종료했을때 시간
              await DataStore().saveSharedPreferencesString("${KeyValue().OVERTIMEAPP}_time", time);


              gptContent = await sendGPT("GPTFirstResponse", currentAppName, timer, savedMinutes, index);
              // gptContent = "test1 알람옴";
              await DataStore().saveSharedPreferencesString(KeyValue().REPLY, gptContent!);

              // gptContent = "$currentAppName 끄쇼";
              sendAlarm("Agent", gptContent!, time, millitime, "1", KeyValue().GPT);

              await Future.delayed(Duration(seconds: duration));
              //PCA의 응답
              now = DateTime.now();
              millitime = DateTime.now().millisecondsSinceEpoch;
              formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
              time = formatter.format(now);

              agentContent = await sendGPT("PCAFirstResponse", currentAppName, timer, savedMinutes, index);
              // agentContent="$currentAppName 의도 목적";
              await DataStore().saveSharedPreferencesString(KeyValue().REPLY, agentContent!);

              await DataStore().saveSharedPreferencesString("${KeyValue().ISFEEDBACK}_agentContent", agentContent);
              await DataStore().saveSharedPreferencesString("${KeyValue().ISFEEDBACK}_time", time);
              await DataStore().saveSharedPreferencesInt("${KeyValue().ISFEEDBACK}_millitime", millitime);
              // agentContent = "끌겨";
              sendAlarm("나", agentContent!, time, millitime, "2", KeyValue().AGENT);

              print("현재 앱 사용시간이 설정된 시간을 초과했습니다. $timer $savedMinutes");

              /**
               *
               * 초기화가 안됐을 경우 알람
               *
               */
            } else if ((timer == (savedMinutes + 13) && (checker != firstchecker)) ||
                (timer == (savedMinutes * 2 + 13) && (checker != firstchecker))) {
              LocalNotification.showOngoingNotification(
                title: "시스템에 오류가 있습니다.",
                body: "프로필에서 새로고침을 눌러주세요.",
                payload: "8",
              );
              /**
               *
               * n분 이상 사용했으면서 알람을 받고도 종료하지 않으면 알람.
               *
               */
            } else if ((timer == (savedMinutes + 5) && checker!) ||
                (timer == (savedMinutes * 2 + 5) && checker!)) {

              await DataStore().saveSharedPreferencesBool("${KeyValue().ALARM_CHECKER}_${currentAppName}_", false);
              await DataStore().saveSharedPreferencesBool("${KeyValue().ALARM_CHECKER}_$currentAppName", false);
              if (oldCurrentApp == currentApp && hasPackage) {
                now = DateTime.now();
                millitime = DateTime.now().millisecondsSinceEpoch;
                formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
                time = formatter.format(now);
                gptContent = await sendGPT("GPTRejectResponse", currentAppName, timer, savedMinutes, index);
                // gptContent="test3 알람보고 종료 안함";
                await DataStore().saveSharedPreferencesString(KeyValue().REPLY, gptContent!);
                // gptContent = "GPT2 사용 종료 하세요!";
                sendAlarm("Agent", gptContent!, time, millitime, "3", KeyValue().GPT);

                await Future.delayed(Duration(seconds: duration));
                //PCA의 응답
                now = DateTime.now();
                millitime = DateTime.now().millisecondsSinceEpoch;
                formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
                time = formatter.format(now);

                agentContent = await sendGPT("PCARejectResponse", currentAppName, timer, savedMinutes, index);
                // agentContent="test4 알람보고 종료 안함";
                await DataStore().saveSharedPreferencesString(KeyValue().REPLY, agentContent!);

                // agentContent = "아예~";
                sendAlarm("나", agentContent!, time, millitime, "4", KeyValue().AGENT);
                // feedback();
              }
            } else {
              print("아무런 작동을 하지 않습니다.");
            }
          }
/**
*
*
*
* 집단1
*
*
* **/
          else if(mode==false){
            //알람을 받고 사용을 종료했을때 대답
//알람을 받고 사용을 종료했을때 대답
            checker = await DataStore().getSharedPreferencesBool("${KeyValue().ALARM_CHECKER}_${oldCurrentAppName}_");
            firstchecker = await DataStore().getSharedPreferencesBool("${KeyValue().ALARM_CHECKER}_$oldCurrentAppName");
            print("old app name : $oldCurrentAppName");
            print("old checker : $checker");
            print("old firstchecker : $firstchecker");
            /**
             *
             *
             * 알람을 보고 바로 앱을 종료하는 경우
             *
             *
             */
            if ((oldCurrentApp != currentApp) && checker! && firstchecker!) {
              print("알람을 보고 앱을 종료했습니다.");
              await DataStore().saveSharedPreferencesBool("${KeyValue().ALARM_CHECKER}_${oldCurrentAppName}_", false);

              now = DateTime.now();
              millitime = DateTime.now().millisecondsSinceEpoch;
              formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
              time = formatter.format(now);
              gptContent = await sendGPT("GPTAcceptResponse", oldCurrentAppName, timer, savedMinutes, index);
              // gptContent = "test3 알람보고 앱 종료함";
              await DataStore().saveSharedPreferencesString(KeyValue().REPLY, gptContent!);
              // gptContent = "GPT2 사용 종료하셨군요!";
              sendAlarm("Agent", gptContent!, time, millitime, "3", KeyValue().GPT);

            }

            checker = await DataStore().getSharedPreferencesBool("${KeyValue().ALARM_CHECKER}_${currentAppName}_");
            firstchecker = await DataStore().getSharedPreferencesBool("${KeyValue().ALARM_CHECKER}_$currentAppName");
            print("-----------------------------------------");
            print("current app name : $currentAppName");
            print("current checker : $checker");
            print("current firstchecker : $firstchecker");

            /**
             * 알람이 울리고 사용중인 앱을 중단하고 다른 앱을 사용하게 될 경우
             */
            String? overtimeapp = await DataStore().getSharedPreferencesString(KeyValue().OVERTIMEAPP);

            if(overtimeapp!=null && overtimeapp!="none" && currentAppName!=overtimeapp && currentAppName !="my_research"){
              now = DateTime.now();
              formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
              time = formatter.format(now);

              //히스토리에 저장
              String? alarmTime = await DataStore().getSharedPreferencesString("${KeyValue().OVERTIMEAPP}_time");
              await DataStore().saveData(KeyValue().ID, 'stop_after_alarm/$time', {
                "alarm_time": alarmTime,
              });
              await DataStore().saveSharedPreferencesString(KeyValue().OVERTIMEAPP, "none");
            }

            /**
             *
             *
             * 알람이 울린 후에 알람이 울린 과정을 초기화 하는 알고리즘
             *
             *
             */
            if (((savedMinutes * 2 > timer!) && (savedMinutes + 6 <= timer!) && firstchecker!) ||
                ((savedMinutes * 2 + 6 <= timer) && firstchecker!)) {
              print("알람 설정 초기화");
              await DataStore().saveSharedPreferencesBool("${KeyValue().ALARM_CHECKER}_$currentAppName", false);
              await DataStore().saveSharedPreferencesBool("${KeyValue().ALARM_CHECKER}_${currentAppName}_", false);
              await DataStore().saveSharedPreferencesInt("${KeyValue().OVERTIMEAPP}_timer", 0);
            }



            /**
             *
             *
             * n분 이상 사용했을때 알람.
             *
             *
             */
            print("-----------------------------------------");
            print("$currentAppName 사용 시간 : $timer");
            print("$currentAppName 제한 시간 : $savedMinutes");
            print("사용시간 초과 앱 : $overtimeapp");
            print("-----------------------------------------");
            if (((savedMinutes + 5 >= timer!) && (timer >= savedMinutes) && !checker! && !firstchecker!) ||
                ((savedMinutes * 2 + 5 >= timer!) && (timer >= savedMinutes * 2) && !checker! && !firstchecker!)) {
              await DataStore().saveSharedPreferencesBool("${KeyValue().ALARM_CHECKER}_${currentAppName}_", true);
              await DataStore().saveSharedPreferencesBool("${KeyValue().ALARM_CHECKER}_$currentAppName", true);
              await DataStore().saveSharedPreferencesString(KeyValue().OVERTIMEAPP, currentAppName);
              await DataStore().saveSharedPreferencesInt("${KeyValue().OVERTIMEAPP}_timer", 0);
              //사용을 종료하라는 agent의 메세지
              print("최대 사용시간이 되었습니다.");
              now = DateTime.now();
              millitime = DateTime.now().millisecondsSinceEpoch;
              formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
              time = formatter.format(now);
              //앱을 종료했을때 시간
              await DataStore().saveSharedPreferencesString("${KeyValue().OVERTIMEAPP}_time", time);


              gptContent = await sendGPT("GPTFirstResponse", currentAppName, timer, savedMinutes, index);
              // gptContent = "test1 알람옴";
              await DataStore().saveSharedPreferencesString(KeyValue().REPLY, gptContent!);

              // gptContent = "$currentAppName 끄쇼";
              sendAlarm("Agent", gptContent!, time, millitime, "1", KeyValue().GPT);

              print("현재 앱 사용시간이 설정된 시간을 초과했습니다. $timer $savedMinutes");

              /**
               *
               * 초기화가 안됐을 경우 알람
               *
               */
            } else if ((timer == (savedMinutes + 13) && (checker != firstchecker)) ||
                (timer == (savedMinutes * 2 + 13) && (checker != firstchecker))) {
              LocalNotification.showOngoingNotification(
                title: "시스템에 오류가 있습니다.",
                body: "프로필에서 새로고침을 눌러주세요.",
                payload: "8",
              );
              /**
               *
               * n분 이상 사용했으면서 알람을 받고도 종료하지 않으면 알람.
               *
               */
            } else if ((timer == (savedMinutes + 5) && checker!) ||
                (timer == (savedMinutes * 2 + 5) && checker!)) {

              await DataStore().saveSharedPreferencesBool("${KeyValue().ALARM_CHECKER}_${currentAppName}_", false);
              await DataStore().saveSharedPreferencesBool("${KeyValue().ALARM_CHECKER}_$currentAppName", false);
              if (oldCurrentApp == currentApp && hasPackage) {
                now = DateTime.now();
                millitime = DateTime.now().millisecondsSinceEpoch;
                formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
                time = formatter.format(now);
                gptContent = await sendGPT("GPTRejectResponse", currentAppName, timer, savedMinutes, index);
                // gptContent="test3 알람보고 종료 안함";
                await DataStore().saveSharedPreferencesString(KeyValue().REPLY, gptContent!);
                // gptContent = "GPT2 사용 종료 하세요!";
                sendAlarm("Agent", gptContent!, time, millitime, "3", KeyValue().GPT);

              }
            } else {
              print("아무런 작동을 하지 않습니다.");
            }
          }
        } else {
          print("selectedDurationMap에 'hours' 또는 'minutes' 키가 없습니다.");
        }
      } catch (e) {
        print("JSON 파싱 중 오류 발생: $e");
      }
    } else {
      print("selectedDurationJson이 null입니다.");
    }
  }
}
