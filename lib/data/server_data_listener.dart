import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:math';

import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:chat_gpt_sdk/src/model/chat_complete/response/message.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:my_research/data/keystring.dart';
import 'package:my_research/data/data_store.dart';
import 'package:my_research/module/pedometerAPI.dart';

import '../module/healthKit.dart';
import '../module/local_notification.dart';
import '../package/const_key.dart';
import '../page/chat/chat_message.dart';

class ServerDataListener {

  //백그라운드에서 작업할 내용을 작성
  Future<void> FCMbackgroundMessage(RemoteMessage message) async {
    // If you're going to use other Firebase services in the background, such as Firestore,
    // make sure you call `initializeApp` before using other Firebase services.
    FCMactivce(message);
    //key값은 서버에서 보내줌
  }

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
  Future<String?> sendGPT(text, category) async {
    var habit = await DataStore().getSharedPreferencesString(
        KeyValue().HABIT_STATE);
    var bodyissue = await DataStore().getSharedPreferencesString(
        KeyValue().CURRENT_BODY_ISSUE);
    // Messages 객체 리스트 생성
    if (category == "makePeriodContent") {
      text =
      "평소 습관이 $habit, 신체 특이사항이 $bodyissue 인 저에게 1시간동안 움직임이 없었다고 걷기가 필요하다는 것을 저에게 알려주는 글을 40자 정도의 존댓말로 자연스러운 문장 딱 1개만! 생성해줘요.";
    }

    if (category == "RecommendWalkingContent") {
      text =
      "다음 문장을 보고 평소 습관이 $habit, 신체 특이사항이 $bodyissue 인 '저'에게 지금 바로 걷기를 장려하는 글을 40자 정도의 존댓말로 자연스러운 문장 딱 1개만! 생성해주세요. $text";
    }

    if (category == "makeIamWalking") {
      text = "제가 알람을 보고 움직였다는 글을 30자 정도의 존댓말로 자연스러운 문장 딱 1개만! 생성해주세요.";
    }
    if (category == "makeWalkingNextTime") {
      text =
      "다음 문장을 보고 평소 습관이 $habit, 신체 특이사항이 $bodyissue 인 저에게 계속 활동을 격려하는 글을 20자 정도의 존댓말로 자연스러운 문작 딱 1개만! 추천해주세요. $text";
    }

    if (category == "notWalkingReason") {
      int i = DateTime
          .now()
          .hashCode;
      String reseaon = '업무';
      if (i % 3 == 0) {
        reseaon = "휴식";
      }
      if (i % 3 == 1) {
        reseaon = "업무";
      }
      if (i % 3 == 2) {
        reseaon = "귀찮음";
      }
      text =
      "다음 알람을 보고 상대방에게 $reseaon 의 이유로 알람을 보고도 움직이지 않았다고 변명하는 메시지를 30자 정도의 존댓말로 자연스러운 문장 딱 1개만! 생성해주세요. $text";
    }

    if (category == "makeOpinion") {
      int i = DateTime
          .now()
          .hashCode;
      String reseaon = '업무';
      if (i % 2 == 0) {
        reseaon = "할게요..";
      }
      if (i % 2 == 1) {
        reseaon = "안할게요..";
      }
      text =
      "다음 문장을 보고 평소 습관이 $habit, 신체 특이사항이 $bodyissue 인 제가 '걷기나 스트레칭 등 가벼운 활동을 $reseaon'라고 말하는 글을 20자 정도의 존댓말로 자연스러운 문작 딱 1개만! 추천해주세요. $text";
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
      maxToken: 200,
      temperature: 1,
    );
    final response = await _openAI.onChatCompletion(request: request);
    for (var element in response!.choices) {
      final message = element.message;
      if (message != null) {
        return message.content;
      }
    }
    return null;
  }

  Future<void> agentAlarm(String title, String content, var time, var millitime,
      String payload) async {
    LocalNotification.showOngoingNotification(
      title: title,
      body: content,
      payload: payload,
    );
    //히스토리에 저장
    await DataStore().saveData(KeyValue().ID, '${KeyValue().Chat}/$time', {
      KeyValue().CHAT_ID: KeyValue().AGENT,
      KeyValue().CONTENT: content,
      KeyValue().TIMESTAMP: time,
      KeyValue().MILLITIMESTAMP: millitime,

    });
  }

  Future<void> gptAlarm(String title, String content, var time, var millitime,
      String payload) async {
    LocalNotification.showOngoingNotification(
        title: title,
        body: content,
        payload: payload
    );

    //히스토리 저장
    await DataStore().saveData(KeyValue().ID, '${KeyValue().Chat}/$time', {
      KeyValue().CHAT_ID: KeyValue().GPT,
      KeyValue().CONTENT: content,
      KeyValue().TIMESTAMP: time,
      KeyValue().MILLITIMESTAMP: millitime,
    });
  }

