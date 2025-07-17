import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:prokit_socialv/main.dart';
import 'package:prokit_socialv/model/SVUser.dart';
import 'package:prokit_socialv/screens/auth/components/SVSignUpComponent.dart';
import 'package:prokit_socialv/screens/home/components/SVPostComponent.dart';
import 'package:prokit_socialv/screens/home/screens/MyPostScreen.dart';
import 'package:prokit_socialv/screens/message/screens/SVContactsScreen.dart';
import 'package:prokit_socialv/screens/message/screens/SVMessagesScreen.dart';
import 'package:prokit_socialv/screens/profile/edit/EditProfileScreen.dart';
import 'package:prokit_socialv/service/auth.dart';
import 'package:prokit_socialv/service/firestore_service.dart';
import 'package:prokit_socialv/service/localrules.dart';
import 'package:prokit_socialv/users/screens/UserScreen.dart';
import 'package:prokit_socialv/utils/AppTheme.dart';
import 'package:prokit_socialv/utils/Extensions.dart';
import 'package:prokit_socialv/utils/SVColors.dart';
import 'package:prokit_socialv/utils/SVCommon.dart';
import 'package:prokit_socialv/utils/SVConstants.dart';
import 'package:prokit_socialv/model/Notification.dart' as Notif;

import '../../utils/Translations.dart';
import '../auth/screens/SVSignInScreen.dart';

class SVProfileFragment extends StatefulWidget {
  const SVProfileFragment({Key? key, this.uid}) : super(key: key);

  final String? uid;

  @override
  State<SVProfileFragment> createState() => _SVProfileFragmentState(uid);
}

class _SVProfileFragmentState extends State<SVProfileFragment> {
  LocalRules localRules = LocalRules();
  AuthService authService = AuthService();
  FirestoreService firestoreService = FirestoreService();
  bool? darkTheme = false;
  final String? uid;
  final borderRadius = BorderRadius.circular(100); // Image border

  String imageLink = SVConstants.imageLinkDefault;
  String bgImageLink = SVConstants.backgroundLinkDefault;
  String name = 'Mal Nurrisht';
  String username = 'malnur123';
  UserDetails? userModel;
  final s = Translations();

  Color aboutContainerColor = appStore.isDarkMode
      ? Color.fromARGB(255, 44, 45, 49)
      : Color.fromARGB(255, 221, 221, 225);

  Color oppositeColor = appStore.isDarkMode ? Colors.white : Colors.black;

  int loginType = 0;
  int postSize = 0;
  int followingSize = 0;
  int followersSize = 0;

  _SVProfileFragmentState(this.uid);

  @override
  void initState() {
    setStatusBarColor(Colors.transparent);
    localRules.getSharedPref().then((sharedPref) => {
          darkTheme = sharedPref.getBool("darkMode"),
          loginType = localRules.loginTypeState(sharedPref)
        });
    getFollowersSize();
    getUserInfo();
    getUserInfoSize();
    ctrlIfUserFollowing();
    super.initState();
  }

  getUserInfoSize() {
    firestoreService.getUserFollowingSize(uid).then((size) => {
          setState(() {
            followingSize = size;
          })
        });
  }

  getFollowersSize() {
    firestoreService
        .getCollSize(
            "${CollectionPath().users}/$uid/${CollectionPath().followers}")
        .then((size) => {followersSize = size});
  }

  getUserInfo() {
    firestoreService.getUser(uid).then((user) {
      if (user != null) {
        setState(() {
          name = user.name;
          username = user.username;
          imageLink = user.ppUrl;
          bgImageLink = user.bgUrl;
          userModel = user;
        });
        firestoreService
            .getCollSize(CollectionPath().posts,
                uid: userModel!.id, queryName: "posterName")
            .then((size) => {
                  setState(() {
                    postSize = size;
                  })
                });
      }
    });
  }

  setThemeColors() {
    aboutContainerColor = appStore.isDarkMode
        ? Color.fromARGB(255, 44, 45, 49)
        : Color.fromARGB(255, 221, 221, 225);
    oppositeColor = appStore.isDarkMode ? Colors.white : Colors.black;
  }

