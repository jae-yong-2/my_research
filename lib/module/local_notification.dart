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
      //TODO 의도가 맞을떄, 틀릴때 피드백 각각 받기




      if (response.actionId == 'yes_action' || response.actionId == 'no_action') {
        // 예 또는 아니오 버튼이 눌렸을 때, 다시 "이유가 맞습니다" 또는 "이유가 다릅니다" 알림을 생성
        await LocalNotification.showOngoingNotification(
          title: '이유는 어떤가요?',
          body: '이유가 맞습니까?',
          payload: '5',
        );
      } else if (response.input != null) {
        // 시간 초기화
        var millitime = DateTime.now().millisecondsSinceEpoch;
        var now = DateTime.now();
        var formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
        String time = formatter.format(now);
        print("User replied: ${response.input}");

        // 수정할 때 내용 저장
        // await DataStore().saveData(KeyValue().ID, '${KeyValue().REPLY}/$time', {
        //   KeyValue().CHAT_ID: KeyValue().AGENT,
        //   KeyValue().CONTENT: response.input,
        //   KeyValue().TIMESTAMP: time,
        //   KeyValue().MILLITIMESTAMP: millitime,
        // });

        // 서버로 전송하는 함수 호출
      } else {
        print("No input received.");
      }

      // 두 번째 피드백을 받았을 때 알림 취소
      await LocalNotification.cancelNotificationByPayload(1);
      await LocalNotification.cancelNotificationByPayload(2);
    } else if (response.actionId == 'correct_reason' || response.actionId == 'incorrect_reason') {
      // 이유가 맞는지 묻는 알림에 대한 응답 처리
      print("User selected reason response: ${response.actionId}");

      //TODO 이유가 맞고 틀릴때, 각각에 대해서 알고리즘 처리

      // 모든 알림 취소
      await LocalNotification.cancelAllNotifications();
    } else {
      // navigatorKey.currentState?.push(MaterialPageRoute(builder: (context) => MyApp(isLaunchedByNotification: false,)));
    }
  } catch (e) {
    print("Error handling notification response: $e");
    // 에러 처리 로직
  }
}

class LocalNotification {
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<bool?> get isFeedbackEnable async => await DataStore().getSharedPreferencesBool(KeyValue().ISFEEDBACK);

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
          "의도가 맞습니다.",
          showsUserInterface: true,
          inputs: [],
        ),
        AndroidNotificationAction(
          "no_action",
          "의도가 틀립니다.",
          showsUserInterface: true,
          inputs: [],
        ),
      ];
    } else if (payload == '5') {
      actions = [
        AndroidNotificationAction(
          "correct_reason",
          "이유가 맞습니다.",
          showsUserInterface: true,
          inputs: [],
        ),
        AndroidNotificationAction(
          "incorrect_reason",
          "이유가 다릅니다.",
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
      ongoing: true,
      autoCancel: false,
      groupKey: groupKey,
      styleInformation: bigTextStyleInformation,
      actions: actions,
      icon: (payload == "2" || payload == "5" || payload == "4") ? '@drawable/user' : '@drawable/gpt',
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
