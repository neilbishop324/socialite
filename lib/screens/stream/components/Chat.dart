import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:prokit_socialv/model/SVUser.dart';
import 'package:prokit_socialv/screens/credit/logic/in_app_service.dart';
import 'package:prokit_socialv/service/auth.dart';
import 'package:prokit_socialv/service/firestore_service.dart';
import 'package:prokit_socialv/utils/SVCommon.dart';
import 'package:prokit_socialv/utils/SVConstants.dart';

import '../../../utils/Translations.dart';

class Chat extends StatefulWidget {
  final String channelId;
  final UserDetails? user;
  final RtcEngine? engine;
  const Chat(
      {Key? key, required this.channelId, this.user, required this.engine})
      : super(key: key);

  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  final chatController = TextEditingController();

  bool switchCamera = true;
  bool isMuted = false;
  bool userLiked = false;

  @override
  void dispose() {
    chatController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _ctrlIfUserLiked();
  }

  _ctrlIfUserLiked() async {
    final userId = AuthService().getUid();
    final channelId = widget.channelId;
    final snapshot = await likeRef(channelId, userId).get();
    userLiked = snapshot.exists;
    setState(() {});
  }

  DocumentReference likeRef(String channelId, String? userId) =>
      FirebaseFirestore.instance
          .collection(CollectionPath().liveStream)
          .doc(channelId)
          .collection(CollectionPath().likes)
          .doc(userId);

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return SizedBox(
      width: size.width,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Expanded(flex: 1, child: SizedBox()),
          Expanded(
            flex: 2,
            child: StreamBuilder<dynamic>(
              stream: FirebaseFirestore.instance
                  .collection(CollectionPath().liveStream)
                  .doc(widget.channelId)
                  .collection(CollectionPath().comments)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: SizedBox(
                      width: 35,
                      height: 35,
                      child: const CircularProgressIndicator(),
                    ),
                  );
                }
                List<DocumentSnapshot<Map<String, dynamic>>> comments =
                    snapshot.data.docs;
                List<DocumentSnapshot<Map<String, dynamic>>>
                    typeThreeOrFourComments = [];
                List<DocumentSnapshot<Map<String, dynamic>>> otherComments = [];

                // Partition comments into two lists based on type
                for (var comment in comments) {
                  if (comment['type'] == 2 || comment['type'] == 4) {
                    typeThreeOrFourComments.add(comment);
                  } else {
                    otherComments.add(comment);
                  }
                }

                // Sort the two lists by createdAt
                typeThreeOrFourComments
                    .sort((a, b) => b['createdAt'].compareTo(a['createdAt']));

                otherComments
                    .sort((a, b) => b['createdAt'].compareTo(a['createdAt']));

                // Concatenate the two sorted lists
                comments = typeThreeOrFourComments + otherComments;
                print(comments.map((e) => e['message']).join(' '));
                return ListView.builder(
                  reverse: true,
                  itemCount: comments.length,
                  itemBuilder: (context, index) => ListTile(
                    leading: userImage(
                        comments[index]['uid'],
                        comments[index]['type'] == 2 ||
                            comments[index]['type'] == 4),
                    title: Visibility(
                      visible: comments[index]['type'] == 1 ||
                          comments[index]['type'] == 2,
                      child: Text(
                        comments[index]['username'],
                        style: TextStyle(
                          color: comments[index]['uid'] == widget.user?.id
                              ? Color.fromARGB(255, 20, 212, 242)
                              : comments[index]['type'] == 2 ||
                                      comments[index]['type'] == 4
                                  ? purple
                                  : null,
                        ),
                      ),
                    ),
                    subtitle: Text(
                      comments[index]["message"],
                      style: comments[index]['type'] == 3 ||
                              comments[index]['type'] == 4
                          ? TextStyle(
                              color: purple,
                              fontStyle: FontStyle.italic,
                              fontSize: 16)
                          : null,
                    ),
                  ),
                );
              },
            ),
          ),
          Row(
            children: [
              Expanded(
                child: normalTextField(
                  focusNode: FocusNode(),
                  hintText: Translations().writeaComment,
                  controller: chatController,
                  maxLines: 1,
                  borderRadius: 20,
                  onTap: (p0) {
                    FirestoreService()
                        .addCommentToLivestream(
                            p0, widget.channelId, context, widget.user)
                        .then((value) => {
                              setState(
                                () => {chatController.text = ''},
                              ),
                            });
                  },
                ),
              ),
              Visibility(
                visible: widget.channelId !=
                    '${widget.user?.id}${widget.user?.username}',
                child: InkWell(
                  onTap: () => _sendGift(context),
                  child: Image.asset(
                    'images/socialv/icons/gift-pngrepo-com.png',
                    color: white,
                    width: 30,
                    height: 30,
                  ),
                ).paddingOnly(left: 16),
              ),
              Visibility(
                visible: widget.channelId ==
                    '${widget.user?.id}${widget.user?.username}',
                child: InkWell(
                  onTap: () => _onToggleMute(),
                  child: Icon(
                    isMuted ? Icons.volume_up : Icons.volume_off,
                    color: white,
                    size: 30,
                  ),
                ).paddingOnly(left: 16),
              ),
              InkWell(
                onTap: () {
                  if (chatController.text.isNotEmpty) {
                    FirestoreService()
                        .addCommentToLivestream(chatController.text,
                            widget.channelId, context, widget.user)
                        .then((value) => {
                              setState(
                                () => {chatController.text = ''},
                              ),
                            });
                  }
                },
                child: Image.asset(
                  'images/socialv/icons/ic_Send.png',
                  color: white,
                  width: 30,
                  height: 30,
                ),
              ).paddingSymmetric(horizontal: 8),
              Visibility(
                visible: widget.channelId !=
                    '${widget.user?.id}${widget.user?.username}',
                child: InkWell(
                  onTap: () => _likeEvent(),
                  child: Image.asset(
                    userLiked
                        ? 'images/socialv/icons/ic_HeartFilled.png'
                        : 'images/socialv/icons/ic_Heart.png',
                    color: userLiked ? redColor : white,
                    width: 30,
                    height: 30,
                  ),
                ),
              ),
              Visibility(
                visible: widget.channelId ==
                    '${widget.user?.id}${widget.user?.username}',
                child: InkWell(
                  onTap: () => _switchCamera(),
                  child: Icon(
                    Icons.switch_camera,
                    color: white,
                    size: 30,
                  ),
                ),
              ),
            ],
          ).paddingAll(8),
        ],
      ),
    );
  }

  void _switchCamera() {
    widget.engine?.switchCamera().then((value) {
      setState(() {
        switchCamera = !switchCamera;
      });
    }).catchError((err) {
      debugPrint('switchCamera $err');
    });
  }

  void _onToggleMute() async {
    setState(() {
      isMuted = !isMuted;
    });
    await widget.engine?.muteLocalAudioStream(isMuted);
  }

  userImage(doc, isVip) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Visibility(
          visible: isVip,
          child: Image.asset(
            'images/socialv/icons/vip-pngrepo-com.png',
            color: purple,
            width: 40,
            height: 40,
          ).paddingRight(8),
        ),
        FutureBuilder(
          future: getUserImage(doc),
          builder: (context, AsyncSnapshot<String?> snapshot) {
            if (!snapshot.hasData || snapshot.data == null) {
              return Container(
                color: white,
                width: 40,
                height: 40,
                child: Image.asset('images/socialv/icons/user-pngrepo-com.png')
                    .paddingAll(4),
              ).cornerRadiusWithClipRRect(20);
            }
            return Container(
              color: white,
              width: 40,
              height: 40,
              child: Image.network(
                snapshot.data!,
                fit: BoxFit.fitHeight,
              ),
            ).cornerRadiusWithClipRRect(20);
          },
        ),
      ],
    );
  }

  Future<String?> getUserImage(String uid) async {
    final user = await FirestoreService().getUser(uid);
    return user?.ppUrl;
  }

  _likeEvent() async {
    final userId = AuthService().getUid();
    if (userLiked) {
      await likeRef(widget.channelId, userId).delete();
    } else {
      await likeRef(widget.channelId, userId).set({"id": userId});
    }
    setState(() {
      userLiked = !userLiked;
    });
  }

  _sendGift(BuildContext context) async {
    final snapshot = await FirebaseFirestore.instance
        .collection(CollectionPath().liveStream)
        .doc(widget.channelId)
        .get();
    final userId = snapshot['uid'];
    await InAppService()
        .showSendGiftDialog(context, userId, channelId: widget.channelId);
  }
}
