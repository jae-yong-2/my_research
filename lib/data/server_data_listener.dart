import 'dart:async';
import 'dart:convert';
import 'dart:ffi';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:my_research/data/category.dart';
import 'package:my_research/data/data_store.dart';
import 'package:my_research/module/pedometerAPI.dart';

import '../module/local_notification.dart';

class ServerDataListener{

  //백그라운드에서 작업할 내용을 작성
  Future<void> FCMbackgroundMessage(RemoteMessage message) async {
    // If you're going to use other Firebase services in the background, such as Firestore,
    // make sure you call `initializeApp` before using other Firebase services.
    FCMactivce(message);
    //key값은 서버에서 보내줌
  }
  Future<void> sendMessage(String message) async{
    var url = Uri.parse("http://ljy7802.cafe24.com/message/");
    var response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: json.encode({'message':message}),
    );

    if(response.statusCode == 200){
      print("Server response: ${response.body}");
    } else{
      print('Request failed with status: ${response.statusCode}.');
    }
  }

  Future<void> FCMactivce(RemoteMessage message) async {

    print("Handling a background message: ${message.sentTime}");
    if(message.data["title"] =="휴대폰 깨우기"){
      print("${message.data["title"]}  ${message.data["content"]}");
    }else {
      LocalNotification.showOngoingNotification(
          title: '${message.data["title"]} background',
          body: '${message.data["content"]} background',
          payload: "background"
      );
    }
    final stepCounterService = PedometerAPI();
    stepCounterService.refreshSteps();
    var step = await DataStore().getSharedPreferencesInt(Category().TOTALSTEP_KEY);
    Map<String, dynamic> data = {
      Category().ISFCM :"true",
      Category().TOTALSTEP_KEY : '$step',
      Category().FIRSTSTEP_KEY : "${await DataStore().getSharedPreferencesInt(Category().FIRSTSTEP_KEY)}",
    };
    DataStore().saveData(Category().ID, Category().FCM, data);
    DataStore().saveData(Category().ID, Category().FCM, data);
    // sendMessage('$step');
    // sendMessage('$step0 background');
  }
}