import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:prokit_socialv/main.dart';
import 'package:prokit_socialv/model/Message.dart';
import 'package:prokit_socialv/model/SVUser.dart';
import 'package:prokit_socialv/model/Story.dart';
import 'package:prokit_socialv/models/SVStoryModel.dart';
import 'package:prokit_socialv/service/auth.dart';
import 'package:prokit_socialv/service/firestore_service.dart';
import 'package:prokit_socialv/utils/SVCommon.dart';
import 'package:prokit_socialv/utils/SVConstants.dart';
import 'package:prokit_socialv/utils/Translations.dart';
import 'package:story_view/story_view.dart';

import '../../../model/Chat.dart';
import '../../../service/message_service.dart';
import '../../../utils/Extensions.dart';

class SVStoryScreen extends StatefulWidget {
  final List<SVStoryModel> svStoryModels;
  final bool isCurrent;
  final int index;

  SVStoryScreen(
      {required this.svStoryModels,
      required this.isCurrent,
      required this.index});

  @override
  State<SVStoryScreen> createState() => _SVStoryScreenState();
}

class _SVStoryScreenState extends State<SVStoryScreen>
    with TickerProviderStateMixin {
  List<String> imageList = [];
  StoryController storyController = StoryController();

  TextEditingController messageController = TextEditingController();

  @override
  void initState() {
    setStatusBarColor(Colors.transparent);
    super.initState();
  }

  UserDetails? storyUser;
  UserDetails? currentUser;
  FirestoreService firestoreService = FirestoreService();

  @override
  void dispose() {
    super.dispose();
  }

  Color oppColor = appStore.isDarkMode ? white : black;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        child: Scaffold(
          body: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Image.network(
                widget.svStoryModels[widget.index].storyImage,
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                fit: BoxFit.contain,
              ),
              Positioned(
                  left: 0,
                  child: GestureDetector(
                      onHorizontalDragUpdate: (details) {
                        int sensitivity = 8;
                        if (details.delta.dx > -sensitivity) {
                          navigateToLeft();
                        }
                      },
                      child: Container(
                        height: MediaQuery.of(context).size.height,
                        width: MediaQuery.of(context).size.width / 2,
                        color: Colors.transparent,
                      ))),
              Positioned(
                  right: 0,
                  child: GestureDetector(
                      onHorizontalDragUpdate: (details) {
                        int sensitivity = 8;
                        if (details.delta.dx < -sensitivity) {
                          navigateToRight();
                        }
                      },
                      child: Container(
                        height: MediaQuery.of(context).size.height,
                        width: MediaQuery.of(context).size.width / 2,
                        color: Colors.transparent,
                      ))),
              Positioned(
                left: 16,
                top: 70,
                child: SizedBox(
                  height: 48,
                  child: Row(
                    children: [
                      Image.network(
                        widget.svStoryModels[widget.index].profileImage ??
                            SVConstants.imageLinkDefault,
                        height: 48,
                        width: 48,
                        fit: BoxFit.cover,
                      ).cornerRadiusWithClipRRect(8),
                      16.width,
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              widget.svStoryModels[widget.index].name
                                  .validate(),
                              style: boldTextStyle()),
                          svRobotoText(
                              text:
                                  '${widget.svStoryModels[widget.index].time.validate()} ' +
                                      Translations().ago),
                        ],
                      )
                    ],
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Visibility(
                    child: Container(
                      width: context.width() * 0.73,
                      padding: EdgeInsets.only(left: 16, right: 8, bottom: 16),
                      child: AppTextField(
                        controller: messageController,
                        textStyle: secondaryTextStyle(
                            fontFamily: svFontRoboto, color: oppColor),
                        textFieldType: TextFieldType.OTHER,
                        decoration: InputDecoration(
                          hintText: Translations().sendMessage,
                          hintStyle: secondaryTextStyle(
                              fontFamily: svFontRoboto, color: oppColor),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  BorderSide(width: 1.0, color: oppColor)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  BorderSide(width: 1.0, color: oppColor)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  BorderSide(width: 1.0, color: oppColor)),
                        ),
                      ),
                    ),
                    visible: !widget.isCurrent,
                  ),
                  Visibility(
                    child: Image.asset('images/socialv/icons/ic_Send.png',
                            height: 24,
                            width: 24,
                            fit: BoxFit.cover,
                            color: oppColor)
                        .onTap(() async {
                      if (messageController.text.isNotEmpty) {
                        final success = await sendAsMessage(
                            widget.svStoryModels[widget.index].id);
                        if (success) {
                          messageController.clear();
                          showToast(Translations().ymhbSent);
                        }
                      }
                    },
                            splashColor: Colors.transparent,
                            highlightColor: Colors.transparent),
                    visible: !widget.isCurrent,
                  ),
                  IconButton(
                    icon: widget.svStoryModels[widget.index].like == true
                        ? Image.asset('images/socialv/icons/ic_HeartFilled.png',
                            height: 20, width: 22, fit: BoxFit.fill)
                        : Image.asset('images/socialv/icons/ic_Heart.png',
                            height: 24,
                            width: 24,
                            fit: BoxFit.cover,
                            color: oppColor),
                    onPressed: () {
                      setState(() {
                        widget.svStoryModels[widget.index].like =
                            !widget.svStoryModels[widget.index].like.validate();
                        if (widget.svStoryModels[widget.index].like == true) {
                          widget.svStoryModels[widget.index].likeSize += 1;
                        } else {
                          widget.svStoryModels[widget.index].likeSize -= 1;
                        }
                      });
                      firestoreService.likeEvent(
                          widget.svStoryModels[widget.index].like == true,
                          "${CollectionPath().stories}/${widget.svStoryModels[widget.index].id}",
                          AuthService().getUid()!);
                    },
                  ).paddingBottom((widget.isCurrent) ? 20 : 0),
                  Visibility(
                      visible: widget.isCurrent,
                      child: Text(
                        widget.svStoryModels[widget.index].likeSize == 0
                            ? ""
                            : widget.svStoryModels[widget.index].likeSize
                                .toString(),
                      ).paddingBottom(20))
                ],
              ),
            ],
          ),
        ),
        onWillPop: () async {
          Navigator.pop(context);
          return true;
        });
  }

  Future<bool> sendAsMessage(String userId) async {
    try {
      await getUserToken(userId);
      if (AuthService().getUid() != null) {
        final type = await FirestoreService()
            .ctrlChatType(AuthService().getUid()!, userId);
        final fId = (type == 1) ? AuthService().getUid()! : userId;
        final sId = (type == 1) ? userId : AuthService().getUid()!;
        await FirestoreService().sendMessage(
            Message(
                id: Extensions.generateRandomString(12),
                from: AuthService().getUid()!,
                to: userId,
                timeForMillis: DateTime.now().millisecondsSinceEpoch,
                messageText: messageController.text,
                messageMediaUrl: widget.svStoryModels[widget.index].id,
                type: 4,
                hasSeen: false),
            fId,
            sId);
      }
      if (chatUserToken != null) {
        sendPushMessage(chatUserToken!, Translations().sharedaStory,
            "${currentUser?.name}");
      }
      return true;
    } on FirebaseException catch (e) {
      print(e);
      showToast(e.message.toString());
      return false;
    } catch (e) {
      print(e);
      showToast(Translations().sthWentWrong);
      return false;
    }
  }

  String? chatUserToken;

  getUserToken(String? id) async {
    if (id != null) {
      chatUserToken = await firestoreService.getUserToken(id);
    }
  }

  void navigateToLeft() {
    if (!widget.isCurrent && widget.index > 0) {
      finish(context);
      SVStoryScreen(
              svStoryModels: widget.svStoryModels,
              isCurrent: false,
              index: widget.index - 1)
          .launch(context);
    }
  }

  void navigateToRight() {
    if (!widget.isCurrent && widget.svStoryModels.length - widget.index > 1) {
      finish(context);
      SVStoryScreen(
              svStoryModels: widget.svStoryModels,
              isCurrent: false,
              index: widget.index + 1)
          .launch(context);
    }
  }
}
