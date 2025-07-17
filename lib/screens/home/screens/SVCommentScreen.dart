import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:prokit_socialv/model/SVPost.dart';
import 'package:prokit_socialv/model/SVUser.dart';
import 'package:prokit_socialv/models/SVCommentModel.dart';
import 'package:prokit_socialv/service/auth.dart';
import 'package:prokit_socialv/utils/SVColors.dart';
import 'package:prokit_socialv/utils/Translations.dart';

import '../../../../../main.dart';
import '../../../model/SVComment.dart';
import '../../../service/firestore_service.dart';
import '../../../utils/Extensions.dart';
import '../../../utils/SVCommon.dart';
import '../../../utils/SVConstants.dart';

class SVCommentScreen extends StatefulWidget {
  const SVCommentScreen({Key? key, required this.post, this.userDetails})
      : super(key: key);

  final Post post;
  final UserDetails? userDetails;

  @override
  State<SVCommentScreen> createState() =>
      _SVCommentScreenState(post, userDetails);
}

class _SVCommentScreenState extends State<SVCommentScreen> {
  List<SVCommentModel> commentList = [];
  final firestoreService = FirestoreService();
  final authService = AuthService();

  final Post post;
  UserDetails? userModel;

  final commentController = TextEditingController();

  _SVCommentScreenState(this.post, this.userModel);

  List<Comment> realCommentList = <Comment>[];

  @override
  void initState() {
    firestoreService.getComments(post.postId, true).then((comments) async {
      realCommentList = comments;
      getComments(comments, post.postId).then((list) => {
            setState(
              () {
                commentList = list;
                commentSquareList =
                    List.generate(commentList.length, (_) => []);
                realCommentSquareList =
                    List.generate(commentList.length, (_) => []);
                showReplies = List.generate(commentList.length, (_) => false);
                replySize = List.generate(commentList.length, (_) => 0);
                for (int i = 0; i < commentList.length; i++) {
                  getReplies(realCommentList[i], i, first: true);
                }
                editingControllers = List.generate(
                    commentList.length, (_) => TextEditingController());
              },
            )
          });
    });
    final uid = authService.getUid();
    firestoreService.getUser(uid).then((user) {
      if (user != null) {
        userModel = user;
      }
    });
    super.initState();
    afterBuildCreated(() {
      setStatusBarColor(context.cardColor);
    });
  }