  bool blocked = false;

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) => Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: svGetScaffoldColor(),
        appBar: AppBar(
          automaticallyImplyLeading: (uid != AuthService().getUid()),
          backgroundColor: svGetScaffoldColor(),
          title: Text(s.profile, style: boldTextStyle(size: 20)),
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: context.iconColor),
          actions: [
            Visibility(
                visible: authService.getUid() == uid,
                child: IconButton(
                    icon: Image.asset(
                      appStore.isDarkMode
                          ? 'images/socialv/icons/ic_moon.png'
                          : 'images/socialv/icons/ic_sun.png',
                      width: 24,
                      height: 22,
                      fit: BoxFit.fill,
                      color: context.iconColor,
                    ),
                    onPressed: () async {
                      darkTheme = (darkTheme == null) ? false : !darkTheme!;
                      appStore.toggleDarkMode(value: darkTheme);
                      localRules.getSharedPref().then((sharedPref) =>
                          {sharedPref.setBool("darkMode", darkTheme!)});
                      setThemeColors();
                    })),
            Visibility(
              visible: authService.getUid() != uid,
              child: PopupMenuButton<int>(
                onSelected: (item) => handleClick(item),
                itemBuilder: (context) => [
                  PopupMenuItem<int>(
                      value: 0, child: Text((blocked) ? s.unblock : s.unblock)),
                  PopupMenuItem<int>(value: 1, child: Text(s.report)),
                ],
              ),
            )
          ],
        ),
        body: bodyWidget(context),
      ),
    );
  }

  handleClick(int i) {
    switch (i) {
      case 0:
        blocked = !blocked;
        blockEvent(blocked);
        break;
      case 1:
        reportEvent();
        break;
      default:
    }
  }

  reportEvent() {
    FirebaseFirestore.instance
        .collection(CollectionPath().reportedUsers)
        .doc(uid)
        .set({"id": uid}).then((value) => {showToast(s.usReported)});
  }

  blockEvent(bool blocked) {
    if (authService.getUid() != null) {
      if (blocked) {
        FirebaseFirestore.instance
            .collection(CollectionPath().users)
            .doc(authService.getUid()!)
            .collection(CollectionPath().blockedUsers)
            .doc(uid)
            .set({"id": uid}).then((value) => {showToast(s.usBlocked)});
      } else {
        FirebaseFirestore.instance
            .collection(CollectionPath().users)
            .doc(authService.getUid()!)
            .collection(CollectionPath().blockedUsers)
            .doc(uid)
            .delete()
            .then((value) => {showToast(s.usUnblocked)});
      }
    }
  }

  Widget bodyWidget(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        body: Container(
            height: MediaQuery.of(context).size.height,
            child: SingleChildScrollView(
                child: Column(
              children: [
                profileHeader(context),
                Text(
                  name,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                ).paddingTop(12),
                Text(
                  '@' + username,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ).paddingTop(6),
                bioLayout(context),
                messageLayout(context),
                interactionsLayout(context),
                accountInfo(context),
                Visibility(
                    visible: authService.getUid() == uid,
                    child: extraButtons(context))
              ],
            ).paddingBottom(32))));
  }

  bool userIsFollowing = false;

  ctrlIfUserFollowing() async {
    if (authService.getUid() != uid &&
        authService.getUid() != null &&
        uid != null) {
      final ss = await FirebaseFirestore.instance
          .collection(CollectionPath().users)
          .doc(uid!)
          .collection(CollectionPath().followers)
          .doc(authService.getUid())
          .get();

      userIsFollowing = ss.exists;
    }
  }

  followEvent() async {
    setState(() {
      userIsFollowing = !userIsFollowing;
      getFollowersSize();
    });
    final docRef = FirebaseFirestore.instance
        .collection(CollectionPath().users)
        .doc(uid!)
        .collection(CollectionPath().followers)
        .doc(authService.getUid());
    if (userIsFollowing) {
      docRef.set({"id": authService.getUid()!});
      final id = Extensions.generateRandomString(10);
      final notification = Notif.Notification(
          userId: AuthService().getUid()!,
          type: 2,
          postId: null,
          id: id,
          timeForMillis: DateTime.now().millisecondsSinceEpoch);
      await FirebaseFirestore.instance
          .collection(CollectionPath().users)
          .doc(uid!)
          .collection(CollectionPath().notifications)
          .doc(notification.id)
          .set(notification.toJson());
    } else {
      docRef.delete();
    }
  }

  Widget messageLayout(BuildContext context) {
    return Visibility(
        visible: authService.getUid() != uid,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            actionButton(
                context,
                "images/socialv/icons/message-2-pngrepo-com.png",
                s.tr ? "Sohbet Et" : "Message",
                () => {SVMessagesScreen(uid: uid).launch(context)}),
            20.width,
            actionButton(
                context,
                "images/socialv/icons/user-follow-pngrepo-com.png",
                (userIsFollowing)
                    ? (s.tr ? "Takipten Çık" : "Unfollow")
                    : (s.tr ? "Takip Et" : "Follow"),
                () => {followEvent()})
          ],
        ).paddingTop(16));
  }

  Widget actionButton(BuildContext context, String imagePath, String title,
      Function() onClick) {
    return ElevatedButton(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.resolveWith<Color>(
          (Set<MaterialState> states) {
            if (states.contains(MaterialState.pressed)) {
              // Add a different color when the button is pressed, if desired
              return (appStore.isDarkMode)
                  ? Color.fromARGB(255, 64, 65, 69) // Dark mode pressed color
                  : Colors.lightBlue; // Light mode pressed color
            }
            return (appStore.isDarkMode)
                ? Color.fromARGB(255, 44, 45, 49) // Dark mode color
                : Colors.blue; // Light mode color
          },
        ),
      ),
      onPressed: () {
        onClick();
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            imagePath,
            height: 20,
            width: 20,
            color: white,
          ),
          12.width,
          Text(
            title,
            style: TextStyle(color: white),
          )
        ],
      ),
    );
  }

  Widget bioLayout(BuildContext context) {
    return Text(
      (userModel != null) ? userModel!.bio : "",
      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
    ).paddingTop((userModel != null) ? 12 : 0).paddingSymmetric(horizontal: 16);
  }

  Widget profileHeader(BuildContext context) {
    return SizedBox(
      height: 180,
      child: Stack(
        children: <Widget>[
          Image.network(
            bgImageLink,
            height: 150,
          ),
          Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: 100.0,
                height: 100.0,
                decoration: BoxDecoration(
                  image: DecorationImage(
                      fit: BoxFit.cover, image: NetworkImage(imageLink)),
                  borderRadius: BorderRadius.all(Radius.circular(20.0)),
                  color: Colors.redAccent,
                ),
              ))
        ],
      ),
    );
  }

  final interactionsColor =
      appStore.isDarkMode ? Colors.grey : Color.fromARGB(255, 106, 106, 106);

  Widget interactionsLayout(BuildContext context) {
    return Row(
      children: [
        mSafeArea(context, [
          Text(s.posts,
              style: TextStyle(
                  color: interactionsColor, fontWeight: FontWeight.bold)),
          Text(postSize.toString(),
              style: TextStyle(fontWeight: FontWeight.bold))
        ], (() {
          MyPostScreen(uid: uid).launch(context);
        })),
        mSafeArea(context, [
          Text(s.followers,
              style: TextStyle(
                  color: interactionsColor, fontWeight: FontWeight.bold)),
          Text(followersSize.toString(),
              style: TextStyle(fontWeight: FontWeight.bold))
        ], (() {
          UserScreen(
                  uid: uid,
                  title: (uid == authService.getUid())
                      ? s.myFollowers
                      : name + " " + s.sFollowers,
                  listType: 1)
              .launch(context);
        })),
        mSafeArea(context, [
          Text(s.followings,
              style: TextStyle(
                  color: interactionsColor, fontWeight: FontWeight.bold)),
          Text(followingSize.toString(),
              style: TextStyle(fontWeight: FontWeight.bold))
        ], (() {
          UserScreen(
                  uid: uid,
                  title: (uid == authService.getUid())
                      ? s.myFollowings
                      : name + " " + s.sFollowings,
                  listType: 2)
              .launch(context);
        })),
      ],
    ).paddingTop(32);
  }

  Widget mSafeArea(
      BuildContext context, List<Widget> children, Function() onClick) {
    return InkWell(
        onTap: () {
          onClick();
        },
        child: SafeArea(
            child: Container(
                width: MediaQuery.of(context).size.width / 3 - 16,
                height: 70,
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: children,
                )).paddingSymmetric(horizontal: 8)));
  }

  Widget accountInfo(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          border: Border.all(
            color: aboutContainerColor,
          ),
          borderRadius: BorderRadius.all(Radius.circular(10)),
          color: aboutContainerColor),
      width: MediaQuery.of(context).size.width,
      child: Column(
        children: new List.from([
          Center(
            child: infoItem("images/socialv/icons/ic_about.png",
                s.tr ? "Hakkında" : "About",
                center: true),
          )
        ])
          ..addAll(infosLay(context)),
      ).paddingBottom(12),
    ).paddingTop(32).paddingSymmetric(horizontal: 32);
  }

  List<Widget> infosLay(BuildContext context) {
    return [
      infoItem("images/socialv/icons/gender-pngrepo-com.png",
          s.gender + ": " + ((userModel != null) ? userModel!.gender : "")),
      infoItem("images/socialv/icons/birthday-card-pngrepo-com.png",
          s.birthday + ": " + ((userModel != null) ? userModel!.birthDay : "")),
      infoItem(
          "images/socialv/icons/location-pngrepo-com.png",
          s.location +
              ": " +
              ((userModel != null)
                  ? userModel!.location.city +
                      ((userModel!.location.city.length != 0) ? ", " : "") +
                      userModel!.location.state +
                      ((userModel!.location.state.length != 0) ? ", " : "") +
                      userModel!.location.country
                  : "")),
      Visibility(
          visible: authService.getUid() == uid, child: editProfile(context)),
      Visibility(visible: authService.getUid() != uid, child: 16.height)
    ];
  }

  Widget infoItem(String iconPath, String title, {bool center = false}) {
    return Row(children: [
      Image.asset(
        iconPath,
        width: 25,
        color: Theme.of(context).disabledColor,
      ).paddingRight(8).paddingLeft((center) ? 0 : 16),
      Flexible(
          child: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ))
    ], mainAxisSize: (center) ? MainAxisSize.min : MainAxisSize.max)
        .paddingTop(16);
  }

  Widget editProfile(BuildContext context) {
    return ElevatedButton(
      child: Row(children: [
        Image.asset(
          "images/socialv/icons/edit-pngrepo-com.png",
          width: 20,
          height: 20,
          color: appStore.isDarkMode ? Colors.white : null,
        ).paddingRight(6),
        Text(
          s.editProfile,
          style: TextStyle(color: appStore.isDarkMode ? Colors.white : null),
        )
      ], mainAxisSize: MainAxisSize.min),
      onPressed: () => {EditProfileScreen().launch(context)},
    ).paddingTop(8);
  }

  Widget extraButtons(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () => {
            authService.signOut().then((dynamic) {
              Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => SVSignInScreen()),
                  (route) => false);
            })
          },
          child: Row(
            children: [
              Image.asset("images/socialv/icons/ic_Logout.png",
                      width: 20, height: 20, color: Colors.grey)
                  .paddingRight(6),
              Text(
                s.logout,
                style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold),
              )
            ],
            mainAxisSize: MainAxisSize.min,
          ),
        ),
        Container(
          width: MediaQuery.of(context).size.width - 64,
          height: 1,
          color: aboutContainerColor,
        ).paddingSymmetric(horizontal: 32).paddingTop(16),
        InkWell(
          onTap: () => {
            Extensions().showAlertDialog(
                context, s.deleteAccount, s.deleteAccDetails, s.yes, () {
              deleteAccount();
            }),
          },
          child: Row(
            children: [
              Image.asset("images/socialv/icons/close-pngrepo-com.png",
                      width: 20, height: 20, color: Colors.red)
                  .paddingRight(6),
              Text(
                s.deleteAccount,
                style: TextStyle(
                    fontSize: 18,
                    color: Colors.red,
                    fontWeight: FontWeight.bold),
              )
            ],
            mainAxisSize: MainAxisSize.min,
          ),
        ).paddingTop(24),
        Container(
          width: MediaQuery.of(context).size.width - 64,
          height: 1,
          color: aboutContainerColor,
        ).paddingSymmetric(horizontal: 32).paddingTop(16)
      ],
    ).paddingTop(48);
  }

  deleteAccount() {
    if (userModel != null) {
      switch (loginType) {
        default:
          Extensions.showInformationDialog(
              context,
              s.deleteDetailDialog,
              "Email",
              s.password,
              s.delete,
              (userLogInfo) => {
                    authService
                        .deleteUserWithEmail(
                            userLogInfo.email, userLogInfo.password)
                        .then((success) => {
                              if (success) {deleteFromFirebase()}
                            })
                  });
          break;
      }
    }
  }

  withCredentials(AuthCredential? value) {
    if (value != null) {
      try {
        authService.deleteUserWithCredential(value);
      } catch (e) {
        print(e);
      }
    }
  }

  deleteFromFirebase() async {
    await firestoreService.deleteuser(userModel!.id);
    showToast(s.usDeleted);
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => SVSignInScreen()),
        (route) => false);
  }
}
