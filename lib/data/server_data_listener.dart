import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:math';

import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:chat_gpt_sdk/src/model/chat_complete/response/message.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:my_research/data/keystring.dart';
import 'package:my_research/data/data_store.dart';
import 'package:my_research/module/pedometerAPI.dart';

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
    // Messages 객체 리스트 생성
    if(category =="wakeup") {
      text = "1시간동안 움직임이 없었다고 움직임이 필요하다는 것을 저에게 알려주는 글을 20자 이하의 존댓말로 문장 딱 1개만! 생성해줘요.";
    }
    if(category =="GPTask") {
      int i = DateTime.now().hashCode;
      String reseaon = '업무';
      if(i%3==0){
        reseaon = "휴식";
      }
      if(i%3==1){
        reseaon = "업무";
      }
      if(i%3==2){
        reseaon = "귀찮음";
      }
      text = "제가 상대방에게 $reseaon 의 이유로 운동을 하지 않았다고 변명하는 메시지를 20자 이하의 존댓말로 문장 딱 1개만! 생성해주세요.";
    }
    if(category =="agent") {
      text = "다음 문장을 보고 저에게 움직이도록 유도하는 글을 20자 이하의 존댓말로 문장 딱 1개만! 생성해주세요. $text";
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
    var time = DateTime
        .now()
        .millisecondsSinceEpoch;
    final response = await _openAI.onChatCompletion(request: request);
    for(var element in response!.choices){
      final message = element.message;
      if (message != null){
        return message.content;
      }
    }
    return null;
  }
  // Future<void> sendMessage(String message) async {
  //   var url = Uri.parse("http://ljy7802.cafe24.com/message/");
  //   var response = await http.post(
  //     url,
  //     headers: {
  //       'Content-Type': 'application/json; charset=UTF-8',
  //     },
  //     body: json.encode({'message': message}),
  //   );
  //
  //   if (response.statusCode == 200) {
  //     print("Server response: ${response.body}");
  //   } else {
  //     print('Request failed with status: ${response.statusCode}.');
  //   }
  // }

  //FCM을 통해서 받은 데이터를 휴대폰에서 처리하는 함수.
  Future<void> FCMactivce(RemoteMessage message) async {
    final stepCounterService = PedometerAPI();
    stepCounterService.refreshSteps();
    var step = await DataStore().getSharedPreferencesInt(
        Category().TOTALSTEP_KEY);
    step=100;
    String? gptContent = "key가 없거나 오류가 났습니다.";
    String? agentContent = "key가 없거나 오류가 났습니다.";
    var time = DateTime
        .now()
        .millisecondsSinceEpoch;
    print("Handling a background message: ${message.data}");
//--------------------------------------------------------------------------
    if (message.data["isRecord"] == "wakeup") {
      print("${message.data}");
      Map<String, dynamic> data = {
        // Category().ISFCM: message.data[Category().ISFCM],
        Category().TOTALSTEP_KEY: '$step',
        Category().FIRSTSTEP_KEY: "${await DataStore().getSharedPreferencesInt(
            Category().FIRSTSTEP_KEY)}",
      };
      //FCM이 들어왔을때, 파이어베이스에 값(FCM을 잘 받았는지, 현재까지 걸은것, 어플을 켰을때 초기 걸음수) 저장함.
      await DataStore().saveData(Category().ID, Category().FCM, data);
      //FCM을 받았는지 확인하는 코드
      await DataStore().saveData(Category().ID, Category().ISFCM, {Category().ISFCM: message.data[Category().ISFCM]});
      await DataStore().saveData(
          Category().ID, '${Category().STEPHISTORY}/$time',
          {
            Category().TOTALSTEP_KEY: '$step',
            Category().TIMESTAMP: time,
          }
      );



      //TODO
      //GPT가 물어볼말 서버에 전달하기
      //gptContent = 지피티에게 왜 운동하지 않았냐? 라는 문구를 생성하도록 요구.
      //                                "wakeup"
      gptContent = await sendGPT(message.data["content"],message.data["isRecord"]);

      await DataStore().saveData(
          Category().ID, Category().CONVERSATION,
          {
            Category().WHO: Category().GPT,
            Category().CONTENT: gptContent,
          }
      );
      //히스토리 저장
      await DataStore().saveData(Category().ID, '${Category().Chat}/$time', {
        Category().CHAT_ID: Category().GPT,
        Category().CONTENT: gptContent,
        Category().TIMESTAMP: time,
      });

      //이 문구를 서버에 보내고 기다림
    }
//--------------------------------------------------------------------------
    if (message.data["isRecord"] == "GPTask") {
      //서버에서 지피티의 내용 전달 해주기
      // gptContent 내용 받아오기 (왜 안하셨어요? 라고 묻기) or 응원의 메세지로 묻기
      LocalNotification.showOngoingNotification(
          title: '${message.data["title"]}',
          body: '${message.data["content"]}',
          payload: "feedback"
      );

      //TODO
      //agentContent = {사실 전달} 때문에 못했습니다. 라고 말하기.         "GPTask"
      agentContent = await sendGPT(message.data["content"],message.data["isRecord"]);
      //agent가 대신할말 서버에 전달하기
      await DataStore().saveData(
          Category().ID, Category().CONVERSATION,
          {
            Category().WHO: Category().AGENT,
            Category().CONTENT: agentContent,
          }
      );

      await DataStore().saveData(Category().ID, '${Category().Chat}/$time', {
        Category().CHAT_ID: Category().AGENT,
        Category().CONTENT: agentContent,
        Category().TIMESTAMP: time,
      });
      await DataStore().saveSharedPreferencesString(Category().CONVERSATION, agentContent!);
      print("agent");
    }

//--------------------------------------------------------------------------
    if (message.data["isRecord"] == "agent") {
      //TODO
      //서버에서 agent내용 FCM받기
      //agent
      LocalNotification.showOngoingNotification(
          title: '${message.data["title"]}',
          body: '${message.data["content"]}',
          payload: "feedback"
      );

      //GPT가 생성한 내용을 서버에 전달
      //                                                        "agent"
      gptContent = await sendGPT(message.data["content"],message.data["isRecord"]);

      await DataStore().saveData(
          Category().ID, Category().CONVERSATION,
          {
            Category().WHO: Category().GPT,
            Category().CONTENT: gptContent,
          }
      );
      //agentContent = {사실 전달 } 때문에 못했습니다. 라고 말하기.
      await DataStore().saveData(Category().ID, '${Category().Chat}/$time', {
        Category().CHAT_ID: Category().GPT,
        Category().CONTENT: gptContent,
        Category().TIMESTAMP: time,
      });
    }

//--------------------------------------------------------------------------
    if (message.data["isRecord"] == "GPTanswer") {
      //TODO
      //서버에서 받은 GPT내용 받기
      LocalNotification.showOngoingNotification(
          title: '${message.data["title"]}',
          body: '${message.data["content"]}',
          payload: "feedback"
      );
      //FCM이 마무리된걸 표시하는 코드
      await DataStore().saveData(Category().ID, Category().ISFCM, {Category().ISFCM: message.data[Category().ISFCM]});
    }
  }
}
