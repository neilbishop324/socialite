import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:prokit_socialv/model/Confession.dart';
import 'package:prokit_socialv/models/SVPostModel.dart';
import 'package:prokit_socialv/screens/confession/widgets/Loading.dart';
import 'package:prokit_socialv/screens/credit/logic/in_app_service.dart';
import 'package:prokit_socialv/service/firestore_service.dart';
import 'package:prokit_socialv/utils/Translations.dart';

import '../../../main.dart';
import '../../../model/SVComment.dart';
import '../../../model/SVUser.dart';
import '../../../models/SVCommentModel.dart';
import '../../../service/auth.dart';
import '../../../utils/Extensions.dart';
import '../../../utils/SVColors.dart';
import '../../../utils/SVCommon.dart';
import '../../../utils/SVConstants.dart';
import 'package:share_plus/share_plus.dart';

class ConfessionScreen extends StatefulWidget {
  const ConfessionScreen({Key? key, required this.confessionId})
      : super(key: key);
  final String confessionId;

  @override
  State<ConfessionScreen> createState() => _ConfessionScreenState();
}

class _ConfessionScreenState extends State<ConfessionScreen> {
  final s = Translations();
  final oppositeColor = (appStore.isDarkMode) ? white : black;

  String? confessionId;
  String? userId;

  final commentController = TextEditingController();
  UserDetails? userModel;

  @override
  void initState() {
    confessionId = widget.confessionId;
    userId = AuthService().getUid();
    _init();
    super.initState();
  }

