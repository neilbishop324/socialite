import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:prokit_socialv/model/Chat.dart';
import 'package:prokit_socialv/model/SVPost.dart';
import 'package:prokit_socialv/model/SVUser.dart';
import 'package:prokit_socialv/models/SVSearchModel.dart';
import 'package:prokit_socialv/service/auth.dart';
import 'package:prokit_socialv/service/firestore_service.dart';
import 'package:prokit_socialv/utils/SVColors.dart';
import 'package:prokit_socialv/utils/SVCommon.dart';
import 'package:prokit_socialv/utils/SVConstants.dart';
import 'package:prokit_socialv/utils/Translations.dart';

import '../../../model/Message.dart';
import '../../../service/message_service.dart';
import '../../../utils/Extensions.dart';

class SVSharePostBottomSheetComponent extends StatefulWidget {
  final Post post;
  const SVSharePostBottomSheetComponent({Key? key, required this.post})
      : super(key: key);

  @override
  State<SVSharePostBottomSheetComponent> createState() =>
      _SVSharePostBottomSheetComponentState(post);
}

class _SVSharePostBottomSheetComponentState
    extends State<SVSharePostBottomSheetComponent> {
  Post post;

  _SVSharePostBottomSheetComponentState(this.post);
  final s = Translations();

  @override
  void initState() {
    FirestoreService().getUser(AuthService().getUid()).then((user) => {
          setState(() {
            userPp = user?.ppUrl;
            currentUser = user;
          })
        });
    if (AuthService().getUid() != null) {
      FirestoreService().getChats(AuthService().getUid()!).then((chats) => {
            setState(() {
              chatList = chats;
              uiList = chats;
            })
          });
    }
    super.initState();
  }

  List<Chat> chatList = [];
  List<Chat> uiList = [];
  UserDetails? currentUser;

  String? userPp;
  final commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        30.height,
        Row(
          children: [
            (post.imageLink != null)
                ? Image.network(post.imageLink!,
                        height: 80, width: 80, fit: BoxFit.cover)
                    .cornerRadiusWithClipRRect(SVAppCommonRadius)
                : SizedBox(),
            10.width,
            Container(
              width: context.width() * 0.6,
              child: AppTextField(
                controller: commentController,
                textFieldType: TextFieldType.OTHER,
                decoration: InputDecoration(
                  hintText: s.writeaComment,
                  hintStyle: secondaryTextStyle(color: svGetBodyColor()),
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
        20.height,
        Container(
          decoration: BoxDecoration(
              color: svGetScaffoldColor(),
              borderRadius: radius(SVAppCommonRadius)),
          child: AppTextField(
            onChanged: (p0) {
              setState(() {
                uiList = chatList
                    .where((element) =>
                        element.name.toLowerCase().contains(p0.toLowerCase()))
                    .toList();
              });
            },
            textFieldType: TextFieldType.NAME,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: s.searchHere,
              hintStyle: secondaryTextStyle(color: svGetBodyColor()),
              prefixIcon: Image.asset('images/socialv/icons/ic_Search.png',
                      height: 16,
                      width: 16,
                      fit: BoxFit.cover,
                      color: svGetBodyColor())
                  .paddingAll(16),
            ),
          ),
        ),
        Divider(height: 40),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: uiList.map((e) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Image.network(e.image.validate(),
                            height: 56, width: 56, fit: BoxFit.cover)
                        .cornerRadiusWithClipRRect(SVAppCommonRadius),
                    10.width,
                    Row(
                      children: [
                        Text(e.name.validate(), style: boldTextStyle()),
                      ],
                      mainAxisSize: MainAxisSize.min,
                    ),
                  ],
                  mainAxisSize: MainAxisSize.min,
                ),
                AppButton(
                  shapeBorder: RoundedRectangleBorder(borderRadius: radius(4)),
                  text: s.send,
                  textStyle: secondaryTextStyle(color: white, size: 10),
                  onTap: () async {
                    final success = await sendAsMessage(e);
                    if (success) {
                      finish(context);
                    }
                  },
                  elevation: 0,
                  height: 30,
                  width: 50,
                  color: SVAppColorPrimary,
                  padding: EdgeInsets.all(0),
                ),
              ],
            ).paddingSymmetric(vertical: 8);
          }).toList(),
        )
      ],
    ).paddingAll(16);
  }

  String? chatUserToken;

  getUserToken(String? id) async {
    if (id != null) {
      chatUserToken = await FirestoreService().getUserToken(id);
    }
  }

  Future<bool> sendAsMessage(Chat e) async {
    try {
      await getUserToken(e.chatUserId);
      if (AuthService().getUid() != null) {
        final type = await FirestoreService()
            .ctrlChatType(AuthService().getUid()!, e.chatUserId);
        final fId = (type == 1) ? AuthService().getUid()! : e.chatUserId;
        final sId = (type == 1) ? e.chatUserId : AuthService().getUid()!;
        await FirestoreService().sendMessage(
            Message(
                id: Extensions.generateRandomString(12),
                from: AuthService().getUid()!,
                to: e.chatUserId,
                timeForMillis: DateTime.now().millisecondsSinceEpoch,
                messageText: commentController.text,
                messageMediaUrl: post.postId,
                type: 3,
                hasSeen: false),
            fId,
            sId);
      }
      if (chatUserToken != null) {
        sendPushMessage(chatUserToken!, s.sharedaPost, "${currentUser?.name}");
      }
      return true;
    } on FirebaseException catch (e) {
      print(e);
      showToast(e.message.toString());
      return false;
    } catch (e) {
      print(e);
      showToast(s.sthWentWrong);
      return false;
    }
  }
}
