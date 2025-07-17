import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:prokit_socialv/model/Group.dart';
import 'package:prokit_socialv/model/SVPost.dart';
import 'package:prokit_socialv/model/SVUser.dart';
import 'package:prokit_socialv/models/SVPostModel.dart';
import 'package:prokit_socialv/screens/fragments/SVAddPostFragment.dart';
import 'package:prokit_socialv/screens/profile/screens/EditGroupScreen.dart';
import 'package:prokit_socialv/service/auth.dart';
import 'package:prokit_socialv/service/firestore_service.dart';
import 'package:prokit_socialv/utils/Extensions.dart';
import 'package:prokit_socialv/utils/SVConstants.dart';
import 'package:prokit_socialv/utils/Translations.dart';

import '../../../main.dart';
import '../../../utils/SVCommon.dart';
import '../../home/screens/SVCommentScreen.dart';
import 'GroupMembersScreen.dart';

class ShowGroupScreen extends StatefulWidget {
  const ShowGroupScreen({Key? key, required this.groupId}) : super(key: key);
  final String groupId;

  @override
  State<ShowGroupScreen> createState() => _ShowGroupScreenState(groupId);
}

class _ShowGroupScreenState extends State<ShowGroupScreen> {
  _ShowGroupScreenState(this.groupId);
  final String groupId;
  final firestore = FirestoreService();
  Group? group;
  bool isMember = false;

  @override
  void didChangeDependencies() {
    firestore
        .getUser(AuthService().getUid())
        .then((value) => {userModel = value});
    firestore.getGroup(groupId).then((value) => {
          if (value != null)
            {
              ctrlIsMember(value.id),
              setState(() {
                group = value;
              })
            }
        });
    super.didChangeDependencies();
  }