  Future<void> recordStepHistory(var time, var step) async {
    await DataStore().saveData(
        KeyValue().ID, '${KeyValue().STEPHISTORY}/$time',
        {
          KeyValue().TOTALSTEP_KEY: '$step',
          KeyValue().TIMESTAMP: time,
        }
    );
  }
  Future<void> makeGPTContent(var gptContent, String content, String isRecord) async {
    gptContent = await sendGPT(content, isRecord);

    await DataStore().saveData(
        KeyValue().ID, KeyValue().CONVERSATION,
        {
          KeyValue().WHO: KeyValue().GPT,
          KeyValue().CONTENT: gptContent,
        }
    );
  }
  Future<void> makeAgentContent(var agentContent, String content, String isRecord) async {
    agentContent =
    await sendGPT(content, isRecord);

    await DataStore().saveData(
        KeyValue().ID, KeyValue().CONVERSATION,
        {
          KeyValue().WHO: KeyValue().AGENT,
          KeyValue().CONTENT: agentContent,
        }
    );
  }

  //FCM을 통해서 받은 데이터를 휴대폰에서 처리하는 함수.
  Future<void> FCMactivce(RemoteMessage message) async {
    // final stepCounterService = PedometerAPI();
    // stepCounterService.refreshSteps();
    // var step = await DataStore().getSharedPreferencesInt(
    //     Category().TOTALSTEP_KEY);
    // HealthKit healthHelper = HealthKit();
    // int step = await healthHelper.getSteps();
    print("FCM");
    var step = await HealthKit().getSteps();
    step ??= 0;
    String? gptContent = "key가 없거나 오류가 났습니다.";
    String? agentContent = "key가 없거나 오류가 났습니다.";
    var now = DateTime.now();
    var millitime = DateTime
        .now()
        .millisecondsSinceEpoch;
    var formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    String time = formatter.format(now);
    print("Handling a background message: ${message.data}");
//--------------------------------------------------------------------------
    if (message.data["isRecord"] == "update") {
      print("FCM update");
      try {
        DataStore().saveData(KeyValue().ID, KeyValue().CURRENTSTEP, {
          KeyValue().TOTALSTEP_KEY: '$step',
        });
      } catch (e) {
        DataStore().saveData(KeyValue().ID, KeyValue().CURRENTSTEP, {
          KeyValue().TOTALSTEP_KEY: '0',
        });
      }
      //이 문구를 서버에 보내고 기다림
    }

    if (message.data["isRecord"] == "makePeriodContent") {
      recordStepHistory(time, step);
      //TODO
      //GPT가 물어볼말 서버에 전달하기
      //gptContent = 지피티에게 왜 운동하지 않았냐? 라는 문구를 생성하도록 요구.
      //                                                  "makePeriodContent"
      makeGPTContent(gptContent, message.data["content"], message.data["isRecord"]);
    }
//--------------------------------------------------------------------------
    if (message.data["isRecord"] == "notWalkingReason") {
      //서버에서 지피티의 내용 전달 해주기
      // gptContent 내용 받아오기 (왜 안하셨어요? 라고 묻기) or 응원의 메세지로 묻기
      // //히스토리 저장
      gptAlarm(
          message.data["title"], message.data["content"], time, millitime, "1");

      //TODO
      //agentContent = {사실 전달} 때문에 못했습니다. 라고 말하기.         "notWalkingReason"
      // //agent가 대신할말 서버에 전달하기
      makeAgentContent(agentContent, message.data["content"], message.data["isRecord"]);

      //피드백 페이지를 위한 저장 장소
      await DataStore().saveSharedPreferencesString(
          "${KeyValue().CONVERSATION}1", agentContent!);
      await DataStore().saveSharedPreferencesString(
          "${KeyValue().TIMESTAMP}1", time);
      print("agent");
    }
    // Fluttertoast.showToast(msg: '$agentContent', gravity: ToastGravity.CENTER);

//--------------------------------------------------------------------------
    if (message.data["isRecord"] == "RecommendWalkingContent") {
      //TODO
      //서버에서 agent내용 FCM받기
      //agent
      // //히스토리에 저장
      agentAlarm(
          message.data["title"], message.data["content"], time, millitime, "2");
      //GPT가 생성한 내용을 서버에 전달
      makeGPTContent(gptContent, message.data["content"], message.data["isRecord"]);
    }


//--------------------------------------------------------------------------

    //GPT가 생성한 내용을 서버에 전달
    //내가 다음에 할 의사 표현을 하는 문구 생성                                 "GPTanswer"
    //움직였을때 무브

    if (message.data["isRecord"] == "makeIamWalking") {
      recordStepHistory(time, step);
      //GPT가 물어볼말 서버에 전달하기
      //gptContent = 지피티에게 왜 운동하지 않았냐? 라는 문구를 생성하도록 요구.
      //                                                     "move"
      makeAgentContent(agentContent, message.data["content"], message.data["isRecord"]);
    }

    if (message.data["isRecord"] == "makeWalkingNextTime") {
      // //히스토리에 저장
      agentAlarm(
          message.data["title"], message.data["content"], time, millitime, "2");
      recordStepHistory(time, step);
      //TODO
      //GPT가 물어볼말 서버에 전달하기
      //gptContent = 지피티에게 지속적으로 운동을 더 해달라는 라는 문구를 생성하도록 요구.
      //                                                     "movedGPTanswer"
      makeGPTContent(gptContent, message.data["content"], message.data["isRecord"]);
    }

    if (message.data["isRecord"] == "GPTAlarm") {
      //TODO
      //서버에서 받은 GPT내용 받기
      //   //히스토리에 저장
      gptAlarm(
          message.data["title"], message.data["content"], time, millitime, "3");
    }
  }
}
