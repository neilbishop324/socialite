import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:prokit_socialv/model/SVPost.dart';
import 'package:prokit_socialv/model/SVUser.dart';
import 'package:prokit_socialv/models/SVCommentModel.dart';
import 'package:prokit_socialv/models/SVPostModel.dart';
import 'package:prokit_socialv/screens/home/components/SVPostComponent.dart';
import 'package:prokit_socialv/service/auth.dart';
import 'package:prokit_socialv/service/firestore_service.dart';
import 'package:prokit_socialv/utils/Translations.dart';

import '../../../utils/Extensions.dart';
import '../../../utils/SVCommon.dart';
import '../../../utils/SVConstants.dart';
import '../../home/screens/SVCommentScreen.dart';

class PostScreen extends StatefulWidget {
  const PostScreen({Key? key, this.id}) : super(key: key);

  @override
  State<PostScreen> createState() => _PostScreenState(id);
  final String? id;
}

class _PostScreenState extends State<PostScreen> {
  final String? id;
  String? username;
  final firestoreService = FirestoreService();

  _PostScreenState(this.id);

  @override
  void initState() {
    final userId = AuthService().getUid();
    FirestoreService().getUser(userId).then((user) => {userModel = user});
    FirebaseFirestore.instance
        .collection(CollectionPath().posts)
        .doc(id)
        .withConverter<Post>(
          fromFirestore: (snapshot, _) => Post.fromJson(snapshot.data()!),
          toFirestore: (post, _) => post.toJson(),
        )
        .get()
        .then((value) => {
              postModel = value.data(),
              if (postModel != null)
                {
                  getPost(postModel!).then(
                      (postSv) => {svPostModel = postSv, setState(() {})}),
                }
            });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) => Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: svGetScaffoldColor(),
        appBar: AppBar(
          backgroundColor: svGetScaffoldColor(),
          title: Text('Post', style: boldTextStyle(size: 20)),
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: context.iconColor),
        ),
        body: SingleChildScrollView(
            child: post().paddingSymmetric(horizontal: 16)),
      ),
    );
  }

  Post? postModel;
  SVPostModel? svPostModel;
  UserDetails? userModel;
  final s = Translations();

  Widget post() {
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
                  Text('${svPostModel?.time.validate()} ' + s.ago,
                      style: secondaryTextStyle(
                          color: svGetBodyColor(), size: 12)),
                  IconButton(
                      onPressed: () {
                        if (postModel != null) {
                          handleAttachmentPressed(context, [
                            NameAndAction(
                                (svPostModel?.postSaved == true)
                                    ? s.unsave
                                    : s.save, (() {
                              _savePost(postModel!.postId,
                                  svPostModel?.postSaved == true, svPostModel);
                            })),
                            NameAndAction(s.report, (() {
                              _reportPost(postModel!.postId);
                            }))
                          ]);
                        }
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
                    if (postModel != null && userModel != null) {
                      SVCommentScreen(
                        post: postModel!,
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
                        svPostModel!.like = !svPostModel!.like.validate();
                        if (userModel != null) {
                          FirestoreService().likeEvent(
                              svPostModel!.like == true,
                              "${CollectionPath().posts}/${postModel?.postId}",
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
                    if (postModel != null) {
                      svShowShareBottomSheet(context, postModel!);
                    }
                  },
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent),
                ],
              ),
              InkWell(
                onTap: () => {
                  if (postModel != null)
                    {
                      SVCommentScreen(
                        post: postModel!,
                        userDetails: userModel,
                      ).launch(context)
                    }
                },
                child: Text(
                    '${svPostModel?.commentCount.validate()} ' + s.comments,
                    style: secondaryTextStyle(color: svGetBodyColor())),
              ),
            ],
          ).paddingSymmetric(horizontal: 16),
        ],
      ),
    );
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
}