  final s = Translations();

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) => Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: svGetScaffoldColor(),
        appBar: AppBar(
          backgroundColor: svGetScaffoldColor(),
          title: Text(s.group, style: boldTextStyle(size: 20)),
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: context.iconColor),
          actions: [
            Visibility(
                visible: group?.adminId == AuthService().getUid(),
                child: IconButton(
                    onPressed: () {
                      EditGroupScreen(group: group).launch(context);
                    },
                    icon: Icon(Icons.edit))),
            Visibility(
                visible: group?.adminId != AuthService().getUid() && isMember,
                child: IconButton(
                    onPressed: () {
                      _leaveGroup();
                    },
                    icon: Icon(Icons.logout)))
          ],
        ),
        body: WillPopScope(
            onWillPop: () async {
              Navigator.pop(context, {setState(() {})});
              return true;
            },
            child: bodyWidget(context)),
      ),
    );
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
                  group?.name ?? s.deletedGroup,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                ).paddingTop(12),
                bioLayout(context),
                groupMembers(context),
                groupPosts(context)
              ],
            ).paddingBottom(32))));
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
      group?.description ?? "",
      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
    ).paddingTop(12).paddingSymmetric(horizontal: 16);
  }

  Widget profileHeader(BuildContext context) {
    return SizedBox(
      height: 180,
      child: Stack(
        children: <Widget>[
          Image.network(
            group?.bgUrl ?? SVConstants.backgroundLinkDefault,
            height: 150,
          ),
          Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: 100.0,
                height: 100.0,
                decoration: BoxDecoration(
                  image: DecorationImage(
                      fit: BoxFit.cover,
                      image: NetworkImage(
                          group?.ppUrl ?? SVConstants.groupImageLinkDefault)),
                  borderRadius: BorderRadius.all(Radius.circular(20.0)),
                  color: Colors.redAccent,
                ),
              ))
        ],
      ),
    );
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

  Widget groupMembers(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Visibility(
          visible: !isMember,
          child: normalButton(
                  text: s.join,
                  onPressed: () {
                    _joinGroup();
                  },
                  icon: Icons.login)
              .paddingRight(16)),
      Visibility(
          visible: isMember,
          child: normalButton(
                  text: s.addPost,
                  onPressed: () {
                    SVAddPostFragment(postContextId: groupId).launch(context);
                  },
                  icon: Icons.add)
              .paddingRight(16)),
      normalButton(
          text: s.members,
          onPressed: () {
            GroupMembersScreen(
              id: groupId,
              isMember: isMember,
            ).launch(context);
          },
          icon: Icons.supervised_user_circle),
    ]).paddingSymmetric(vertical: 16);
  }

  Widget groupPosts(BuildContext context) {
    return StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection(CollectionPath().posts)
            .where("postContextId", isEqualTo: groupId)
            .orderBy("timeForMillis", descending: true)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return CircularProgressIndicator();
          }
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              DocumentSnapshot documentSnapshot = snapshot.data!.docs[index];
              Post postModel = Post(
                  posterName: documentSnapshot['posterName']! as String,
                  timeForMillis: documentSnapshot['timeForMillis']! as int,
                  imageLink: documentSnapshot['imageLink'] as String?,
                  description: documentSnapshot['description'] as String?,
                  isForStory: documentSnapshot['isForStory']! as bool,
                  postId: documentSnapshot['postId']! as String,
                  postContextId: documentSnapshot['postContextId'] as String);
              return FutureBuilder<SVPostModel>(
                future: getPost(postModel),
                builder: (context, postModelSnapshot) {
                  if (postModelSnapshot.hasData) {
                    // Build the UI with the fetched data
                    return post(postModelSnapshot.data, postModel);
                  } else if (postModelSnapshot.hasError) {
                    // Build the UI for the error state
                    return Text("${s.error}: ${postModelSnapshot.error}");
                  } else {
                    // Build the UI for the loading state
                    return Container(
                        child: Align(
                            child: CircularProgressIndicator()
                                .paddingSymmetric(vertical: 180)));
                  }
                },
              );
            },
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
          );
        });
  }

  UserDetails? userModel;

  Widget post(SVPostModel? svPostModel, Post postModel) {
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
              Row(
                children: [
                  Image.network(
                    svPostModel?.profileImage ?? SVConstants.imageLinkDefault,
                    height: 56,
                    width: 56,
                    fit: BoxFit.cover,
                  ).cornerRadiusWithClipRRect(SVAppCommonRadius),
                  12.width,
                  Text(svPostModel?.name ?? s.loading, style: boldTextStyle())
                ],
              ).paddingSymmetric(horizontal: 16),
              Row(
                children: [
                  Text('${svPostModel?.time.validate()} ${s.ago}',
                      style: secondaryTextStyle(
                          color: svGetBodyColor(), size: 12)),
                  IconButton(
                      onPressed: () {
                        handleAttachmentPressed(
                            context,
                            [
                              NameAndAction(
                                  (svPostModel?.postSaved == true)
                                      ? s.unsave
                                      : s.save, (() {
                                _savePost(
                                    postModel.postId,
                                    svPostModel?.postSaved == true,
                                    svPostModel);
                              })),
                              NameAndAction(s.report, (() {
                                _reportPost(postModel.postId);
                              }))
                            ]..addAll((group?.adminId == AuthService().getUid())
                                ? [
                                    NameAndAction(s.delete, () {
                                      _deletePost(postModel.postId);
                                    })
                                  ]
                                : []));
                      },
                      icon: Icon(Icons.more_horiz)),
                ],
              ).paddingSymmetric(horizontal: 8),
            ],
          ),
          16.height,
          svPostModel?.description != null
              ? svRobotoText(
                      text: svPostModel?.description ?? "",
                      textAlign: TextAlign.start)
                  .paddingSymmetric(horizontal: 16)
              : Offstage(),
          svPostModel?.description != null ? 16.height : Offstage(),
          (svPostModel?.postImage != null)
              ? Image.network(
                  svPostModel?.postImage ?? SVConstants.backgroundLinkDefault,
                  height: 300,
                  width: context.width() - 64,
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
                    if (userModel != null) {
                      SVCommentScreen(
                        post: postModel,
                        userDetails: userModel,
                      ).launch(context);
                    }
                  },
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent),
                  IconButton(
                    icon: svPostModel?.like == true
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
                      if (svPostModel != null) {
                        svPostModel.like = !svPostModel.like.validate();
                        if (userModel != null) {
                          FirestoreService().likeEvent(
                              svPostModel.like == true,
                              "${CollectionPath().posts}/${postModel.postId}",
                              userModel!.id,
                              post: postModel);
                        }
                        setState(() {});
                      }
                    },
                  ),
                  Image.asset(
                    'images/socialv/icons/ic_Send.png',
                    height: 22,
                    width: 22,
                    fit: BoxFit.cover,
                    color: context.iconColor,
                  ).onTap(() {
                    svShowShareBottomSheet(context, postModel);
                  },
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent),
                ],
              ),
              InkWell(
                onTap: () => {
                  SVCommentScreen(
                    post: postModel,
                    userDetails: userModel,
                  ).launch(context)
                },
                child: Text(
                    '${svPostModel?.commentCount.validate()} ${s.comments}',
                    style: secondaryTextStyle(color: svGetBodyColor())),
              ),
            ],
          ).paddingSymmetric(horizontal: 16),
        ],
      ),
    ).paddingSymmetric(horizontal: 8);
  }

  final db = FirebaseFirestore.instance;

  ctrlIsMember(String id) async {
    final isMemberSS = await db
        .collection(CollectionPath().groups)
        .doc(id)
        .collection(CollectionPath().members)
        .doc(AuthService().getUid())
        .get();
    setState(() {
      isMember = isMemberSS.exists;
    });
  }

  void _joinGroup() async {
    final success = await firestore.setData(
        "${CollectionPath().groups}/$groupId/${CollectionPath().members}",
        AuthService().getUid() ?? "",
        {"id": AuthService().getUid()});
    if (success) {
      showToast(s.uramNow);
    }
    setState(() {
      isMember = success;
    });
  }

  void _leaveGroup() async {
    Extensions().showAlertDialog(context, s.leaveGroup, s.dywtltg, s.yes,
        () async {
      final success = await firestore.firebaseExceptionHandler(() => {
            FirebaseFirestore.instance
                .collection(CollectionPath().groups)
                .doc(groupId)
                .collection(CollectionPath().members)
                .doc(userModel?.id)
                .delete()
          });
      if (success) {
        Navigator.pop(context, {setState(() {})});
        showToast(s.youLeavedTheGroup);
      }
    });
  }

  _savePost(String id, bool saved, SVPostModel? postModel) {
    if (userModel != null) {
      firestore.savePost(userModel!.id, id, saved).then((success) => {
            if (success)
              {
                showToast((saved) ? s.psUnsaved : s.psSaved),
                postModel?.postSaved = !saved
              }
          });
    }
  }

  _reportPost(String id) {
    firestore.reportPost(id).then((success) => {
          if (success) {showToast(s.pReported)}
        });
  }

  void _deletePost(String postId) async {
    final db = FirebaseFirestore.instance;
    final success = await firestore.firebaseExceptionHandler(
        () => db.collection(CollectionPath().posts).doc(postId).delete());
    if (success) {
      showToast(s.pDeleted);
    }
  }
}
