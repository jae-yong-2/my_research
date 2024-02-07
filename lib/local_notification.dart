import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotification{
  static final FlutterLocalNotificationsPlugin
    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  //알람시작/
  static Future init()async{
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    final DarwinInitializationSettings initializationSettingsDarwin =
    DarwinInitializationSettings(
        onDidReceiveLocalNotification: (id, title, body, payload)=>null);
    final LinuxInitializationSettings initializationSettingsLinux =
    LinuxInitializationSettings(
        defaultActionName: 'Open notification');
    final InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
        linux: initializationSettingsLinux);
    _flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse: (details)=> null
    );
  }
// initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project
  static Future showOngoingNotification({
    required String title,
    required String body,
    required String payload,
  }) async {
    const AndroidNotificationDetails androidNotificationDetails =
      AndroidNotificationDetails(
        'ongoing', 'ongoing',
        channelDescription: 'ongoing',
        importance: Importance.max,
        priority: Priority.high,
        ongoing: true,
        autoCancel: false);

    const NotificationDetails notificationDetails =
    NotificationDetails(android: androidNotificationDetails);
    await _flutterLocalNotificationsPlugin.show(
        0, title, body, notificationDetails, payload: payload);
  }
//update 기능
  // static Future showOngoingUpdateNotification({
  //   required String title,
  //   required String body,
  //   required String payload,
  // }) async {
  //
  //   const AndroidNotificationDetails androidNotificationDetails =
  //   AndroidNotificationDetails(
  //       'ongoing', 'ongoing',
  //       channelDescription: 'ongoing',
  //       importance: Importance.max,
  //       priority: Priority.high,
  //       ongoing: true,
  //       autoCancel: false,
  //       channelAction: AndroidNotificationChannelAction.update);
  //   const NotificationDetails notificationDetails = NotificationDetails(android: androidNotificationDetails);
  //   await _flutterLocalNotificationsPlugin.show( 0, title, body, notificationDetails, payload: payload);
  // }

}