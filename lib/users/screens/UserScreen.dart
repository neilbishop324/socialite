import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:prokit_socialv/model/SVUser.dart';
import 'package:prokit_socialv/models/SVCommentModel.dart';
import 'package:prokit_socialv/models/SVSearchModel.dart';
import 'package:prokit_socialv/screens/home/components/SVPostComponent.dart';
import 'package:prokit_socialv/service/auth.dart';
import 'package:prokit_socialv/service/firestore_service.dart';
import 'package:prokit_socialv/utils/SVConstants.dart';
import 'package:prokit_socialv/utils/Translations.dart';

import '../../../utils/SVCommon.dart';
import '../../screens/fragments/SVProfileFragment.dart';
import '../../screens/search/components/SVSearchCardComponent.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({Key? key, this.uid, this.title, this.listType})
      : super(key: key);

  @override
  State<UserScreen> createState() => _UserScreenState(uid, title, listType);
  final String? uid;
  final String? title;
  final int? listType;
}

class _UserScreenState extends State<UserScreen> {
  final String? uid;
  String? username;
  String? title;
  int? listType;

  _UserScreenState(this.uid, this.title, this.listType);

  List<SVSearchModel> list = [];
  List<UserDetails> userList = [];
  FirestoreService firestoreService = FirestoreService();

  @override
  void initState() {
    firestoreService.getUser(uid).then((user) => {
          setState(() {
            username = user?.name;
          })
        });
    getUsers();
    super.initState();
  }

  CollectionReference followersRef(String uid) {
    return FirebaseFirestore.instance
        .collection(CollectionPath().users)
        .doc(uid)
        .collection(CollectionPath().followers);
  }

  getUsers() async {
    if (uid == null) {
      return;
    }
    final allUsers = await firestoreService.getUsers();
    final userIds = allUsers.map((e) => e.id).toList();
    switch (listType) {
      case 1: //followers
        final userIdListSS = await followersRef(uid!).get();
        final ids =
            userIdListSS.docs.map((doc) => doc["id"] as String).toList();
        for (final id in ids) {
          final user = await firestoreService.getUser(id);
          if (user != null) {
            userList.add(user);
          }
        }
        break;
      case 2: //followings
        for (final id in userIds) {
          final userDoc = await followersRef(id).doc(uid!).get();
          if (userDoc.exists) {
            final user = await firestoreService.getUser(id);
            if (user != null) {
              userList.add(user);
            }
          }
        }
        break;
      default:
    }

    if (userList.length > 0) {
      list = userList
          .map((e) => SVSearchModel(
              name: e.name,
              profileImage: e.ppUrl,
              subTitle: e.bio,
              isOfficialAccount: false,
              id: e.id))
          .toList();
      setState(
        () {},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) => Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: svGetScaffoldColor(),
        appBar: AppBar(
          backgroundColor: svGetScaffoldColor(),
          title: Text(
              (title == null)
                  ? Translations().users.toLowerCase().capitalizeFirstLetter()
                  : title!,
              style: boldTextStyle(size: 20)),
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: context.iconColor),
        ),
        body: SingleChildScrollView(
            child: ListView.separated(
          padding: EdgeInsets.all(16),
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            return SVSearchCardComponent(element: list[index]).onTap(() {
              SVProfileFragment(
                uid: userList[index].id,
              ).launch(context);
            });
          },
          separatorBuilder: (BuildContext context, int index) {
            return Divider(height: 20);
          },
          itemCount: list.length,
        )),
      ),
    );
  }
}
