import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:prokit_socialv/screens/fragments/SVAddPostFragment.dart';
import 'package:prokit_socialv/screens/fragments/SVHomeFragment.dart';
import 'package:prokit_socialv/screens/fragments/SVNotificationFragment.dart';
import 'package:prokit_socialv/screens/fragments/SVProfileFragment.dart';
import 'package:prokit_socialv/screens/fragments/SVSearchFragment.dart';
import 'package:prokit_socialv/service/auth.dart';
import 'package:prokit_socialv/service/firestore_service.dart';
import 'package:prokit_socialv/utils/SVCommon.dart';
import 'package:prokit_socialv/utils/SVConstants.dart';

import 'fragments/SVConfessionFragment.dart';

class SVDashboardScreen extends StatefulWidget {
  @override
  State<SVDashboardScreen> createState() => _SVDashboardScreenState();
}

class _SVDashboardScreenState extends State<SVDashboardScreen> {
  int selectedIndex = 0;
  bool shouldPop = false;

  AuthService authService = AuthService();
  FirestoreService firestoreService = FirestoreService();
  String imageLink = SVConstants.imageLinkDefault;
  bool accountItemSelected = false;
  double borderForImage = 0;

  Widget getFragment() {
    if (selectedIndex == 0) {
      return SVHomeFragment();
    } else if (selectedIndex == 1) {
      return SVSearchFragment();
    } else if (selectedIndex == 2) {
      return SVConfessionFragment();
    } else if (selectedIndex == 4) {
      return SVNotificationFragment();
    } else if (selectedIndex == 5) {
      return SVProfileFragment(
        uid: AuthService().getUid(),
      );
    }
    return SVHomeFragment();
  }

  @override
  void initState() {
    setStatusBarColor(Colors.transparent);
    final uid = authService.getUid();
    firestoreService.getUser(uid).then((user) {
      if (user != null) {
        setState(() {
          imageLink = user.ppUrl;
        });
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return shouldPop;
      },
      child: Scaffold(
        backgroundColor: svGetScaffoldColor(),
        body: getFragment(),
        bottomNavigationBar: BottomNavigationBar(
          showSelectedLabels: false,
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
              icon: Image.asset('images/socialv/icons/ic_Home.png',
                      height: 24,
                      width: 24,
                      fit: BoxFit.cover,
                      color: context.iconColor)
                  .paddingTop(12),
              label: '',
              activeIcon: Image.asset(
                      'images/socialv/icons/ic_HomeSelected.png',
                      height: 24,
                      width: 24,
                      fit: BoxFit.cover)
                  .paddingTop(12),
            ),
            BottomNavigationBarItem(
              icon: Image.asset('images/socialv/icons/ic_Search.png',
                      height: 24,
                      width: 24,
                      fit: BoxFit.cover,
                      color: context.iconColor)
                  .paddingTop(12),
              label: '',
              activeIcon: Image.asset(
                      'images/socialv/icons/ic_SearchSelected.png',
                      height: 24,
                      width: 24,
                      fit: BoxFit.cover)
                  .paddingTop(12),
            ),
            BottomNavigationBarItem(
              icon: Image.asset('images/socialv/icons/confession.png',
                      height: 24,
                      width: 24,
                      fit: BoxFit.cover,
                      color: context.iconColor)
                  .paddingTop(12),
              label: '',
              activeIcon: Image.asset(
                      'images/socialv/icons/confession_Selected.png',
                      height: 24,
                      width: 24,
                      fit: BoxFit.cover)
                  .paddingTop(12),
            ),
            BottomNavigationBarItem(
              icon: Image.asset('images/socialv/icons/ic_Plus.png',
                      height: 24,
                      width: 24,
                      fit: BoxFit.cover,
                      color: context.iconColor)
                  .paddingTop(12),
              label: '',
              activeIcon: Image.asset(
                      'images/socialv/icons/ic_PlusSelected.png',
                      height: 24,
                      width: 24,
                      fit: BoxFit.cover)
                  .paddingTop(12),
            ),
            BottomNavigationBarItem(
              icon: Image.asset('images/socialv/icons/ic_Notification.png',
                      height: 24,
                      width: 24,
                      fit: BoxFit.cover,
                      color: context.iconColor)
                  .paddingTop(12),
              label: '',
              activeIcon: Image.asset(
                      'images/socialv/icons/ic_NotificationSelected.png',
                      height: 24,
                      width: 24,
                      fit: BoxFit.cover)
                  .paddingTop(12),
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: EdgeInsets.all(borderForImage),
                decoration: BoxDecoration(
                    color: Color.fromARGB(255, 16, 1, 146),
                    shape: BoxShape.circle),
                child: ClipOval(
                  child: SizedBox.fromSize(
                    size: Size.fromRadius(15),
                    child: Image.network(
                      imageLink,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ).paddingTop(12),
              label: '',
              activeIcon: Container(
                padding: EdgeInsets.all(borderForImage),
                decoration: BoxDecoration(
                    color: Color.fromARGB(255, 16, 1, 146),
                    shape: BoxShape.circle),
                child: ClipOval(
                  child: SizedBox.fromSize(
                    size: Size.fromRadius(15),
                    child: Image.network(
                      imageLink,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ).paddingTop(12),
            ),
          ],
          onTap: (val) {
            selectedIndex = val;
            setState(() {
              accountItemSelected = val == 5;
              borderForImage = (accountItemSelected) ? 2 : 0;
            });
            if (val == 3) {
              selectedIndex = 0;
              setState(() {});
              SVAddPostFragment(
                postContextId: "Public",
              ).launch(context);
            }
          },
          currentIndex: selectedIndex,
        ),
      ),
    );
  }
}
