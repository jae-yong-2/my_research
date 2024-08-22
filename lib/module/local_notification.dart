import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
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
      // TODO 의도가 맞을 때, 틀릴 때 피드백 각각 받기

      String? content = await DataStore().getSharedPreferencesString("${KeyValue().ISFEEDBACK}_agentContent");
      String? time = await DataStore().getSharedPreferencesString("${KeyValue().ISFEEDBACK}_time");
      int? millitime = await DataStore().getSharedPreferencesInt("${KeyValue().ISFEEDBACK}_millitime");

      if (response.actionId == 'yes_action' || response.actionId == 'no_action' || response.actionId == 'unknown_action') {
        // 예 또는 아니오 또는 모르겠습니다 버튼이 눌렸을 때, 다시 "이유가 맞습니다" 또는 "이유가 다릅니다" 또는 "모르겠습니다" 알림을 생성
        if(response.actionId == 'yes_action'){
          await DataStore().saveSharedPreferencesString("Purpose", "true");
          // TODO 의도가 맞다는 피드백 보내기
          await DataStore().saveData(KeyValue().ID, '${KeyValue().Chat}/$time', {
            KeyValue().CHAT_ID: KeyValue().AGENT,
            KeyValue().CONTENT: content,
            KeyValue().TIMESTAMP: time,
            KeyValue().MILLITIMESTAMP: millitime,
            "Purpose" : "true",
            "Reason" : "null",
          });
          print("click yes action");
        }
        if(response.actionId == 'no_action'){
          // TODO 의도가 틀리다는 피드백 보내기
          await DataStore().saveSharedPreferencesString("Purpose", "false");
          // TODO 의도가 맞다는 피드백 보내기
          await DataStore().saveData(KeyValue().ID, '${KeyValue().Chat}/$time', {
            KeyValue().CHAT_ID: KeyValue().AGENT,
            KeyValue().CONTENT: content,
            KeyValue().TIMESTAMP: time,
            KeyValue().MILLITIMESTAMP: millitime,
            "Purpose" : "false",
            "Reason" : "null",
          });
          print("click no action ");
        }
        if(response.actionId == 'unknown_action'){
          // TODO 의도를 모르겠다는 피드백 보내기
          await DataStore().saveSharedPreferencesString("Purpose", "unknown");
          // TODO 의도를 모르겠다는 피드백 보내기
          await DataStore().saveData(KeyValue().ID, '${KeyValue().Chat}/$time', {
            KeyValue().CHAT_ID: KeyValue().AGENT,
            KeyValue().CONTENT: content,
            KeyValue().TIMESTAMP: time,
            KeyValue().MILLITIMESTAMP: millitime,
            "Purpose" : "unknown",
            "Reason" : "null",
          });
          print("click unknown action");
        }

        String? text = await DataStore().getSharedPreferencesString("${KeyValue().ISFEEDBACK}_agentContent");
        text ??= "오류입니다. 아무 응답 후, 넘어가주세요.";
        await LocalNotification.showOngoingNotification(
          title: '이유는 어떤가요?',
          body: text,
          payload: '6',
        );
      }

      if (response.actionId == 'correct_reason' || response.actionId == 'incorrect_reason' || response.actionId == 'unknown_reason') {
        // 이유가 맞는지 묻는 알림에 대한 응답 처리
        print("User selected reason response: ${response.actionId}");

        String? purpose = await DataStore().getSharedPreferencesString("Purpose");

        if(response.actionId == 'correct_reason'){
          // TODO 이유가 맞다는 피드백 보내기
          await DataStore().saveData(KeyValue().ID, '${KeyValue().Chat}/$time', {
            KeyValue().CHAT_ID: KeyValue().AGENT,
            KeyValue().CONTENT: content,
            KeyValue().TIMESTAMP: time,
            KeyValue().MILLITIMESTAMP: millitime,
            "Purpose" : purpose,
            "Reason" : "true",
          });
          print("click reason yes");
        }
        if(response.actionId == 'incorrect_reason'){
          // TODO 이유가 틀리다는 피드백 보내기
          await DataStore().saveData(KeyValue().ID, '${KeyValue().Chat}/$time', {
            KeyValue().CHAT_ID: KeyValue().AGENT,
            KeyValue().CONTENT: content,
            KeyValue().TIMESTAMP: time,
            KeyValue().MILLITIMESTAMP: millitime,
            "Purpose" : purpose,
            "Reason" : "false",
          });
          print("click reason no");
        }
        if(response.actionId == 'unknown_reason'){
          // TODO 이유를 모르겠다는 피드백 보내기
          await DataStore().saveData(KeyValue().ID, '${KeyValue().Chat}/$time', {
            KeyValue().CHAT_ID: KeyValue().AGENT,
            KeyValue().CONTENT: content,
            KeyValue().TIMESTAMP: time,
            KeyValue().MILLITIMESTAMP: millitime,
            "Purpose" : purpose,
            "Reason" : purpose,
          });
          print("click reason unknown");
        }
        // TODO 이유가 맞고 틀릴 때, 각각에 대해서 알고리즘 처리

        // 모든 알림 취소
        await LocalNotification.cancelNotificationByPayload(1);
        await LocalNotification.cancelNotificationByPayload(2);
        await LocalNotification.cancelNotificationByPayload(6);
      } else {
        print("No input received.");
      }

      if(response.payload == '6' || response.payload == '2'){
        FlutterForegroundTask.minimizeApp();
      }
      // 두 번째 피드백을 받았을 때 알림 취소
    } else {
      // navigatorKey.currentState?.push(MaterialPageRoute(builder: (context) => MyApp(isLaunchedByNotification: false,)));
      // 앱으로 이동하지 않도록 이 부분을 비워둡니다.
    }
  } catch (e) {
    print("Error handling notification response: $e");
    // 에러 처리 로직
  }
}

