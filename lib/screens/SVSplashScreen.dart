import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:prokit_socialv/main.dart';
import 'package:prokit_socialv/screens/SVDashboardScreen.dart';
import 'package:prokit_socialv/screens/auth/screens/SVSignInScreen.dart';
import 'package:prokit_socialv/service/auth.dart';
import 'package:prokit_socialv/service/firestore_service.dart';
import 'package:prokit_socialv/service/localrules.dart';

class SVSplashScreen extends StatefulWidget {
  const SVSplashScreen({Key? key}) : super(key: key);

  @override
  State<SVSplashScreen> createState() => _SVSplashScreenState();
}

class _SVSplashScreenState extends State<SVSplashScreen> {
  AuthService authService = AuthService();
  LocalRules localRules = LocalRules();
  FirestoreService firestoreService = FirestoreService();
  bool doRemember = false;

  @override
  void initState() {
    init();
    super.initState();
  }

  Future<void> init() async {
    await firestoreService.deleteStories();
    await firestoreService.controlIfVip();
    await setStatusBarColor(Colors.transparent);
    await 3.seconds.delay;
    finish(context);
    localRules.getSharedPref().then((sharedPref) {
      doRemember = localRules.rememberMeState(sharedPref);
      if (doRemember && authService.userLoggedIn()) {
        SVDashboardScreen().launch(context);
      } else {
        SVSignInScreen().launch(context, isNewTask: true);
      }
      bool? darkMode = sharedPref.getBool("darkMode");
      appStore.toggleDarkMode(value: darkMode);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            'images/socialv/svSplashImage.jpg',
            height: context.height(),
            width: context.width(),
            fit: BoxFit.fill,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('images/socialv/svAppIcon.png',
                      height: 50, width: 52, fit: BoxFit.cover)
                  .cornerRadiusWithClipRRect(50),
              8.width,
              Text("Socialite",
                  style: primaryTextStyle(
                      color: Colors.white, size: 40, weight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}
