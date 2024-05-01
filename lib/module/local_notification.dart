import 'package:flutter_local_notifications/flutter_local_notifications.dart';


@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  // handle action
  print(notificationResponse.actionId);
  print(notificationResponse.id);
  print(notificationResponse.input);
  print(notificationResponse.payload);
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
        onDidReceiveNotificationResponse: (NotificationResponse response) async {
          try {
            if (response.notificationResponseType == NotificationResponseType.selectedNotificationAction) {
              if (response.input != null) {
                print("User replied: ${response.input}");
                // 서버로 전송하는 함수 호출
              } else {
                print("No input received.");
              }
            }
          } catch (e) {
            print("Error handling notification response: $e");
            // 에러 처리 로직
          }
    },
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
