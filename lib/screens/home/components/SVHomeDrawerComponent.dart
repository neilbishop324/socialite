import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:prokit_socialv/models/SVCommonModels.dart';
import 'package:prokit_socialv/screens/auth/screens/SVSignInScreen.dart';
import 'package:prokit_socialv/screens/credit/pages/BecomeVipScreen.dart';
import 'package:prokit_socialv/screens/credit/pages/PurchasePackageScreen.dart';
import 'package:prokit_socialv/screens/fragments/SVProfileFragment.dart';
import 'package:prokit_socialv/screens/home/screens/MyPostScreen.dart';
import 'package:prokit_socialv/screens/profile/screens/SVGroupProfileScreen.dart';
import 'package:prokit_socialv/screens/stream/pages/StreamsScreen.dart';
import 'package:prokit_socialv/service/auth.dart';
import 'package:prokit_socialv/service/firestore_service.dart';
import 'package:prokit_socialv/service/localrules.dart';
import 'package:prokit_socialv/utils/SVColors.dart';
import 'package:prokit_socialv/utils/SVCommon.dart';
import 'package:prokit_socialv/utils/SVConstants.dart';
import 'package:prokit_socialv/utils/Translations.dart';
import 'package:share_plus/share_plus.dart';

import '../../../users/screens/UserScreen.dart';

class SVHomeDrawerComponent extends StatefulWidget {
  @override
  State<SVHomeDrawerComponent> createState() => _SVHomeDrawerComponentState();
}

class _SVHomeDrawerComponentState extends State<SVHomeDrawerComponent> {
  List<SVDrawerModel> options = getDrawerOptions();
  AuthService authService = AuthService();
  LocalRules localRules = LocalRules();
  FirestoreService firestoreService = FirestoreService();

  String name = 'Mal Nurrisht';
  String username = 'malnur123';
  String imageLink = SVConstants.imageLinkDefault;

  int selectedIndex = -1;

  @override
  void initState() {
    final uid = authService.getUid();
    firestoreService.getUser(uid).then((user) {
      if (user != null) {
        setState(() {
          name = user.name;
          username = user.username;
          imageLink = user.ppUrl;
        });
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        50.height,
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CachedNetworkImage(
                  imageUrl: imageLink,
                  height: 62,
                  width: 62,
                  fit: BoxFit.cover,
                ).cornerRadiusWithClipRRect(8),
                16.width,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(name, style: boldTextStyle(size: 18)),
                    8.height,
                    Text(username,
                        style: secondaryTextStyle(color: svGetBodyColor())),
                  ],
                ),
              ],
            ),
            IconButton(
              icon: Image.asset('images/socialv/icons/ic_CloseSquare.png',
                  height: 16,
                  width: 16,
                  fit: BoxFit.cover,
                  color: context.iconColor),
              onPressed: () {
                finish(context);
              },
            ),
          ],
        ).paddingOnly(left: 16, right: 8, bottom: 20, top: 20),
        20.height,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((e) {
            int index = options.indexOf(e);
            return SettingItemWidget(
              decoration: BoxDecoration(
                  color: selectedIndex == index
                      ? SVAppColorPrimary.withAlpha(30)
                      : context.cardColor),
              title: e.title.validate(),
              titleTextStyle: boldTextStyle(size: 14),
              leading: Image.asset(e.image.validate(),
                  height: 22,
                  width: 22,
                  fit: BoxFit.cover,
                  color: SVAppColorPrimary),
              onTap: () async {
                selectedIndex = index;
                setState(() {});
                switch (selectedIndex) {
                  case 0: //Profile
                    _openProfile();
                    break;
                  case 1: //Followings
                    _openFollowings();
                    break;
                  case 2: //Groups
                    finish(context);
                    SVGroupProfileScreen().launch(context);
                    break;
                  case 3: //Live Streams
                    finish(context);
                    StreamsScreen().launch(context);
                    break;
                  case 4: //Saved Posts
                    _openSavedPosts();
                    break;
                  case 5: //Become Vip
                    BecomeVipScreen().launch(context);
                    break;
                  case 6: //Purchase Credit
                    PurchasePackageScreen().launch(context);
                    break;
                  case 7: //Share App
                    PackageInfoData packageInfo = await getPackageInfo();
                    String? packageName = packageInfo.packageName;
                    String shareLink =
                        "https://play.google.com/store/apps/details?id=$packageName";
                    Share.share(shareLink);
                    break;
                  case 8: //Logout
                    _logOut();
                    break;
                  default:
                }
              },
            );
          }).toList(),
        ).expand(),
        Divider(indent: 16, endIndent: 16),
        SnapHelperWidget<PackageInfo>(
          future: PackageInfo.fromPlatform(),
          onSuccess: (data) =>
              Text(data.version, style: boldTextStyle(color: svGetBodyColor())),
        ),
        20.height,
      ],
    );
  }

  _logOut() {
    authService.signOut().then((dynamic) {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => SVSignInScreen()),
          (route) => false);
    });
  }

  _openProfile() {
    finish(context);
    SVProfileFragment(
      uid: AuthService().getUid(),
    ).launch(context);
  }

  _openFollowings() {
    finish(context);
    UserScreen(
            uid: authService.getUid(),
            title: Translations().myFollowings,
            listType: 2)
        .launch(context);
  }

  _openSavedPosts() {
    finish(context);
    MyPostScreen(uid: AuthService().getUid(), fromSaved: true).launch(context);
  }
}
