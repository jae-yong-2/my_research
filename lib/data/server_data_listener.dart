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
import 'package:native_shared_preferences/native_shared_preferences.dart';

import '../module/local_notification.dart';
import '../package/const_key.dart';
class ServerDataListener {

  //ChatGPT API사용
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

//GPT에게 원하는 내용 생성
  Future<String?> sendGPT(category, currentApp, currentAppUsageTime) async {
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
    if(category =="GPTFirstResponse"){
      text = '''
      {
        "역할" : "나의 $currentApp 사용을 줄이려는 사람",
        "상황" : "스마트폰($currentApp) 사용시간이 너무 길어서 사용시간이 많아져서 사용을 중단하라는 알람을 줘야하는 상황",  
        "평소 취침시간": "$sleepTime",
        "현재 시간": "$currentTime",
        "목표한 최대 스마트폰($currentApp) 사용시간" : "$appUsageLimitTime",  
        "현재 스마트폰($currentApp) 사용시간" : "$currentAppUsageTime",  
        "요구사항": ["상대방이 스마트폰($currentApp)사용 시간이 '$appUsageLimitTime 이 됐다고 중단해야한다'고 전해줘, 상대방이 기분이 상하지 않도록 '사용시간을 말해주면서 전달'해줘,15~20단어 정도 한글로 문장생성"]
      }
        ''';
    }

    if(category =="PCAFirstResponse"){
      final Random random = Random();
      final nonStopReason = [
        "지인들의 일상생활을 실시간으로 더 보고싶다는",
        "내 일상생활을 실시간으로 더 공유하고 싶다는",
        "지금 알고리즘이 좋은 정보들을 잘 알려주고 있다는",
      ];
      final stopReason = [
        "일상의 기록을 위함인지 과시를 위함인지 생각",
        "불필요하고 단발적인 컨텐츠에 시간을 쏟지말자 생각",
        "화면속 이미 지나간일들의 기록보다 현재의 세상을 보자고 생각",
      ];
      // 0 또는 1을 랜덤으로 출력하는 변수
      int purposeRandomValue = random.nextInt(2);
      int nonStopReasonRandomValue = random.nextInt(nonStopReason.length);
      int stopReasonRandomValue = random.nextInt(stopReason.length);
      String purpose;
      //Todo 각 어플에 대한 reason, purpose 를 작성.

      if(purposeRandomValue==0){
        purpose = '${stopReason[stopReasonRandomValue]} 이유로 $currentApp 사용을 "지금 사용을 멈추겠다"고 말하는 거야';
      }else{
        purpose = '${nonStopReason[nonStopReasonRandomValue]}한 이유로 $currentApp 사용"조금만 더 사용"한다고 말하는 거야';
      }
      text = '''
      {
        "역할" : "나를 대신해서 나인 척하는 사람.",  
        "방금 받은 알람" : "${await DataStore().getSharedPreferencesString(KeyValue().REPLY)}", 
        "평소 취침시간" : "$sleepTime",  
        "현재 시간" : "$currentTime",  
        "목표한 최대 스마트폰($currentApp) 사용시간" : "$appUsageLimitTime",  
        "현재 스마트폰($currentApp) 사용시간" : "$currentAppUsageTime분",  
        "요구사항" : 
        ["나는 '방금 받은 알람'에 답장하려 해, 내용은 $purpose. 20~30단어 정도 한글로 문장 생성"]
      }
      ''';
    }
    if(category =="GPTAcceptResponse"){
      text = '''
      {
        "역할" : "나의 $currentApp 사용을 줄이려는 사람",
        "상황" : "스마트폰($currentApp) 사용시간이 너무 길어서 졌지만 사용을 종료한 상황",
        "방금 받은 알람": "${await DataStore().getSharedPreferencesString(KeyValue().REPLY)}",
        "평소 취침시간": "$sleepTime",
        "현재 시간": "$currentTime",
        "목표 최대 스마트폰($currentApp) 사용시간": "$appUsageLimitTime",
        “현재 스마트폰($currentApp) 사용시간”: “$currentAppUsageTime분”,
        "요구사항": 
          ["
            방금 받은 알람을 받고 스마트폰($currentApp) 사용을 멈췄어. 잘 했다고 격려의 말을 전달해줘,20~30단어 정도로 한글로 응답
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
          ["방금 받은 알람을 확인했다고 5단어 정도로 말하려면 뭐라고 말해야해? 한글 문장으로만 생성해줘.]"
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
            방금 받은 알람을 받고도 아직 $currentApp 사용을 멈추지 않았어. 앱을 5분 더 초과해서 사용했으니 얼른 $currentApp사용을 멈추라고 전달해줘,20~30단어 정도로 한글로 문장생성
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
            방금 받은 알람을 받고 확인했다고 5단어 정도로 할말을 추천해줘. 한글 문장으로만 출력해
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
          return message.content;
        }
      }
    }
    return null;

  }

  Future<void> sendAlarm(String title, String content, var time, var millitime,
      String payload, String who) async {
    LocalNotification.showOngoingNotification(
      title: "",
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
  //FCM을 통해서 받은 데이터를 휴대폰에서 처리하는 함수.
  Future<void> FCMactivce(Map<String, dynamic> data) async {
    // 네이티브 코드 호출
    print("Flutter FCM");
    String? oldCurrentApp = await DataStore().getSharedPreferencesString(KeyValue().CURRENTAPP);
    String? oldCurrentAppName = await DataStore().getSharedPreferencesString(KeyValue().CURRENTAPPNAME);
    int? oldAppUsageTime = await DataStore().getSharedPreferencesInt(KeyValue().APPUSAGETIME);
    int? timer;

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

    print("--------------received data--------------");
    print("Current App: $currentApp");
    print("Current App Name: $currentAppName");
    print("App Usage Time: $currentAppUsageTime minutes");
    print("App Usage State: $usageStats");
    print("-----------------------------------------");

    now = DateTime.now();
    formatter = DateFormat('yyyy-MM-dd');
    time = formatter.format(now);
    
    String formattedTime = DateFormat('HH:mm').format(now);

    //하루가 끝나기 전에 스마트폰의 사용 시간을 전체적으로 저장한다.
    if ((formattedTime.compareTo("22:30") >= 0 && formattedTime.compareTo("23:59") <= 0) || formattedTime == "00:00") {
      await DataStore().saveData(KeyValue().ID, "${KeyValue().APPUSAGETIME}/$time",
          {'usageStats' :usageStats});
    }

    String? selectedApp = await DataStore().getSharedPreferencesString(KeyValue().SELECTEDAPP);
    List<dynamic> jsonData = jsonDecode(selectedApp!);
    //현재 실행 중인 앱이 선택된 앱 중에 포함이 될때 true 반환
    bool hasPackage = containsPackageName(jsonData, currentApp);

    //선택된 앱( 유튜브 or 다른 앱 )이 현재 실행 중인 앱이고, 계속 실행 중이었으면 알고리즘 실행
    if (oldCurrentApp == currentApp && hasPackage) {

      try {
        //현재 앱이 계속 실행중이었으면 시간(1분에 한번씩) +1하여 timer에 저장함.
        Map<String, dynamic>? data = await DataStore().getData(KeyValue().ID,"timer/$currentAppName/$time");
        timer = data?["time"]+1;

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
      print("----------------------timer : $timer");
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
          final int savedMinutes = selectedDuration.inMinutes;
          bool? checker = await DataStore().getSharedPreferencesBool(KeyValue().ALARM_CHECKER);
          checker ??= false;
          print('checker : $checker');
          print('oldCurrentApp : $oldCurrentApp');
          print('currentApp : $currentApp');

          //알람을 받고 사용을 종료했을때 대답
          if(oldCurrentApp != currentApp &&checker) {
            await DataStore().saveSharedPreferencesBool(KeyValue().ALARM_CHECKER,false);

            now = DateTime.now();
            millitime = DateTime
                .now()
                .millisecondsSinceEpoch;
            formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
            time = formatter.format(now);
            gptContent = await sendGPT("GPTAcceptResponse",oldCurrentAppName,timer);
            await DataStore().saveSharedPreferencesString(KeyValue().REPLY,gptContent!);
            // gptContent = "GPT2 사용 종료하셨군요!";
            sendAlarm(
                "Agent ", gptContent!, time, millitime,
                "1",KeyValue().GPT);


            await Future.delayed(Duration(seconds: duration));
            //PCA의 응답
            now = DateTime.now();
            millitime = DateTime
                .now()
                .millisecondsSinceEpoch;
            formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
            time = formatter.format(now);

            agentContent = await sendGPT("PCAAcceptResponse",oldCurrentAppName,timer);
            await DataStore().saveSharedPreferencesString(KeyValue().REPLY,agentContent!);

            // agentContent = "넹 껐어요";
            sendAlarm("나", agentContent!, time, millitime, "2",KeyValue().AGENT);


          }

          //n분 이상 사용했을때 알람.
          if((savedMinutes+5 >timer!)  && (timer >= savedMinutes)  && !checker) {
            await DataStore().saveSharedPreferencesBool(KeyValue().ALARM_CHECKER,true);
            //사용을 종료하라는 agent의 메세지
            now = DateTime.now();
            millitime = DateTime
                .now()
                .millisecondsSinceEpoch;
            formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
            time = formatter.format(now);
            gptContent = await sendGPT("GPTFirstResponse",currentAppName,timer);
            await DataStore().saveSharedPreferencesString(KeyValue().REPLY,gptContent!);

            // gptContent = "$currentAppName 끄쇼";
            sendAlarm(
                "Agent", gptContent!, time, millitime,
                "1",KeyValue().GPT);

            await Future.delayed(Duration(seconds: duration));
            //PCA의 응답
            now = DateTime.now();
            millitime = DateTime
                .now()
                .millisecondsSinceEpoch;
            formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
            time = formatter.format(now);

            agentContent = await sendGPT("PCAFirstResponse",currentAppName,timer);
            await DataStore().saveSharedPreferencesString(KeyValue().REPLY,agentContent!);
            // agentContent = "끌겨";
            sendAlarm("나", agentContent!, time, millitime, "2",KeyValue().AGENT);


            print("현재 앱 사용시간이 설정된 시간을 초과했습니다. $timer $savedMinutes");

            // n분 이상 사용했으면서 알람을 받고도 종료하지 않으면 알람.
          } else if (timer >= (savedMinutes + 5) && checker!) {
            await DataStore().saveSharedPreferencesBool(KeyValue().ALARM_CHECKER,false);
            if( oldCurrentApp == currentApp && hasPackage){
              now = DateTime.now();
              millitime = DateTime
                  .now()
                  .millisecondsSinceEpoch;
              formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
              time = formatter.format(now);
              gptContent = await sendGPT("GPTRejectResponse",currentAppName,timer);
              await DataStore().saveSharedPreferencesString(KeyValue().REPLY,gptContent!);
              // gptContent = "GPT2 사용 종료 하세요!";
              sendAlarm(
                  "Agent : ", gptContent!, time, millitime,
                  "1",KeyValue().GPT);

              await Future.delayed(Duration(seconds: duration));
              //PCA의 응답
              now = DateTime.now();
              millitime = DateTime
                  .now()
                  .millisecondsSinceEpoch;
              formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
              time = formatter.format(now);

              agentContent = await sendGPT("PCARejectResponse",currentAppName,timer);
              await DataStore().saveSharedPreferencesString(KeyValue().REPLY,agentContent!);

              // agentContent = "아예~";
              sendAlarm("나", agentContent!, time, millitime, "2",KeyValue().AGENT);

            }
          } else{
            print("아무런 작동을 하지 않습니다.");
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
