// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

Future<void> handlerBackgroundMessage(RemoteMessage message) async {
  print("Title: ${message.notification?.title}");
  print("Body: ${message.notification?.body}");
  print("Payload: ${message.data}");
}

class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;

  final _androidChannel = const AndroidNotificationChannel(
      'high_importance_channel', 'High Importance Notifications',
      description: 'This channel is used for important notification',
      importance: Importance.defaultImportance);

  final _localNotifications = FlutterLocalNotificationsPlugin();

  Future initPushNotifications() async {
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
            alert: true, badge: true, sound: true);
    FirebaseMessaging.instance.getInitialMessage().then(handleMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(handleMessage);
    FirebaseMessaging.onBackgroundMessage(handlerBackgroundMessage);
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;
      _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _androidChannel.id,
              _androidChannel.name,
              channelDescription: _androidChannel.description,
              icon: '@drawable/ic_launcher',
            ),
          ),
          payload: jsonEncode(message.toMap()));
    });
  }

  Future<void> initNotifications() async {
    await _firebaseMessaging.requestPermission();
    final fcmToken = await _firebaseMessaging.getToken();

    if (kDebugMode) {
      print("MyToken $fcmToken");
    }

    initPushNotifications();
    initLocalNotifications();
  }


Future initLocalNotifications() async {
  const iOS = DarwinInitializationSettings();
  const android = AndroidInitializationSettings('@drawable/ic_launcher');
  const settings = InitializationSettings(android: android, iOS: iOS);
  await _localNotifications.initialize(settings, onDidReceiveNotificationResponse: (response) {
    final payload = response.payload;
    if (payload != null) {
      final message = RemoteMessage.fromMap(jsonDecode(payload));
      handleMessage(message);
    }
  });

  final platform = _localNotifications.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();
  await platform?.createNotificationChannel(_androidChannel);
}

  // Future initLocalNotifications() async {
  //   const iOS = IOSInitializationSettings();
  //   const android = AndroidInitializationSettings('@drawable/ic_launcher');
  //   const setting = InitializationSettings(android: android, iOS: iOS);
  //   await _localNotifications.initialize(setting,
  //       onSelectNotification: (payload) {
  //     final message = RemoteMessage.fromMap(jsonDecode(payload!));
  //     handleMessage(message);
  //   });
  //   final platform = _localNotifications.resolvePlatformSpecificImplementation<
  //       AndroidFlutterLocalNotificationsPlugin>();
  //   await platform?.createNotificationChannel(_androidChannel);
  // }

  void handleMessage(RemoteMessage? message) {
    if (message == null) return;
  }

  void sendPushNotification(
    String title,
    String body,
    String token,
  ) async {
    try {
      await http.post(Uri.parse("https://fcm.googleapis.com/fcm/send"),
          headers: <String, String>{
            'Content-Type': 'application/json',
            'Authorization': 'key=${dotenv.get('fcmServerKey')}'
          },
          body: jsonEncode(<String, dynamic>{
            'priority': 'high',
            'data': <String, dynamic>{
              'click_action': 'FLUTTER_NOTIFICATIO_CLICK',
              'status': 'done',
              'body': body,
              'title': title
            },
            'notification': <String, dynamic>{
              'title': title,
              'body': body,
              'android_channel_id': 'high_importance_channel'
            },
            'to': token
          }));
    } catch (e) {
      if(kDebugMode){
      print("error push notification");

      }
    }
  }
}
