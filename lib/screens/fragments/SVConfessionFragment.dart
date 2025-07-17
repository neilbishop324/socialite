import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:prokit_socialv/main.dart';
import 'package:prokit_socialv/model/SVUser.dart';
import 'package:prokit_socialv/screens/confession/pages/ConfessionScreen.dart';
import 'package:prokit_socialv/screens/confession/pages/NewConfessionScreen.dart';
import 'package:prokit_socialv/model/Confession.dart';
import 'package:prokit_socialv/screens/credit/logic/in_app_service.dart';
import 'package:prokit_socialv/service/auth.dart';
import 'package:prokit_socialv/service/firestore_service.dart';
import 'package:prokit_socialv/utils/SVColors.dart';
import 'package:prokit_socialv/utils/Translations.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../../utils/Extensions.dart';
import '../../utils/SVCommon.dart';
import '../../utils/SVConstants.dart';

class SVConfessionFragment extends StatefulWidget {
  const SVConfessionFragment({Key? key}) : super(key: key);

  @override
  State<SVConfessionFragment> createState() => _SVConfessionFragmentState();
}

class _SVConfessionFragmentState extends State<SVConfessionFragment> {
  final s = Translations();

  String? userId;

  @override
  void initState() {
    userId = AuthService().getUid();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: svGetScaffoldColor(),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: svGetScaffoldColor(),
        iconTheme: IconThemeData(color: context.iconColor),
        title: Text(s.confessions, style: boldTextStyle(size: 20)),
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => NewConfessionScreen().launch(context),
        child: Icon(
          Icons.add,
          color: white,
        ),
        backgroundColor: SVAppColorPrimary,
      ),
      body: confessions(context),
    );
  }

  Widget confessions(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection(CollectionPath().confessions)
          .orderBy("timestamp", descending: true)
          .limit(40)
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData) {
          return Container(child: Align(child: CircularProgressIndicator()));
        }

        return MasonryGridView.builder(
          itemCount: snapshot.data!.docs.length,
          gridDelegate: SliverSimpleGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2),
          itemBuilder: (context, index) {
            DocumentSnapshot documentSnapshot = snapshot.data!.docs[index];
            Confession confessionData = Confession(
              documentSnapshot['title']! as String,
              documentSnapshot['description']! as String,
              documentSnapshot['isAnonym']! as bool,
              documentSnapshot['likeCount']! as int,
              documentSnapshot['giftCount']! as int,
              documentSnapshot['commentCount']! as int,
              documentSnapshot['id']! as String,
              documentSnapshot['userId']! as String,
              documentSnapshot['timestamp'],
            );
            return confession(context, confessionData);
          },
        ).paddingAll(6);
      },
    );
  }

  Widget confession(BuildContext context, Confession confession) {
    final randomColor = colors[confession.id.hashCode % colors.length];
    return InkWell(
      onTap: () =>
          ConfessionScreen(confessionId: confession.id).launch(context),
      child: Container(
        color: randomColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            (confession.isAnonym)
                ? Row(
                    children: anonymUser(confession),
                  )
                : nanAnonymUser(confession),
            Divider(
              thickness: 0.6,
              color: black,
            ).paddingSymmetric(vertical: 2),
            Text(
              confession.title,
              style: TextStyle(color: black),
            ),
            Divider(
              thickness: 0.6,
              color: black,
            ).paddingSymmetric(vertical: 2),
            Row(
              children: [
                Image.asset(
                  'images/socialv/icons/ic_Chat.png',
                  height: 14,
                  width: 14,
                  fit: BoxFit.cover,
                  color: black,
                ),
                Text(
                  confession.commentCount.toString(),
                  style: TextStyle(color: black),
                ).paddingLeft(3),
                InkWell(
                  child: likeButton(confession),
                  onTap: () {
                    setState(() {});
                  },
                ).paddingLeft(6),
                Text(
                  confession.likeCount.toString(),
                  style: TextStyle(color: black),
                ).paddingLeft(3),
                InkWell(
                  onTap: () => _sendGift(context, confession),
                  child: Image.asset(
                    'images/socialv/icons/gift-pngrepo-com.png',
                    width: 14,
                    height: 14,
                    color: black,
                  ),
                ).paddingLeft(6),
                Text(
                  confession.giftCount.toString(),
                  style: TextStyle(color: black),
                ).paddingLeft(3),
              ],
            ),
          ],
        ).paddingAll(8),
      ),
    ).cornerRadiusWithClipRRect(5).paddingAll(6);
  }

  List<Widget> anonymUser(Confession confession) {
    return [
      Container(
        color: black,
        child: Image.asset(
          'images/socialv/icons/user-pngrepo-com.png',
          width: 21,
          height: 21,
          color: white,
        ).paddingAll(5),
      ).cornerRadiusWithClipRRect(3),
      Text(
        s.anonim,
        style: TextStyle(color: black, fontSize: 14),
      ).paddingLeft(6)
    ];
  }

  Widget nanAnonymUser(Confession confession) {
    return FutureBuilder(
      future: FirestoreService().getUser(confession.userId),
      builder: (context, AsyncSnapshot<UserDetails?> snapshot) {
        final userImage = snapshot.data?.ppUrl;
        final userName = snapshot.data?.name;
        if (!snapshot.hasData || snapshot.data == null) {
          return Row(
            children: anonymUser(confession),
          );
        }

        return Row(
          children: [
            Image.network(
              userImage!,
              width: 30,
              height: 30,
              fit: BoxFit.fitHeight,
            ).cornerRadiusWithClipRRect(3),
            Text(
              userName!,
              style: TextStyle(color: black, fontSize: 14),
            ).paddingLeft(6)
          ],
        );
      },
    );
  }

  Widget likeButton(Confession confession) {
    return FutureBuilder(
      future: likeButtonFuture(confession),
      builder: (context, AsyncSnapshot<bool> snapshot) {
        return snapshot.data == true
            ? InkWell(
                onTap: () => likeEvent(false, confession),
                child: Image.asset('images/socialv/icons/ic_HeartFilled.png',
                    height: 14, width: 16, fit: BoxFit.fill),
              )
            : InkWell(
                onTap: () => likeEvent(true, confession),
                child: Image.asset(
                  'images/socialv/icons/ic_Heart.png',
                  height: 14,
                  width: 14,
                  fit: BoxFit.cover,
                  color: black,
                ),
              );
      },
    );
  }

  final _firestore = FirebaseFirestore.instance;

  Future<bool> likeButtonFuture(Confession confession) async {
    final snapshot = await _firestore
        .collection(CollectionPath().confessions)
        .doc(confession.id)
        .collection(CollectionPath().likes)
        .doc(AuthService().getUid())
        .get();
    return snapshot.exists;
  }

  Future<void> likeEvent(bool liked, Confession confession) async {
    await _firestore
        .collection(CollectionPath().confessions)
        .doc(confession.id)
        .update({"likeCount": FieldValue.increment(liked ? 1 : -1)});
    if (liked) {
      await _firestore
          .collection(CollectionPath().confessions)
          .doc(confession.id)
          .collection(CollectionPath().likes)
          .doc(userId)
          .set({"id": userId});
    } else {
      await _firestore
          .collection(CollectionPath().confessions)
          .doc(confession.id)
          .collection(CollectionPath().likes)
          .doc(userId)
          .delete();
    }
    setState(() {});
  }

  _sendGift(BuildContext context, Confession confession) async {
    await InAppService().showSendGiftDialog(context, confession.userId,
        confessionId: confession.id);
  }
}
