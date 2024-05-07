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
    //완료-----------------------------------------
    if (category == "makePeriodContent") {
      text =
      "평소 습관이 $habit, "
          "신체 특이사항이 $bodyissue 인 "
          "저에게 1시간동안 움직임이 없었다고 잠시동안 걸어라고 "
          "긍정적으로 권유해주는 글을 35자 정도의 존댓말로 자연스러운 문장 딱 1개만! "
          "생성해줘요.";
    }

    if (category == "makeIamWalking") {
      text =
      "{"
          "'역할' : '나를 대신해서 나인 척 내 목표를 상대방에게 전달하는 사람',"
          "'1분전 받은 알람' :  '$text\n',"
          "'상황' : '알람을 받고 1분이내에 걸었습니다.',"
          "'요구사항' :"
            "["
              "'상대방이 운동하라고 권유했을 때, 대답을 나인 척하며 알람을 받고 운동(걸음, 산책 등)을 했다는 대답을 한다.',"
              "'학습 데이터는 상대방과 나와의 대화 몇가지 예시이며, 예시에 나의 대답에서 나타나는 내 말투와 어투를 분석하여 이와 동일한 말투와 말씨의 문장을 1개 생성한다',"
              "'학습데이터에 있는 내 말투가 아니면 상대방이 어색해 할 것 이므로 주의 요망!!!!',"
            "],"
          "'학습데이터' :"
            "[ "
              "'example 1)"
              "상대방의 권유 : 잠시마나 일어나셔서 걸어보시는 건 어떠세요? 무릎에도 좋고, 자세 교정에도 도움이 될 거에요."
              "나의 대답 : 5분 있다가 10분 정도 걷겠음.',"
              "'example 2)"
              "상대방의 권유 : 오래 앉아 계셨으니, 잠시 허리를 펴며 걸어보시는 건 어떠세요?."
              "나의 대답 : 좋아 지금 잠시동안 스트레칭 해보겠음.',"
              "'example 3)"
              "상대방의 권유 : 1시간이 지났어요. 잠시 무릎 통증을 잊고 걸어보는 건 어떨까요?"
              "나의 대답 : 지금 30분정도 걸어보겠음.'"
            "],"
          "'대답' : ''"
      "}";
    }

    if (category == "notWalkingReason") {
        // 단순 이유가 아닌 의지 표현
      text =
      // "{"
      //     "'역할' : '나를 대신해서 나인 척 내 목표를 상대방에게 전달하는 사람',"
      //     "'1분전 받은 알람' :  '$text\n',"
      //     "'상황' : '알람을 받고 1분동안 아무런 움직임이 없었습니다.',"
      //
      //     "'요구사항' :"
      //         "["
      //             "'상대방에게 1회성의 가벼운 걷기 목표를 구체적이고 달성가능고 다양하게 설정해서 제가 할 거라고 채팅으로 전달.',"
      //             "'학습데이터는 내가 평소 채팅에서 쓰는 문장이며, 상대방이 최대한 익숙하게 느낄 수 있도록 학습데이터의 문장들을 분석하여!!! 동일한 말투!!와 말씨!!의 문장 1개 생성. ',"
      //             "'학습데이터의 말투가 아니면 상대방이 어색해 할거니 주의 요망!!!!', "
      //             "'30글자 정도로 생성."
      //         "],"
      //     "'학습데이터' :"
      //         "["
      //             "'n분 있다가 n분 동안 움직일 것임',"
      //             "'일을 끝 마치고 n분 동안 걸어볼 것 임.',"
      //             "'하던 일을 끝내면 n분간 산책을 해볼 것 임.'"
      //         "],"
      //     "'대답' : ''"
      // "}";
      "{"
          "'GPT 역할' : '나를 대신해서 나인 척 내 목표를 상대방에게 전달하는 사람',"
          "'1분전 상대방에게 받은 알람' :  '$text\n',"
          "'상황' : '알람을 받고 1분동안 아무런 움직임이 없었습니다.',"
          "'요구사항' :"
          "["
              "'상대방이 운동하라고 권유했을 때, 운동을 할 것이라는 대답을 나인 척하며 대답한다',"
              "'생성하는 대답은 언제, 얼마동안, 어떻게 행동할지 최대한 구체적인 나의 말투로 생성한다.',"
              "'학습 데이터는 상대방과 나와의 대화 몇가지 예시이며, 예시에 나의 대답에서 나타나는 내 말투와 어투를 분석하여 이와 동일한 말투와 말씨의 문장 1개!를 생성한다',"
              "'학습데이터에 있는 내 말투가 아니면 상대방이 어색해 할 것 이므로 주의 요망!!!!',"
          "],"
          "'학습데이터' :"
          "[ "
              "'example 1 )"
                "상대방의 권유 : 잠시마나 일어나셔서 걸어보시는 건 어떠세요? 무릎에도 좋고, 자세 교정에도 도움이 될 거에요."
                "나의 대답 : 밤 n시에 집앞 공원에서 nkm가량 조깅할 예정~',"
              "'example 2)"
                "상대방의 권유 : 오래 앉아 계셨으니, 잠시 허리를 펴며 걸어보시는 건 어떠세요?."
                "나의 대답 : 지금은 업무중이라 n분 뒤에 일어나서 허리펴고 스트레칭 할게',"
              "'example 3)"
                "상대방의 권유 : 1시간이 지났어요. 잠시 무릎 통증을 잊고 걸어보는 건 어떨까요?"
                "나의 대답 : 그래, n분만 있다가 잠시 n시간 정도는 집앞 산책 다녀오지뭐'"
          "],"
          "'대답' : '(평소 몸상태가 $bodyissue인 나에게 맞는 n 수치를 생성해줘)'"
      "}";
      //GPT가 운동을 하는 것에 대한 목적을 생성할 수 있도록 해보자.
      //카카오
    }
    //안움직였지만 다음에 움직여라고 GPT가 하는 말
    if (category == "RecommendWalkingContent") {
      text =
          "방금 전 응답 : $text"
          "방금 전 응답을 확인했다는 글을 15자 정도의 존댓말 문장 딱 1개만!"
          "추천해주세요.";
      // "다음 문장을 보고 평소 습관이 $habit, 신체 특이사항이 $bodyissue 인 '저'에게 지금 바로 걷기를 장려하는 글을 40자 정도의 존댓말로 자연스러운 문장 딱 1개만! 생성해주세요. $text";
    }
    if(category=="reply"){
      text =
      "{"
          "'GPT 역할' : '처음 생성된 문장이 만족스럽지 못해서 수정했으면 함.',"
          "'처음 생성된 문장' : ${await DataStore().getSharedPreferencesString("${KeyValue().CONVERSATION}1")}"
          "'요청 사항' : '$text',"
          "'상황' : '다음 내용을 받고 마음에 들지 않습니다.',"
          "'요구사항' :"
            "["
              "'학습데이터는 말투만 따라하기 위한 데이터이므로 내용은 무시하고 말투만 따라하여 생성한다.',"
              "'생성될 문장의 내용은 처음 생성된 문장을 요청 사항에 맞게 수정해서 생성한다.',"
            "],"
          "'학습데이터' :"
            "[ "
              "'example 1 )"
              "상대방의 권유 : 잠시마나 일어나셔서 걸어보시는 건 어떠세요? 무릎에도 좋고, 자세 교정에도 도움이 될 거에요."
              "나의 대답 : 밤 n시에 집앞 공원에서 nkm가량 조깅할 예정~',"
              "'example 2)"
              "상대방의 권유 : 오래 앉아 계셨으니, 잠시 허리를 펴며 걸어보시는 건 어떠세요?."
              "나의 대답 : 지금은 업무중이라 n분 뒤에 일어나서 허리펴고 스트레칭 할게',"
              "'example 3)"
              "상대방의 권유 : 1시간이 지났어요. 잠시 무릎 통증을 잊고 걸어보는 건 어떨까요?"
              "나의 대답 : 그래, n분만 있다가 잠시 n시간 정도는 집앞 산책 다녀오지뭐'"
            "],"
          "'대답' : '',"
      "}";
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
      temperature: 0.75,
    );
    final response = await _openAI.onChatCompletion(request: request);
    for (var element in response!.choices) {
      final message = element.message;
      if (message != null) {
        try {
          final messageContent = message.content.replaceAll("'", '"');
          final decodedMessage = jsonDecode(messageContent);
          if (decodedMessage.containsKey("대답")) {
            // '대답' 키가 있으면 해당 값만 반환합니다.
            return decodedMessage["대답"];
          }else if(decodedMessage.containsKey('대답')){
            return decodedMessage['대답'];
          }
          else{
            return message.content;
          }
        }
        catch (e){
          // '대답' 키가 없으면 전체 메시지를 반환합니다.
          return message.content;
        }
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
  Future<void> makeAgentContent(var agentContent, String content, String isRecord, var time) async {
    agentContent = await sendGPT(content, isRecord);

    await DataStore().saveData(
        KeyValue().ID, KeyValue().CONVERSATION,
        {
          KeyValue().WHO: KeyValue().AGENT,
          KeyValue().CONTENT: agentContent,
        }
    );
    await DataStore().saveSharedPreferencesString(
        "${KeyValue().CONVERSATION}1", agentContent!);
    await DataStore().saveSharedPreferencesString(
        "${KeyValue().TIMESTAMP}1", time);
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
    // var step=0;
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
          KeyValue().TIMESTAMP : time
        });
      } catch (e) {
        DataStore().saveData(KeyValue().ID, KeyValue().CURRENTSTEP, {
          KeyValue().TOTALSTEP_KEY: '0',
          KeyValue().TIMESTAMP : time
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
      makeAgentContent(agentContent, message.data["content"], message.data["isRecord"],time);

      //피드백 페이지를 위한 저장 장소

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
      makeAgentContent(agentContent, message.data["content"], message.data["isRecord"],time);
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
