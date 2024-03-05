import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;

import 'local_notification.dart';

class Message_Connector{

  //백그라운드에서 작업할 내용을 작성
  Future<void> FCMbackgroundMessage(RemoteMessage message) async {
    // If you're going to use other Firebase services in the background, such as Firestore,
    // make sure you call `initializeApp` before using other Firebase services.

    print("Handling a background message: ${message.messageId}");
    LocalNotification.showOngoingNotification(
        title: '${message.notification?.title} background',
        body: '${message.notification?.body} background',
        payload: "background"
    );
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
}