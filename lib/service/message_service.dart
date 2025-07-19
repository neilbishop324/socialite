import 'dart:io';

import 'package:background_fetch/background_fetch.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:prokit_socialv/service/auth.dart';
import 'package:prokit_socialv/service/firestore_service.dart';
import 'package:prokit_socialv/service/notification_request.dart';
import 'package:prokit_socialv/utils/SVConstants.dart';
import 'package:rxdart/rxdart.dart';

class MessageService {
  final messaging = FirebaseMessaging.instance;

  Future<void> ctrlFirebaseMessaging() async {
    final settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (kDebugMode) {
      print('Permission granted: ${settings.authorizationStatus}');
    }
  }

  Future<String?> getMessagingToken() async {
    String? token = await messaging.getToken();

    if (kDebugMode) {
      print('Registration Token=$token');
    }
    return token;
  }

  // ignore: close_sinks
  final messageStreamController = BehaviorSubject<RemoteMessage>();
  void foregroundListener() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Handling a foreground message: ${message.messageId}');
        print('Message data: ${message.data}');
        print('Message notification: ${message.notification?.title}');
        print('Message notification: ${message.notification?.body}');
      }

      messageStreamController.sink.add(message);
      MessageService messageService = MessageService();
      messageService.notificationInitialize();

      messageService.showNotification(
          id: 0,
          title: '${message.notification?.title}',
          body: '${message.notification?.body}');
    });
  }

  final _localNotificationService = FlutterLocalNotificationsPlugin();

  Future<void> notificationInitialize() async {
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@drawable/ic_stat_message');

    final DarwinInitializationSettings darwinInitializationSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final InitializationSettings settings = InitializationSettings(
        android: androidInitializationSettings,
        iOS: darwinInitializationSettings);

    await _localNotificationService.initialize(settings,
        onDidReceiveNotificationResponse: onDidReceiveNotificationResponse);
  }

  Future<NotificationDetails> notificationDetails() async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails('channel_id', 'channel_name',
            channelDescription: 'description',
            importance: Importance.max,
            priority: Priority.max,
            playSound: true);

    const DarwinNotificationDetails darwinNotificationDetails =
        DarwinNotificationDetails();

    return NotificationDetails(
        android: androidNotificationDetails, iOS: darwinNotificationDetails);
  }

  void _onDidReceiveLocalNotification(
      int id, String? title, String? body, String? payload) {
    print('id $id');
  }

  void onDidReceiveNotificationResponse(NotificationResponse details) {
    print('payload : ${details.payload}');
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    final details = await notificationDetails();
    await _localNotificationService.show(id, title, body, details);
  }

  void getTokenAndSaveIt() async {
    if (Platform.isIOS) {
      String? apnsToken = await messaging.getAPNSToken();
      if (apnsToken != null) {
        messaging.getToken().then((token) => {
              print("userToken: $token"),
              FirestoreService().setData(
                  CollectionPath().tokens,
                  AuthService().getUid(),
                  {"token": token, "id": AuthService().getUid()})
            });
      } else {
        await Future<void>.delayed(
          const Duration(
            seconds: 3,
          ),
        );
        apnsToken = await messaging.getAPNSToken();
        if (apnsToken != null) {
          messaging.getToken().then((token) => {
                print("userToken: $token"),
                FirestoreService().setData(
                    CollectionPath().tokens,
                    AuthService().getUid(),
                    {"token": token, "id": AuthService().getUid()})
              });
        }
      }
    } else {
      messaging.getToken().then((token) => {
            print("userToken: $token"),
            FirestoreService().setData(
                CollectionPath().tokens,
                AuthService().getUid(),
                {"token": token, "id": AuthService().getUid()})
          });
    }
  }
}

void sendPushMessage(String token, String body, String title) async {
  try {
    await PostCall().makeCall(token, title, body);
  } catch (e) {
    if (kDebugMode) {
      print("error push notification : $e");
    }
  }
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  if (kDebugMode) {
    print("Handling a background message: ${message.messageId}");
    print('Message data: ${message.data}');
    print('Message notification: ${message.notification?.title}');
    print('Message notification: ${message.notification?.body}');
  }
  MessageService messageService = MessageService();
  messageService.notificationInitialize();

  await messageService.showNotification(
      id: 0,
      title: '${message.notification?.title}',
      body: '${message.notification?.body}');
}

Future<void> addForegroundAndBackgroundMessageHandlers() async {
  MessageService messageService = MessageService();
  await messageService.ctrlFirebaseMessaging();
  messageService.foregroundListener();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  messageService.getTokenAndSaveIt();
}
