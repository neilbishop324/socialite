import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:prokit_socialv/firebase_options.dart';
import 'package:prokit_socialv/screens/SVSplashScreen.dart';
import 'package:prokit_socialv/service/message_service.dart';
import 'package:prokit_socialv/store/AppStore.dart';
import 'package:prokit_socialv/utils/AppTheme.dart';

AppStore appStore = AppStore();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await initialize();
  appStore.toggleDarkMode(value: false);
  await addForegroundAndBackgroundMessageHandlers();
  MobileAds.instance.initialize();
  runApp(const MyApp());
  const topic = 'app_promotion';
  await FirebaseMessaging.instance.subscribeToTopic(topic);
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _lastMessage = "";

  _MyAppState() {
    MessageService().messageStreamController.listen((message) {
      setState(() {
        if (message.notification != null) {
          _lastMessage = 'Received a notification message:'
              '\nTitle=${message.notification?.title},'
              '\nBody=${message.notification?.body},'
              '\nData=${message.data}';
        } else {
          _lastMessage = 'Received a data message: ${message.data}';
        }
        print(_lastMessage);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) => MaterialApp(
        scrollBehavior: SBehavior(),
        navigatorKey: navigatorKey,
        title: 'Socialite',
        debugShowCheckedModeBanner: false,
        theme: (appStore.isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme)
            .copyWith(),
        darkTheme: AppTheme.darkTheme,
        themeMode: appStore.isDarkMode ? ThemeMode.dark : ThemeMode.light,
        home: SVSplashScreen(),
      ),
    );
  }
}