class LocalNotification {
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<bool> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    final DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification: (id, title, body, payload) {},
    );
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
    List<AndroidNotificationAction> actions = [];

    if (payload == '2') {
      actions = [
        AndroidNotificationAction(
          "yes_action",
          "의도가 맞음",
          showsUserInterface: true,
          inputs: [],
        ),

        AndroidNotificationAction(
          "unknown_action",
          "모르겠음",
          showsUserInterface: true,
          inputs: [],
        ),
        AndroidNotificationAction(
          "no_action",
          "의도가 틀림",
          showsUserInterface: true,
          inputs: [],
        ),
      ];
    } else if (payload == '6') {
      actions = [
        AndroidNotificationAction(
          "correct_reason",
          "이유 맞음",
          showsUserInterface: true,
          inputs: [],
        ),

        AndroidNotificationAction(
          "unknown_reason",
          "모르겠음",
          showsUserInterface: true,
          inputs: [],
        ),
        AndroidNotificationAction(
          "incorrect_reason",
          "이유 틀림.",
          showsUserInterface: true,
          inputs: [],
        ),
      ];
    }

    final BigTextStyleInformation bigTextStyleInformation = BigTextStyleInformation(
      body,
      contentTitle: title,
      htmlFormatBigText: true,
      htmlFormatContentTitle: true,
    );

    final AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
      '답장하기',
      '답장하기',
      channelDescription: '답장하기',
      importance: Importance.max,
      priority: Priority.max,
      ongoing: false,
      autoCancel: false,
      groupKey: groupKey,
      styleInformation: bigTextStyleInformation,
      actions: actions,
      icon: (payload == "2" || payload == "4") ? '@drawable/user' : (payload == "5"|| payload == "6")? '@drawable/feedback':'@drawable/gpt',
    );

    final NotificationDetails notificationDetails = NotificationDetails(android: androidNotificationDetails);

    final int notificationId = DateTime.now().hashCode;
    await _flutterLocalNotificationsPlugin.show(int.parse(payload), title, body, notificationDetails, payload: payload);
  }

  static Future<void> cancelNotificationByPayload(int payload) async {
    await _flutterLocalNotificationsPlugin.cancel(payload);
  }

  static Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }
}
