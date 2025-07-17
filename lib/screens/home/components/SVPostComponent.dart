import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:prokit_socialv/model/Group.dart';
import 'package:prokit_socialv/model/SVPost.dart';
import 'package:prokit_socialv/model/SVUser.dart';
import 'package:prokit_socialv/models/SVPostModel.dart';
import 'package:prokit_socialv/screens/home/screens/SVCommentScreen.dart';
import 'package:prokit_socialv/service/auth.dart';
import 'package:prokit_socialv/service/firestore_service.dart';
import 'package:prokit_socialv/utils/Extensions.dart';
import 'package:prokit_socialv/utils/SVCommon.dart';
import 'package:prokit_socialv/utils/SVConstants.dart';

import '../../../utils/Translations.dart';

class SVPostComponent extends StatefulWidget {
  final String? uid;
  final bool? fromSave;
  final bool? fromAnother;

  const SVPostComponent({Key? key, this.uid, this.fromSave, this.fromAnother})
      : super(key: key);
  @override
  State<SVPostComponent> createState() =>
      _SVPostComponentState(uid, fromSave, fromAnother);
}

class _SVPostComponentState extends State<SVPostComponent> {
  final firestoreService = FirestoreService();
  final authService = AuthService();

  UserDetails? userModel;

  _SVPostComponentState(this.userUid, this.fromSave, this.fromAnother);

  final String? userUid;
  final bool? fromSave;
  final bool? fromAnother;

  @override
  void initState() {
    final uid = authService.getUid();
    firestoreService.getUser(uid).then((user) {
      if (user != null) {
        userModel = user;
        hasFriendToPost();
      }
    });

    super.initState();
  }

  List<bool> hasFriendToLike = [];

  List<UserDetails> friends = [];

