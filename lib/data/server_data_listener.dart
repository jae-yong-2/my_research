import 'dart:async';
import 'dart:convert';
import 'dart:ffi';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:my_research/data/keystring.dart';
import 'package:my_research/data/data_store.dart';
import 'package:my_research/module/pedometerAPI.dart';

import '../module/local_notification.dart';

class ServerDataListener {

  //백그라운드에서 작업할 내용을 작성
  Future<void> FCMbackgroundMessage(RemoteMessage message) async {
    // If you're going to use other Firebase services in the background, such as Firestore,
    // make sure you call `initializeApp` before using other Firebase services.
    FCMactivce(message);
    //key값은 서버에서 보내줌
  }

  Future<void> sendMessage(String message) async {
    var url = Uri.parse("http://ljy7802.cafe24.com/message/");
    var response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: json.encode({'message': message}),
    );

    if (response.statusCode == 200) {
      print("Server response: ${response.body}");
    } else {
      print('Request failed with status: ${response.statusCode}.');
    }
  }

  //FCM을 통해서 받은 데이터를 휴대폰에서 처리하는 함수.
  Future<void> FCMactivce(RemoteMessage message) async {
    final stepCounterService = PedometerAPI();
    stepCounterService.refreshSteps();
    var step = await DataStore().getSharedPreferencesInt(
        Category().TOTALSTEP_KEY);
    var gptContent = "화이팅 or 왜못함?";
    var agentContent = "운동하느라 못했습니다.";
    var time = DateTime
        .now()
        .millisecondsSinceEpoch;
    print("Handling a background message: ${message.data}");
//--------------------------------------------------------------------------
    if (message.data["isRecord"] == "wakeup") {
      print("${message.data}");
      Map<String, dynamic> data = {
        Category().ISFCM: message.data[Category().ISFCM],
        Category().TOTALSTEP_KEY: '$step',
        Category().FIRSTSTEP_KEY: "${await DataStore().getSharedPreferencesInt(
            Category().FIRSTSTEP_KEY)}",
      };
      //FCM이 들어왔을때, 파이어베이스에 값(FCM을 잘 받았는지, 현재까지 걸은것, 어플을 켰을때 초기 걸음수) 저장함.
      await DataStore().saveData(Category().ID, Category().FCM, data);
      await DataStore().saveData(Category().ID, Category().ISFCM, data);
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
      gptContent=message.data["title"];
      LocalNotification.showOngoingNotification(
          title: gptContent,
          body: '${message.data["content"]}',
          payload: "background"
      );
      //agent가 대신할말 서버에 전달하기
      await DataStore().saveData(
          Category().ID, Category().CONVERSATION,
          {
            Category().WHO: Category().AGENT,
            Category().CONTENT: agentContent,
          }
      );
      //agentContent = {사실 전달 } 때문에 못했습니다. 라고 말하기.
      await DataStore().saveData(Category().ID, '${Category().Chat}/$time', {
        Category().CHAT_ID: Category().AGENT,
        Category().CONTENT: agentContent,
        Category().TIMESTAMP: time,
      });
      print("agent");
      // var data = {
      //   Category().ISFCM :message.data[Category().ISFCM],
      // };
      // //FCM이 들어왔을때, 파이어베이스에 값을 저장함.
      // DataStore().saveData(Category().ID, Category().FCM, data);
      // print("GPT");
    }

//--------------------------------------------------------------------------
    if (message.data["isRecord"] == "agent") {
      //TODO
      //서버에서 agent내용 FCM받기
      //agentContent = {사실 전달 } 때문에 못했습니다. 라고 말하기.
      agentContent=message.data["title"];
      LocalNotification.showOngoingNotification(
          title: agentContent,
          body: '${message.data["content"]}',
          payload: "background"
      );

      //GPT가 생성한 내용을 서버에 전달
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
      gptContent=message.data["title"];
      LocalNotification.showOngoingNotification(
          title: gptContent,
          body: '${message.data["content"]}',
          payload: "background"
      );
      // Map<String, dynamic> data = {
      //   Category().ISFCM :message.data[Category().ISFCM],
      // };
      // //FCM이 들어왔을때, 파이어베이스에 값을 저장함.
      // DataStore().saveData(Category().ID, Category().FCM, data);

    }
      // sendMessage('$step');
      // sendMessage('$step0 background');
  }
}
