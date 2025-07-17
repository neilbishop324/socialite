import 'dart:ffi';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:prokit_socialv/main.dart';
import 'package:prokit_socialv/model/SVPost.dart';
import 'package:prokit_socialv/model/SVUser.dart';
import 'package:prokit_socialv/screens/profile/edit/EditProfileScreen.dart';
import 'package:prokit_socialv/utils/Extensions.dart';
import 'package:prokit_socialv/utils/SVColors.dart';
import 'package:prokit_socialv/utils/SVCommon.dart';
import 'package:prokit_socialv/utils/Translations.dart';

import '../../service/auth.dart';
import '../../service/firestore_service.dart';
import '../../utils/SVConstants.dart';

class SVAddPostFragment extends StatefulWidget {
  const SVAddPostFragment(
      {Key? key, required this.postContextId, this.fromStory, this.file})
      : super(key: key);

  final String postContextId;
  final bool? fromStory;
  final File? file;

  @override
  State<SVAddPostFragment> createState() =>
      _SVAddPostFragmentState(postContextId, fromStory, file);
}

class _SVAddPostFragmentState extends State<SVAddPostFragment> {
  String image = '';
  final String postContextId;
  final bool? fromStory;
  final s = Translations();

  Color imageSelectorColor =
      (appStore.isDarkMode) ? Colors.white : Colors.indigo;

  final captionController = TextEditingController();
  UserDetails? userModel;
  AuthService authService = AuthService();
  FirestoreService firestoreService = FirestoreService();

  _SVAddPostFragmentState(
      this.postContextId, this.fromStory, this.postImageFile);

  @override
  void initState() {
    super.initState();
    afterBuildCreated(() {
      setStatusBarColor(context.cardColor);
    });
    final uid = authService.getUid();
    firestoreService.getUser(uid).then((user) {
      if (user != null) {
        setState(() {
          userModel = user;
        });
      }
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
        iconTheme: IconThemeData(color: context.iconColor),
        backgroundColor: context.cardColor,
        title: Text((fromStory != true) ? s.newPost : s.newStory,
            style: boldTextStyle(size: 20)),
        elevation: 0,
        centerTitle: true,
        actions: [
          AppButton(
            shapeBorder: RoundedRectangleBorder(borderRadius: radius(4)),
            text: 'Post',
            textStyle: secondaryTextStyle(color: Colors.white, size: 10),
            onTap: () {
              if ((!captionController.text.isEmptyOrNull ||
                      postImageFile != null) &&
                  userModel != null) {
                submitPost(Post(
                    posterName: userModel!.id,
                    timeForMillis: DateTime.now().millisecondsSinceEpoch,
                    imageLink: null,
                    description: captionController.text,
                    isForStory: false, //can be change
                    postId: Extensions.generateRandomString(15),
                    postContextId: postContextId));
              }
            },
            elevation: 0,
            color: SVAppColorPrimary,
            width: 50,
            padding: EdgeInsets.all(0),
          ).paddingAll(16),
        ],
      ),
      body: bodyWidget(context),
    );
  }

  submitPost(Post post) async {
    String? downloadUrl;
    if (postImageFile != null) {
      await firestoreService
          .downloadImage(postImageFile!,
              "posts/${userModel?.id}_${Extensions.generateRandomString(10)}")
          .then((url) => {downloadUrl = url});
    }
    final submitPostModel = Post(
        posterName: post.posterName,
        timeForMillis: post.timeForMillis,
        imageLink: downloadUrl,
        description: captionController.text,
        isForStory: false,
        postId: post.postId,
        postContextId: post.postContextId);

    firestoreService
        .setData(CollectionPath().posts, submitPostModel.postId,
            submitPostModel.toJson())
        .then((success) => {
              if (success)
                {showToast(s.postSuccSub), Navigator.pop(context)}
              else
                {showToast(s.sthWentWrong)}
            });
  }

  File? postImageFile;
  bool iconVisibility = true;
  bool imageVisibility = false;

  Widget bodyWidget(BuildContext context) {
    return Scaffold(
        body: SingleChildScrollView(
      child: Container(
        height: MediaQuery.of(context).size.height - 80,
        decoration: BoxDecoration(
            color: (appStore.isDarkMode)
                ? Color.fromARGB(255, 10, 9, 9)
                : Colors.grey[200]),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Flexible(
              child: InkWell(
                onTap: () async {
                  postImageFile = await Extensions.getFromGallery();
                  if (postImageFile != null) {
                    setState(() {
                      iconVisibility = false;
                      imageVisibility = true;
                    });
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                      color: (appStore.isDarkMode)
                          ? Color.fromARGB(255, 10, 9, 9)
                          : Colors.grey[200]),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Visibility(
                            visible: iconVisibility,
                            child: Icon(Icons.add_photo_alternate,
                                size: 80,
                                color: (appStore.isDarkMode)
                                    ? Colors.grey[300]
                                    : Colors.grey[500])),
                        Visibility(
                            visible: iconVisibility,
                            child: Text(s.selectPhoto,
                                style: TextStyle(
                                    color: (appStore.isDarkMode)
                                        ? Colors.grey[300]
                                        : Colors.grey[500],
                                    fontSize: 20))),
                        Visibility(
                            visible: imageVisibility,
                            child: SizedBox(
                                child: (imageVisibility)
                                    ? Image.file(postImageFile!)
                                    : Image.asset(
                                        "images/socialv/postImage.png")))
                      ]),
                ),
              ),
              fit: FlexFit.loose,
            ),
            Container(
                decoration: BoxDecoration(
                    color:
                        (appStore.isDarkMode) ? Colors.grey[900] : Colors.white,
                    border: Border(
                        top: BorderSide(
                            color: (appStore.isDarkMode)
                                ? Colors.grey[900]!
                                : Colors.grey[300]!,
                            width: 1))),
                child: Visibility(
                  visible: fromStory != true,
                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: TextField(
                      controller: captionController,
                      decoration: InputDecoration(
                          hintText: s.writeaCaption, border: InputBorder.none),
                    ),
                  ),
                ))
          ],
        ),
      ),
    ));
  }
}