  bool globalPosts = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [postType(context), posts(context)],
    );
  }

  final s = Translations();

  Widget postType(BuildContext context) {
    return Visibility(
        visible: fromSave != true && fromAnother != true,
        child: InkWell(
            onTap: () {
              handleAttachmentPressed(context, [
                NameAndAction(s.popyf, () {
                  setState(() {
                    globalPosts = false;
                  });
                }),
                NameAndAction(s.explore, () {
                  setState(() {
                    globalPosts = true;
                  });
                })
              ]);
            },
            child: Align(
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [Text(s.postType), Icon(Icons.arrow_drop_down)],
              ),
            ).paddingAll(12)));
  }

  Widget posts(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection(CollectionPath().posts)
          .orderBy("timeForMillis", descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData) {
          return Container(child: Align(child: CircularProgressIndicator()));
        }
        hasFriendToLike =
            List.generate(snapshot.data!.docs.length, (index) => false);
        friends =
            List.generate(snapshot.data!.docs.length, (index) => nullUser);
        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            DocumentSnapshot documentSnapshot = snapshot.data!.docs[index];
            Post post = Post(
                posterName: documentSnapshot['posterName']! as String,
                timeForMillis: documentSnapshot['timeForMillis']! as int,
                imageLink: documentSnapshot['imageLink'] as String?,
                description: documentSnapshot['description'] as String?,
                isForStory: documentSnapshot['isForStory']! as bool,
                postId: documentSnapshot['postId']! as String,
                postContextId: documentSnapshot['postContextId'] as String);
            return FutureBuilder<SVPostModel>(
              future: getPost(post),
              builder: (context, postModelSnapshot) {
                if (postModelSnapshot.hasData) {
                  // Build the UI with the fetched data
                  if ((globalPosts ==
                          (postModelSnapshot.data?.fromYF ?? false)) ||
                      (fromAnother == true && post.posterName != userUid) ||
                      (fromSave == true &&
                          postModelSnapshot.data?.postSaved != true)) {
                    return SizedBox();
                  }
                  return postContent(postModelSnapshot.data, post, index);
                } else if (postModelSnapshot.hasError) {
                  // Build the UI for the error state
                  return Text("${s.error}: ${postModelSnapshot.error}");
                } else {
                  // Build the UI for the loading state
                  return Container(
                      child: Align(
                          child: CircularProgressIndicator(
                    color: Color(0xff2F65B9),
                  ).paddingSymmetric(vertical: 180)));
                }
              },
            );
          },
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
        );
      },
    );
  }

  List<TextSpan> getLikeTexts(int index, SVPostModel? postModel) {
    final list = <TextSpan>[];
    if (hasFriendToLike.length <= index) {
      return list;
    }
    if (hasFriendToLike[index]) {
      list.add(TextSpan(
          text: '${friends[index].name} ', style: boldTextStyle(size: 12)));

      if ((postModel?.likeList.length ?? 0) > 1) {
        list.add(TextSpan(
            text: s.and + ' ',
            style: secondaryTextStyle(color: svGetBodyColor(), size: 12)));
        list.add(TextSpan(
            text: ((postModel?.likeList.length ?? 0) - 1).toString() +
                ' ${!s.tr ? "Other" : "Kişi"}${(((postModel?.likeList.length ?? 0) - 1) != 1 && !s.tr) ? 's' : ""}',
            style: boldTextStyle(size: 12)));
      }
    } else {
      list.add(TextSpan(
          text: (postModel?.likeList.length.toString() ?? "") +
              ((postModel?.likeList.length == 1)
                  ? " " + s.person
                  : ' ' + s.people),
          style: boldTextStyle(size: 12)));
    }
    if (s.tr) {
      list.add(TextSpan(text: " Beğendi", style: boldTextStyle(size: 12)));
    }
    return list;
  }

  List<String> userFollowingIds = [];
  bool getFollowingIds = true;
  UserDetails nullUser = UserDetails(
      name: "",
      username: "",
      ppUrl: "",
      bgUrl: "",
      gender: "",
      birthDay: "",
      bio: "",
      active: false,
      location: UserLocation(city: "", state: "", country: ""),
      id: "");

  Future<bool> getFriends(String? uid, int index, SVPostModel postModel) async {
    if (uid == null) {
      return false;
    }
    if (getFollowingIds) {
      userFollowingIds = await firestoreService.getUserFollowings(uid);
    }
    getFollowingIds = false;
    for (String id in userFollowingIds) {
      if (postModel.likeList.contains(id)) {
        final user = await firestoreService.getUser(id);
        friends[index] = user ?? nullUser;
        hasFriendToLike[index] = true;
        break;
      }
    }
    return true;
  }

  _savePost(String id, bool saved, SVPostModel? postModel) {
    if (userModel != null) {
      firestoreService.savePost(userModel!.id, id, saved).then((success) => {
            if (success)
              {
                showToast((saved) ? s.psUnsaved : s.psSaved),
                postModel?.postSaved = !saved
              }
          });
    }
  }

  _reportPost(String id) {
    firestoreService.reportPost(id).then((success) => {
          if (success) {showToast(s.pReported)}
        });
  }

  Widget postContent(SVPostModel? postModel, Post post, int index) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16),
      margin: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
          borderRadius: radius(SVAppCommonRadius), color: context.cardColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              postTopBar(postModel, post, context),
              Row(
                children: [
                  Text('${postModel?.time.validate()}',
                      style: secondaryTextStyle(
                          color: svGetBodyColor(), size: 12)),
                  IconButton(
                      onPressed: () {
                        handleAttachmentPressed(context, [
                          NameAndAction(
                              (postModel?.postSaved == true)
                                  ? s.unsave
                                  : s.save, (() {
                            _savePost(post.postId, postModel?.postSaved == true,
                                postModel);
                          })),
                          NameAndAction(s.report, (() {
                            _reportPost(post.postId);
                          }))
                        ]);
                      },
                      icon: Icon(Icons.more_horiz)),
                ],
              ),
            ],
          ),
          16.height,
          (postModel?.description?.validate() ?? "").isNotEmpty
              ? svRobotoText(
                      text: postModel?.description.validate() ?? "",
                      textAlign: TextAlign.start)
                  .paddingSymmetric(horizontal: 16)
              : Offstage(),
          (postModel?.description?.validate() ?? "").isNotEmpty
              ? 16.height
              : Offstage(),
          (postModel?.postImage != null)
              ? Image.network(
                  postModel?.postImage.validate() ??
                      SVConstants.backgroundLinkDefault,
                  height: 300,
                  width: context.width() - 32,
                  fit: BoxFit.cover,
                ).cornerRadiusWithClipRRect(SVAppCommonRadius).center()
              : SizedBox(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Image.asset(
                    'images/socialv/icons/ic_Chat.png',
                    height: 22,
                    width: 22,
                    fit: BoxFit.cover,
                    color: context.iconColor,
                  ).onTap(() {
                    SVCommentScreen(
                      post: post,
                      userDetails: userModel,
                    ).launch(context);
                  },
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent),
                  IconButton(
                    icon: postModel?.like.validate() == true
                        ? Image.asset('images/socialv/icons/ic_HeartFilled.png',
                            height: 20, width: 22, fit: BoxFit.fill)
                        : Image.asset(
                            'images/socialv/icons/ic_Heart.png',
                            height: 22,
                            width: 22,
                            fit: BoxFit.cover,
                            color: context.iconColor,
                          ),
                    onPressed: () {
                      postModel?.like = !postModel.like.validate();
                      if (userModel != null) {
                        firestoreService.likeEvent(
                            postModel?.like == true,
                            "${CollectionPath().posts}/${post.postId}",
                            userModel!.id,
                            post: post);
                      }
                      setState(() {});
                    },
                  ),
                  Image.asset(
                    'images/socialv/icons/ic_Send.png',
                    height: 22,
                    width: 22,
                    fit: BoxFit.cover,
                    color: context.iconColor,
                  ).onTap(() {
                    svShowShareBottomSheet(context, post);
                  },
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent),
                ],
              ),
              InkWell(
                onTap: () => {
                  SVCommentScreen(
                    post: post,
                    userDetails: userModel,
                  ).launch(context)
                },
                child: Text(
                    '${postModel?.commentCount.validate()} ' + s.comments,
                    style: secondaryTextStyle(color: svGetBodyColor())),
              ),
            ],
          ).paddingSymmetric(horizontal: 16),
          FutureBuilder(
              future: getFriends(AuthService().getUid(), index, postModel!),
              builder: (context, success) {
                if ((success.data as bool?) == true) {
                  return Visibility(
                      visible: postModel.likeList.length != 0,
                      child: Column(
                        children: [
                          Divider(indent: 16, endIndent: 16, height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Visibility(
                                  visible: (hasFriendToLike.length > index)
                                      ? hasFriendToLike[index]
                                      : false,
                                  child: SizedBox(
                                    width: 25,
                                    child: Stack(
                                      alignment: Alignment.centerLeft,
                                      children: [
                                        Positioned(
                                          child: Container(
                                            decoration: BoxDecoration(
                                                border: Border.all(
                                                    color: Colors.white,
                                                    width: 2),
                                                borderRadius: radius(100)),
                                            child: (friends.length > index)
                                                ? Image.network(
                                                        friends[index].ppUrl,
                                                        height: 24,
                                                        width: 24,
                                                        fit: BoxFit.cover)
                                                    .cornerRadiusWithClipRRect(
                                                        100)
                                                : SizedBox(),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                              10.width,
                              RichText(
                                text: TextSpan(
                                  text: !s.tr ? 'Liked By ' : '',
                                  style: secondaryTextStyle(
                                      color: svGetBodyColor(), size: 12),
                                  children: getLikeTexts(index, postModel),
                                ),
                              )
                            ],
                          )
                        ],
                      ));
                }
                return SizedBox();
              })
        ],
      ),
    );
  }

  Widget postTopBar(SVPostModel? postModel, Post post, BuildContext context) {
    if (post.postContextId == 'Public') {
      return postTopBarWithoutFuture(postModel, post);
    } else {
      return FutureBuilder(
          future: firestoreService.getGroup(post.postContextId),
          builder: (context, groupSnapshot) {
            if (groupSnapshot.data == null) {
              return postTopBarWithoutFuture(postModel, post);
            }
            return postTopBarWithoutFuture(postModel, post,
                groupImage: (groupSnapshot.data! as Group).ppUrl,
                groupName: (groupSnapshot.data! as Group).name);
          });
    }
  }

  Widget postTopBarWithoutFuture(SVPostModel? postModel, Post post,
      {String? groupImage, String? groupName}) {
    return Row(
      children: [
        Stack(
          children: [
            Image.network(
              (groupImage != null)
                  ? groupImage
                  : postModel?.profileImage?.validate() ??
                      SVConstants.imageLinkDefault,
              height: 56,
              width: 56,
              fit: BoxFit.cover,
            ).cornerRadiusWithClipRRect(SVAppCommonRadius).paddingAll(5),
            Visibility(
                visible: groupImage != null,
                child: Positioned(
                  right: 3.0,
                  bottom: 3.0,
                  child: Image.network(
                    postModel?.profileImage?.validate() ??
                        SVConstants.imageLinkDefault,
                    width: 30,
                    height: 30,
                  ).cornerRadiusWithClipRRect(100),
                ))
          ],
        ),
        12.width,
        SizedBox(
            width: MediaQuery.of(context).size.width * 2 / 5,
            child: Text(
                ((groupName != null) ? groupName + " > " : "") +
                    (postModel?.name.validate() ?? ""),
                style: boldTextStyle()))
      ],
    ).paddingSymmetric(horizontal: 16);
  }

  void hasFriendToPost() async {
    final db = FirebaseFirestore.instance;
    final posts = await db.collection(CollectionPath().posts).get();
    final posterList =
        posts.docs.map((e) => e.data()['posterName'] as String?).toList();
    final postContextList =
        posts.docs.map((e) => e.data()['postContextId'] as String?).toList();
    final getfollowings =
        await firestoreService.getUserFollowings(userModel!.id);
    getfollowings.add(userModel!.id);
    for (String? id in posterList) {
      if (getfollowings.contains(id)) {
        return;
      }
    }
    final getgroups = await firestoreService.getGroups();
    final participated =
        await firestoreService.getParticipatedGroups(getgroups, userModel!.id);
    final groupids = participated.map((e) => e.id).toList();
    for (String? id in postContextList) {
      if (groupids.contains(id)) {
        return;
      }
    }
    globalPosts = true;
  }
}