  _init() async {
    if (confessionId == null) {
      return;
    }
    userModel = await FirestoreService().getUser(userId);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          s.confession,
          style: TextStyle(color: oppositeColor),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: oppositeColor),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection(CollectionPath().confessions)
            .doc(confessionId)
            .snapshots(),
        builder: (context,
            AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> snapshot) {
          if (!snapshot.hasData || snapshot.data == null) {
            return Loading();
          }
          Confession confession = Confession.fromMap(snapshot.data!.data()!);
          return Stack(
            alignment: Alignment.bottomCenter,
            children: [
              SafeArea(
                child: SizedBox(
                  height: double.infinity,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          color: colors[confession.id.hashCode % colors.length],
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                confession.title,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24,
                                    color: black),
                              ).paddingBottom(16),
                            ]..addAll(confessionWidget(context, confession)),
                          ).paddingAll(16),
                        ).cornerRadiusWithClipRRect(16).paddingAll(16),
                        actionLayout(confession),
                        commentSection(confession),
                      ],
                    ).paddingTop(8),
                  ),
                ),
              ).paddingBottom(70),
              commentLayout(confession)
            ],
          );
        },
      ),
    );
  }

  List<Widget> confessionWidget(BuildContext context, Confession confession) {
    return [
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
        confession.description,
        style: TextStyle(color: black, fontSize: 17),
      ),
    ];
  }

  Widget actionLayout(Confession confession) {
    final straightColor = black;
    return Container(
      color: appStore.isDarkMode ? white : Color(0xffffce81),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () => _shareConfession(confession),
                child: Icon(
                  Icons.share,
                  color: straightColor,
                ),
              ).paddingBottom(4),
              Text(
                s.share,
                style: TextStyle(color: straightColor),
              )
            ],
          ),
          Spacer(),
          InkWell(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                likeButton(confession, straightColor).paddingBottom(4),
                Text(
                  s.like,
                  style: TextStyle(color: straightColor),
                )
              ],
            ),
            onTap: () {
              setState(() {});
            },
          ),
          Spacer(),
          InkWell(
            onTap: () => _sendGift(context, confession),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'images/socialv/icons/gift-pngrepo-com.png',
                  width: 30,
                  height: 30,
                  color: straightColor,
                ).paddingBottom(4),
                Text(
                  s.giveGift,
                  style: TextStyle(color: straightColor),
                )
              ],
            ),
          ),
        ],
      ).paddingSymmetric(vertical: 24, horizontal: 32),
    ).cornerRadiusWithClipRRect(16).paddingAll(16);
  }

  Widget likeButton(Confession confession, Color straightColor) {
    return FutureBuilder(
      future: likeButtonFuture(confession),
      builder: (context, AsyncSnapshot<bool> snapshot) {
        return snapshot.data == true
            ? InkWell(
                onTap: () => likeEvent(false, confession),
                child: Image.asset('images/socialv/icons/ic_HeartFilled.png',
                    color: redColor, height: 30, width: 30, fit: BoxFit.fill),
              )
            : InkWell(
                onTap: () => likeEvent(true, confession),
                child: Image.asset(
                  'images/socialv/icons/ic_Heart.png',
                  height: 30,
                  width: 30,
                  fit: BoxFit.cover,
                  color: straightColor,
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

  List<Widget> anonymUser(Confession confession) {
    return [
      Container(
        color: black,
        child: Image.asset(
          'images/socialv/icons/user-pngrepo-com.png',
          width: 40,
          height: 40,
          color: white,
        ).paddingAll(5),
      ).cornerRadiusWithClipRRect(6),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.anonim,
            style: TextStyle(color: black, fontSize: 16),
          ),
          Text(
            getTimeDifference((confession.timestamp as Timestamp)
                    .millisecondsSinceEpoch) +
                " " +
                s.ago,
            style: TextStyle(color: black, fontSize: 12),
          ),
        ],
      ).paddingLeft(12)
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
              width: 50,
              height: 50,
              fit: BoxFit.fitHeight,
            ).cornerRadiusWithClipRRect(6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName!,
                  style: TextStyle(color: black, fontSize: 16),
                ),
                Text(
                  getTimeDifference((confession.timestamp as Timestamp)
                          .millisecondsSinceEpoch) +
                      " " +
                      s.ago,
                  style: TextStyle(color: black, fontSize: 12),
                ),
              ],
            ).paddingLeft(12)
          ],
        );
      },
    );
  }

  Widget commentSection(Confession confession) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "${s.comments.capitalizeFirstLetter()} (${confession.commentCount})",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ).paddingAll(8),
        StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection(CollectionPath().confessions)
              .doc(confession.id)
              .collection(CollectionPath().comments)
              .orderBy("timeForMillis", descending: true)
              .snapshots(),
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (!snapshot.hasData) {
              return Loading(
                height: 150,
              );
            }

            List<Comment> comments = snapshot.data!.docs
                .map((e) => Comment(
                    commenterId: e['commenterId'],
                    timeForMillis: e['timeForMillis'],
                    content: e['content'],
                    commentId: e['commentId']))
                .toList();

            if (comments.isEmpty) {
              return SizedBox(
                width: double.infinity,
                height: 150,
                child: Align(child: Text(s.noComments)),
              );
            }

            return FutureBuilder(
              future: getConfessionComments(comments, confession.id),
              builder: (context, AsyncSnapshot<List<SVCommentModel>> snapshot) {
                if (!snapshot.hasData) {
                  return SizedBox();
                }
                final uiComments = snapshot.data!;
                return ListView.builder(
                    physics: NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      return Column(children: [
                        mainCommentLay(index, uiComments[index]),
                        aboutLay(index, uiComments[index], comments[index],
                            true, "${comments[index].commentId}"),
                      ], crossAxisAlignment: CrossAxisAlignment.start);
                    }).paddingSymmetric(vertical: 8);
              },
            );
          },
        ),
      ],
    ).paddingAll(16);
  }

  Widget mainCommentLay(int index, SVCommentModel comment) {
    return Row(
      children: [
        Image.network(
          comment.profileImage.validate(),
          height: 40,
          width: 40,
          fit: BoxFit.cover,
        ).cornerRadiusWithClipRRect(100),
        Flexible(
            child: Container(
          color: commentBgColor,
          child: Column(
            children: [
              Text(
                comment.name,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ).paddingTop(12).paddingSymmetric(horizontal: 12),
              Text(
                comment.comment,
                style: TextStyle(fontSize: 16),
              ).paddingBottom(12).paddingSymmetric(horizontal: 12).paddingTop(6)
            ],
            crossAxisAlignment: CrossAxisAlignment.start,
          ),
        )
                .cornerRadiusWithClipRRect(SVAppCommonRadius)
                .paddingSymmetric(horizontal: 8))
      ],
      mainAxisSize: MainAxisSize.min,
    ).paddingAll(8);
  }

  Widget aboutLay(int index, SVCommentModel comment, Comment realComment,
      bool visibleReply, String likePath) {
    return Row(
      children: [
        Text(comment.time!).paddingLeft(68).paddingBottom(4),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
              borderRadius: radius(4), color: svGetScaffoldColor()),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              comment.like == true
                  ? Image.asset('images/socialv/icons/ic_HeartFilled.png',
                      height: 14, width: 14, fit: BoxFit.fill)
                  : Image.asset(
                      'images/socialv/icons/ic_Heart.png',
                      height: 14,
                      width: 14,
                      fit: BoxFit.cover,
                      color: svGetBodyColor(),
                    ),
              2.width,
              Text(comment.likeCount.toString(),
                  style: secondaryTextStyle(size: 12)),
            ],
          ),
        ).onTap(() {
          comment.like = !comment.like.validate();
          comment.likeCount = (comment.like == true)
              ? (comment.likeCount! + 1)
              : (comment.likeCount! - 1);
          if (userModel != null) {
            FirestoreService().likeEvent(
                comment.like == true,
                "${CollectionPath().confessions}/${confessionId}/${CollectionPath().comments}/$likePath",
                userModel!.id);
          }
          setState(() {});
        }, borderRadius: radius(4)),
      ],
    );
  }

  Color commentBgColor = (appStore.isDarkMode)
      ? Color.fromARGB(255, 40, 36, 36)
      : Color.fromARGB(255, 221, 220, 220);

  Widget commentLayout(Confession confession) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16),
      color: svGetScaffoldColor(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          //Divider(indent: 16, endIndent: 16, height: 20),
          Row(
            children: [
              16.width,
              (userModel != null)
                  ? Image.network(userModel!.ppUrl,
                          height: 48, width: 48, fit: BoxFit.cover)
                      .cornerRadiusWithClipRRect(8)
                  : Image.asset('images/socialv/faces/face_5.png',
                          height: 48, width: 48, fit: BoxFit.cover)
                      .cornerRadiusWithClipRRect(8),
              10.width,
              Container(
                width: context.width() * 0.6,
                child: AppTextField(
                  controller: commentController,
                  textFieldType: TextFieldType.OTHER,
                  decoration: InputDecoration(
                    hintText: Translations().writeaComment,
                    hintStyle: secondaryTextStyle(color: svGetBodyColor()),
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                  ),
                ),
              ),
              TextButton(
                  onPressed: () async {
                    if (!commentController.text.isEmptyOrNull &&
                        userModel != null) {
                      final comment = Comment(
                          commenterId: userModel!.id,
                          timeForMillis: DateTime.now().millisecondsSinceEpoch,
                          content: commentController.text,
                          commentId: Extensions.generateRandomString(15));
                      await FirebaseFirestore.instance
                          .collection(CollectionPath().confessions)
                          .doc(confession.id)
                          .update({"commentCount": FieldValue.increment(1)});
                      FirestoreService()
                          .setData(
                              "${CollectionPath().confessions}/${confession.id}/${CollectionPath().comments}",
                              comment.commentId,
                              comment.toJson())
                          .then((success) => {
                                commentController.text = "",
                                setState(() => {})
                              });
                    }
                  },
                  child: Text(Translations().reply,
                      style: secondaryTextStyle(color: SVAppColorPrimary)))
            ],
          ),
        ],
      ),
    );
  }

  _sendGift(BuildContext context, Confession confession) async {
    await InAppService().showSendGiftDialog(context, confession.userId,
        confessionId: confession.id);
  }

  _shareConfession(Confession confession) async {
    PackageInfoData packageInfo = await getPackageInfo();
    String? packageName = packageInfo.packageName;
    var userContent = "";
    if (!confession.isAnonym) {
      UserDetails? confesser =
          await FirestoreService().getUser(confession.userId);
      userContent += "\n${confesser?.name}:";
    }
    //String userContent = confession.isAnonym ? '' :
    String shareLink =
        "https://play.google.com/store/apps/details?id=$packageName";
    String shareContent = """
$shareLink$userContent
-----------------------------
${confession.title}
-----------------------------
${confession.description}
    """;
    Share.share(shareContent);
  }
}
