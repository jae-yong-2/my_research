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
      String? content = await DataStore().getSharedPreferencesString("${KeyValue().ISFEEDBACK}_agentContent");
      String? time = await DataStore().getSharedPreferencesString("${KeyValue().ISFEEDBACK}_time");
      int? millitime = await DataStore().getSharedPreferencesInt("${KeyValue().ISFEEDBACK}_millitime");

      if (response.actionId == 'yes_action' || response.actionId == 'no_action') {
        if (response.actionId == 'yes_action') {
          await DataStore().saveSharedPreferencesBool("Purpose", true);
          await DataStore().saveData(KeyValue().ID, '${KeyValue().Chat}/$time', {
            KeyValue().CHAT_ID: KeyValue().AGENT,
            KeyValue().CONTENT: content,
            KeyValue().TIMESTAMP: time,
            KeyValue().MILLITIMESTAMP: millitime,
            "Purpose": true,
            "Reasone": "null",
          });
          print("click yes");
        } else if (response.actionId == 'no_action') {
          await DataStore().saveSharedPreferencesBool("Purpose", false);
          await DataStore().saveData(KeyValue().ID, '${KeyValue().Chat}/$time', {
            KeyValue().CHAT_ID: KeyValue().AGENT,
            KeyValue().CONTENT: content,
            KeyValue().TIMESTAMP: time,
            KeyValue().MILLITIMESTAMP: millitime,
            "Purpose": false,
            "Reasone": "null",
          });
          print("click no");
        }

        String? text = await DataStore().getSharedPreferencesString(KeyValue().ISFEEDBACK);
        text ??= "오류입니다. 아무 응답 후, 넘어가주세요.";
        await LocalNotification.showOngoingNotification(
          title: '피드백을 해주세요.',
          body: text,
          payload: "6",
        );
      } else if (response.actionId == 'correct_reason' || response.actionId == 'incorrect_reason') {
        print("User selected reason response: ${response.actionId}");

        bool? purpose = await DataStore().getSharedPreferencesBool("Purpose");

        if (response.actionId == 'correct_reason') {
          await DataStore().saveData(KeyValue().ID, '${KeyValue().Chat}/$time', {
            KeyValue().CHAT_ID: KeyValue().AGENT,
            KeyValue().CONTENT: content,
            KeyValue().TIMESTAMP: time,
            KeyValue().MILLITIMESTAMP: millitime,
            "Purpose": purpose,
            "Reasone": true,
          });
          print("click yes");
        } else if (response.actionId == 'incorrect_reason') {
          await DataStore().saveData(KeyValue().ID, '${KeyValue().Chat}/$time', {
            KeyValue().CHAT_ID: KeyValue().AGENT,
            KeyValue().CONTENT: content,
            KeyValue().TIMESTAMP: time,
            KeyValue().MILLITIMESTAMP: millitime,
            "Purpose": purpose,
            "Reasone": false,
          });
          print("click no");
        }

        await LocalNotification.cancelNotificationByPayload(1);
        await LocalNotification.cancelNotificationByPayload(2);
        await LocalNotification.cancelNotificationByPayload(5);
      } else {
        print("No input received.");
      }
    } else {
      // 앱으로 이동하지 않도록 이 부분을 비워둡니다.
    }
  } catch (e) {
    print("Error handling notification response: $e");
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

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        // 비워두어서 앱이 실행되지 않도록 합니다.
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

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

    if (payload == "5") {
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
    } else if (payload == "6") {
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
      icon: (payload == "2" || payload == "5"|| payload == "6" || payload == "4") ? '@drawable/user' : '@drawable/gpt',
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
