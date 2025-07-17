import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:prokit_socialv/model/SVUser.dart';
import 'package:prokit_socialv/models/SVStoryModel.dart';
import 'package:prokit_socialv/screens/fragments/SVAddPostFragment.dart';
import 'package:prokit_socialv/screens/home/screens/SVStoryScreen.dart';
import 'package:prokit_socialv/service/auth.dart';
import 'package:prokit_socialv/service/firestore_service.dart';
import 'package:prokit_socialv/utils/SVColors.dart';
import 'package:prokit_socialv/utils/SVCommon.dart';
import 'package:prokit_socialv/utils/SVConstants.dart';
import 'package:prokit_socialv/utils/Translations.dart';

import '../../../model/Story.dart';
import '../../../utils/Extensions.dart';

class SVStoryComponent extends StatefulWidget {
  @override
  State<SVStoryComponent> createState() => _SVStoryComponentState();
}

class _SVStoryComponentState extends State<SVStoryComponent> {
  List<SVStoryModel> storyList = [];
  File? image;

  UserDetails? userModel;
  bool userHasStory = false;
  SVStoryModel? userStory;

  @override
  void initState() {
    FirestoreService()
        .getUser(AuthService().getUid())
        .then((value) => {userModel = value, userHasStoryCtrl()});
    FirestoreService().getStories().then((value) => {
          getStories(value).then((stories) => {
                setState(() {
                  storyList = stories
                      .where((element) => element.id != AuthService().getUid())
                      .toList();
                }),
                if (stories
                        .where(
                            (element) => element.id == AuthService().getUid())
                        .toList()
                        .length >
                    0)
                  {
                    userStory = stories
                        .where(
                            (element) => element.id == AuthService().getUid())
                        .toList()
                        .first
                  }
              })
        });
    super.initState();
  }

  final s = Translations();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
            width: MediaQuery.of(context).size.width,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 16),
                      height: 60,
                      width: 60,
                      decoration: BoxDecoration(
                        color: SVAppColorPrimary,
                        borderRadius: radius(SVAppCommonRadius),
                      ),
                      child: (userHasStory == true)
                          ? Container(
                              child: Image.network(
                                userModel!.ppUrl,
                                height: 58,
                                width: 58,
                                fit: BoxFit.cover,
                              ).cornerRadiusWithClipRRect(SVAppCommonRadius),
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: SVAppColorPrimary, width: 2),
                                borderRadius: radius(14),
                              ),
                            ).onTap(() {
                              SVStoryScreen(
                                      svStoryModels: [userStory!],
                                      isCurrent: true,
                                      index: 0)
                                  .launch(context);
                            })
                          : IconButton(
                              icon: Icon(Icons.add, color: Colors.white),
                              onPressed: () async {
                                image = await svGetImageSource();
                                submitStory(image);
                              }),
                    ),
                    10.height,
                    Text(s.yourStory,
                        style: secondaryTextStyle(
                            size: 12,
                            color: context.iconColor,
                            weight: FontWeight.w500)),
                  ],
                ),
                HorizontalList(
                  spacing: 16,
                  itemCount: storyList.length,
                  itemBuilder: (context, index) {
                    return Column(
                      children: [
                        Container(
                          child: Image.network(
                            storyList[index].profileImage.validate(),
                            height: 58,
                            width: 58,
                            fit: BoxFit.cover,
                          ).cornerRadiusWithClipRRect(SVAppCommonRadius),
                          decoration: BoxDecoration(
                            border:
                                Border.all(color: SVAppColorPrimary, width: 2),
                            borderRadius: radius(14),
                          ),
                        ).onTap(() {
                          SVStoryScreen(
                                  svStoryModels: storyList,
                                  isCurrent: false,
                                  index: index)
                              .launch(context);
                        }),
                        10.height,
                        Text(storyList[index].name.validate(),
                            style: secondaryTextStyle(
                                size: 12,
                                color: context.iconColor,
                                weight: FontWeight.w500)),
                      ],
                    );
                  },
                )
              ],
            )));
  }

  void submitStory(File? file) async {
    String? downloadUrl;
    if (file != null && userModel != null) {
      final storyId = Extensions.generateRandomString(10);
      await FirestoreService()
          .downloadImage(file, "posts/${userModel!.id}_$storyId")
          .then((url) => {downloadUrl = url});
      final submitPostModel = Story(
          userId: userModel!.id,
          timeForMillis: DateTime.now().millisecondsSinceEpoch,
          imageLink: downloadUrl,
          id: storyId);

      FirestoreService()
          .setData(CollectionPath().stories, submitPostModel.userId,
              submitPostModel.toJson())
          .then((success) => {
                if (success)
                  {showToast(s.ypsSubmitted)}
                else
                  {showToast(s.sthWentWrong)}
              });
    } else {
      print(file != null);
      print(userModel != null);
    }
  }

  userHasStoryCtrl() async {
    final ss = await FirebaseFirestore.instance
        .collection(CollectionPath().stories)
        .doc(userModel!.id)
        .get();
    setState(() {
      userHasStory = ss.exists;
    });
  }
}
