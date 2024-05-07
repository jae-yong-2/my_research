import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:my_research/data/keystring.dart';
import 'package:my_research/data/server_data_listener.dart';

import '../data/data_store.dart';
import '../main.dart';
import '../page/feedback.dart';


@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) async {
  try {
    if (response.notificationResponseType == NotificationResponseType.selectedNotificationAction) {
      if (response.input != null) {

        //시간 초기화
        var millitime = DateTime
            .now()
            .millisecondsSinceEpoch;
        var now = DateTime.now();
        var formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
        String time = formatter.format(now);
        print("User replied: ${response.input}");

        //수정할때 내용 저장
        await DataStore().saveData(KeyValue().ID, '${KeyValue().REPLY}/$time', {
          KeyValue().CHAT_ID: KeyValue().AGENT,
          KeyValue().CONTENT: response.input,
          KeyValue().TIMESTAMP: time,
          KeyValue().MILLITIMESTAMP: millitime,
        });

        //수정 요청으로 수정된 내용 생성
        String? agentContent = await ServerDataListener().sendGPT(response.input, KeyValue().REPLY);
        print('---------------$agentContent');

        //수정 된 내용 서버에 캐시 저장
        // await DataStore().saveData(
        //     KeyValue().ID, KeyValue().CONVERSATION,
        //     {
        //       KeyValue().WHO: KeyValue().AGENT,
        //       KeyValue().CONTENT: agentContent,
        //     }
        // );
        //수정된 내용 스마트폰(feedback 용)으로 저장
        Future.delayed(Duration(seconds: 10), () async {
          await DataStore().saveSharedPreferencesString(
              "${KeyValue().CONVERSATION}1", agentContent!);
          await DataStore().saveSharedPreferencesString(
              "${KeyValue().TIMESTAMP}1", time);
          //알람과 동시에 서버에 수정된 내용 저장
          ServerDataListener().agentAlarm(
              "GPT에게 답장했습니다.", agentContent, time, millitime, "2");

        });

        Future.delayed(Duration(seconds: 15), () async {

          var millitime = DateTime
              .now()
              .millisecondsSinceEpoch;
          var now = DateTime.now();
          var formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
          String time = formatter.format(now);
          print("User replied: ${response.input}");
          String? gptContent = await ServerDataListener().sendGPT(agentContent, 'RecommendWalkingContent');
          ServerDataListener().gptAlarm("GPT에게 메세지가 도착했습니다.", gptContent!, time, millitime, "3");

        });



        // 서버로 전송하는 함수 호출
      } else {
        print("No input received.");
      }
    }else{
      navigatorKey.currentState?.push(MaterialPageRoute(builder: (context) => FeedbackPage()));
    }
  } catch (e) {
    print("Error handling notification response: $e");
    // 에러 처리 로직
  }
}
class LocalNotification {
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static Future<bool> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    final DarwinInitializationSettings initializationSettingsDarwin =
    DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        onDidReceiveLocalNotification: (id, title, body, payload) {});
    final InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid, iOS: initializationSettingsDarwin);

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse: notificationTapBackground,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    // 알람 클릭으로 앱이 시작되었는지 확인
    final details = await _flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
    bool isLaunchedByNotification = details?.didNotificationLaunchApp ?? false;

    print("notification 을 초기화했습니다.");
    return isLaunchedByNotification;
  }

  static Future<void> showOngoingNotification({
    required String title,
    required String body,
    required String payload,
  }) async {
    const String groupKey = 'com.yourcompany.messages';

    const AndroidNotificationAction replyAction = AndroidNotificationAction(
      '답장하기',
      '답장하기',
      inputs: <AndroidNotificationActionInput>[AndroidNotificationActionInput(label: 'reply_key')],
    );
    final AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
      '답장하기',
      '답장하기',
      channelDescription: '답장하기',
      importance: Importance.max,
      priority: Priority.max,
      ongoing: true,
      autoCancel: false,
      groupKey: groupKey,
      actions: (payload == "2" ? <AndroidNotificationAction>[
        AndroidNotificationAction(
          "categoryAccept",
          "답장하기",
          showsUserInterface: true,
          inputs: [
            AndroidNotificationActionInput(
              label: "Input your text",
            )
          ],
        )] : []),
    );
    // 답장을 위한 RemoteInput 생성


    final NotificationDetails notificationDetails = NotificationDetails(android: androidNotificationDetails);

    final int notificationId = DateTime.now().hashCode;
    await _flutterLocalNotificationsPlugin.show(int.parse(payload), title, body, notificationDetails, payload: payload);

  }

}