  @override
  void dispose() {
    setStatusBarColor(
        appStore.isDarkMode ? appBackgroundColorDark : SVAppLayoutBackground);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.cardColor,
      appBar: AppBar(
        backgroundColor: context.cardColor,
        iconTheme: IconThemeData(color: context.iconColor),
        title: Text(Translations().comments2, style: boldTextStyle(size: 20)),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(onPressed: () {}, icon: Icon(Icons.more_horiz)),
        ],
      ),
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [comments().paddingBottom(70), commentLayout()],
      ),
    );
  }

  Color commentBgColor = (appStore.isDarkMode)
      ? Color.fromARGB(255, 40, 36, 36)
      : Color.fromARGB(255, 221, 220, 220);

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

  List<bool> showReplies = <bool>[];
  List<int> replySize = [];
  List<TextEditingController> editingControllers = <TextEditingController>[];
  List<List<SVCommentModel>> commentSquareList = <List<SVCommentModel>>[];
  List<List<Comment>> realCommentSquareList = <List<Comment>>[];

  Widget commentSquareLay(int index0) {
    if (commentSquareList.length == 0 ||
        commentSquareList.length < index0 ||
        commentSquareList[index0].length < 0 ||
        realCommentSquareList.length == 0 ||
        realCommentSquareList.length < index0 ||
        realCommentSquareList[index0].length < 0) {
      return SizedBox(
        height: 0,
      );
    }
    bool listVisible = commentSquareList.length > index0 &&
        commentSquareList[index0].length > 0;
    return Visibility(
        visible: showReplies[index0],
        child: Column(
          children: [
            Align(
                alignment: Alignment.topLeft,
                child: Container(
                  width: MediaQuery.of(context).size.width - 200,
                  color: commentBgColor,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                          child: AppTextField(
                        controller: editingControllers[index0],
                        textFieldType: TextFieldType.NAME,
                        decoration: InputDecoration(
                          hintText: Translations().tr
                              ? 'Bu yorumu cevapla'
                              : 'Reply this comment',
                          hintStyle:
                              secondaryTextStyle(color: svGetBodyColor()),
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                        ),
                      ).paddingSymmetric(horizontal: 12)),
                      InkWell(
                          onTap: () {
                            if (!editingControllers[index0]
                                    .text
                                    .isEmptyOrNull &&
                                userModel != null) {
                              final comment = Comment(
                                  commenterId: userModel!.id,
                                  timeForMillis:
                                      DateTime.now().millisecondsSinceEpoch,
                                  content: editingControllers[index0].text,
                                  commentId:
                                      Extensions.generateRandomString(15));
                              FirestoreService()
                                  .setData(
                                      "${CollectionPath().posts}/${post.postId}/${CollectionPath().comments}/${realCommentList[index0].commentId}/${CollectionPath().comments}",
                                      comment.commentId,
                                      comment.toJson())
                                  .then((success) => {
                                        editingControllers[index0].text = "",
                                        getReplies(
                                            realCommentList[index0], index0)
                                      });
                            }
                          },
                          child: Image.asset(
                                  "images/socialv/icons/paper-plane-send-pngrepo-com.png",
                                  color: (appStore.isDarkMode)
                                      ? Colors.white
                                      : Colors.black,
                                  width: 20,
                                  height: 20)
                              .paddingRight(12))
                    ],
                  ),
                )
                    .cornerRadiusWithClipRRect(SVAppCommonRadius)
                    .paddingLeft(60)
                    .paddingSymmetric(vertical: 10)),
            Visibility(
                visible: listVisible,
                child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: commentSquareList[index0].length,
                        itemBuilder: (context, index1) {
                          return Column(children: [
                            mainCommentLay(
                                index1, commentSquareList[index0][index1]),
                            aboutLay(
                                index1,
                                commentSquareList[index0][index1],
                                realCommentSquareList[index0][index1],
                                false,
                                "${realCommentList[index0].commentId}/${CollectionPath().comments}/${realCommentSquareList[index0][index1].commentId}")
                          ], crossAxisAlignment: CrossAxisAlignment.start);
                        })
                    .paddingLeft(40)
                    .paddingSymmetric(vertical: 8)
                    .paddingLeft(8))
          ],
        ));
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
            firestoreService.likeEvent(
                comment.like == true,
                "${CollectionPath().posts}/${post.postId}/${CollectionPath().comments}/$likePath",
                userModel!.id);
          }
          setState(() {});
        }, borderRadius: radius(4)),
        InkWell(
            onTap: () async {
              showReplies[index] = !showReplies[index];
              await getReplies(realComment, index);
            },
            child: Visibility(
                visible: visibleReply,
                child: Container(
                  decoration: BoxDecoration(
                      borderRadius: radius(4), color: svGetScaffoldColor()),
                  child: Text(
                      Translations().reply +
                          ((replySize.length > index && replySize[index] != 0)
                              ? " (" + replySize[index].toString() + ")"
                              : ""),
                      style: secondaryTextStyle(size: 12)),
                )))
      ],
    );
  }

  getReplies(Comment realComment, int index, {bool? first}) async {
    if (showReplies[index] || first == true) {
      final postPath = post.postId +
          "/" +
          CollectionPath().comments +
          "/" +
          realComment.commentId;
      final commentSqListModels =
          await firestoreService.getComments(postPath, false);
      commentSquareList[index] =
          await getComments(commentSqListModels, postPath);
      realCommentSquareList[index] = commentSqListModels;
      replySize[index] = realCommentSquareList[index].length;
    }
    setState(() {});
  }

  Widget comments() {
    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            ListView.builder(
                itemCount: commentList.length,
                itemBuilder: (context, index) {
                  return Column(children: [
                    mainCommentLay(index, commentList[index]),
                    aboutLay(index, commentList[index], realCommentList[index],
                        true, "${realCommentList[index].commentId}"),
                    commentSquareLay(index)
                  ], crossAxisAlignment: CrossAxisAlignment.start);
                }).paddingAll(8)
          ],
        ),
      ),
    );
  }

  Widget commentLayout() {
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
                  onPressed: () {
                    if (!commentController.text.isEmptyOrNull &&
                        userModel != null) {
                      final comment = Comment(
                          commenterId: userModel!.id,
                          timeForMillis: DateTime.now().millisecondsSinceEpoch,
                          content: commentController.text,
                          commentId: Extensions.generateRandomString(15));
                      FirestoreService()
                          .setData(
                              "${CollectionPath().posts}/${post.postId}/${CollectionPath().comments}",
                              comment.commentId,
                              comment.toJson())
                          .then((success) =>
                              {commentController.text = "", initState()});
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
}
