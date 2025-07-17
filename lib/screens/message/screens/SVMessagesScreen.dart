import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:prokit_socialv/main.dart';
import 'package:prokit_socialv/model/Message.dart';
import 'package:prokit_socialv/model/SVUser.dart';
import 'package:prokit_socialv/model/Story.dart';
import 'package:prokit_socialv/screens/message/screens/PostScreen.dart';
import 'package:prokit_socialv/service/auth.dart';
import 'package:prokit_socialv/service/firestore_service.dart';
import 'package:prokit_socialv/service/message_service.dart';
import 'package:prokit_socialv/utils/Extensions.dart';
import 'package:prokit_socialv/utils/SVConstants.dart';
import 'package:path/path.dart';
import 'package:prokit_socialv/utils/Translations.dart';

import '../../../model/SVPost.dart';
import '../../../models/SVStoryModel.dart';
import '../../../utils/SVCommon.dart';
import '../../home/components/SVPostComponent.dart';
import '../../home/screens/SVStoryScreen.dart';

class SVMessagesScreen extends StatefulWidget {
  final String? uid;
  const SVMessagesScreen({Key? key, this.uid}) : super(key: key);

  @override
  State<SVMessagesScreen> createState() => _ChatPageState(uid);
}

class _ChatPageState extends State<SVMessagesScreen> {
  final String? chatUid;
  String? currentUid;
  UserDetails? chatUser;
  UserDetails? currentUser;
  String? firstUserId;
  String? secondUserId;
  final firestoreService = FirestoreService();
  final authService = AuthService();

  final messageController = TextEditingController();
  final oppositeColor = appStore.isDarkMode ? white : black;

  _ChatPageState(this.chatUid);
  final s = Translations();

  @override
  void initState() {
    if (chatUid != null) {
      firestoreService.getUser(chatUid).then((user) => {
            setState(() {
              chatUser = user;
            }),
            getUserToken(user?.id)
          });
    }
    currentUid = authService.getUid();
    if (currentUid != null) {
      firestoreService.getUser(currentUid).then((user) => {
            setState(() {
              currentUser = user;
            })
          });
    }
    ctrlTypes();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) => Scaffold(
        backgroundColor: svGetScaffoldColor(),
        appBar: AppBar(
          backgroundColor: svGetScaffoldColor(),
          title: Row(
            children: [
              (chatUser == null)
                  ? Image.asset("images/socialv/faces/face_5.png",
                          height: 40, width: 40)
                      .cornerRadiusWithClipRRect(100)
                  : Image.network(chatUser!.ppUrl, height: 40, width: 40)
                      .cornerRadiusWithClipRRect(100),
              16.width,
              Text(chatUser?.name ?? s.deletedAccount,
                  style: boldTextStyle(size: 20))
            ],
          ),
          elevation: 0,
          iconTheme: IconThemeData(color: context.iconColor),
        ),
        body: Stack(
          children: [
            Column(
              children: [
                _bodyChat(),
                SizedBox(
                  height: 120,
                )
              ],
            ),
            _formChat(context),
          ],
        ),
      ),
    );
  }

  Widget _bodyChat() {
    return Expanded(
      child: Container(
        padding: EdgeInsets.only(left: 25, right: 25, top: 25),
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(45), topRight: Radius.circular(45)),
          color: (appStore.isDarkMode)
              ? Color.fromARGB(255, 18, 18, 18)
              : Colors.white,
        ),
        child: (collRef.isEmptyOrNull)
            ? SizedBox()
            : StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection(CollectionPath().chats)
                    .doc(collRef)
                    .collection(CollectionPath().messages)
                    .orderBy("timeForMillis")
                    .snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (!snapshot.hasData) {
                    return SizedBox();
                  }
                  return ListView.builder(
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        DocumentSnapshot documentSnapshot =
                            snapshot.data!.docs[index];
                        Message message = Message(
                            id: documentSnapshot['id'],
                            from: documentSnapshot['from'],
                            to: documentSnapshot['to'],
                            timeForMillis: documentSnapshot['timeForMillis'],
                            messageText: documentSnapshot['messageText'],
                            messageMediaUrl:
                                documentSnapshot['messageMediaUrl'],
                            type: documentSnapshot['type'],
                            hasSeen: documentSnapshot['hasSeen']);
                        return _itemChat(context,
                            chat: (message.from == currentUid) ? 0 : 1,
                            message: (message.type == 1)
                                ? message.messageText
                                : message.messageMediaUrl,
                            type: message.type,
                            messageModel: message);
                      },
                      physics: BouncingScrollPhysics());
                },
              ),
      ),
    );
  }

  _itemChat(BuildContext context,
      {int? chat, String? message, int? type, Message? messageModel}) {
    return Row(
      mainAxisAlignment:
          chat == 0 ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        chat == 0 ? 40.width : 0.width,
        Flexible(
          child: Container(
            margin: EdgeInsets.only(left: 10, right: 10, top: 20),
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: chat == 0
                  ? (appStore.isDarkMode)
                      ? Color.fromARGB(255, 40, 36, 36)
                      : Colors.indigo.shade100
                  : (appStore.isDarkMode)
                      ? Colors.deepPurple
                      : Colors.indigo.shade50,
              borderRadius: chat == 0
                  ? BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                      bottomLeft: Radius.circular(30),
                    )
                  : BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
            ),
            child: (type == 1)
                ? Text('$message')
                : (type == 2)
                    ? Container(
                        height: 200,
                        width: 200,
                        child: Image.network(
                          message.toString(),
                          fit: BoxFit.cover,
                        )).cornerRadiusWithClipRRect(SVAppCommonRadius)
                    : (type == 3)
                        ? postLay(messageModel, context)
                        : storyLay(messageModel, context),
          ),
        ),
      ],
    );
  }

  Widget postLay(Message? message, BuildContext context) {
    return InkWell(
        onTap: () {
          PostScreen(id: message!.messageMediaUrl).launch(context);
        },
        child: FutureBuilder(
          future: FirebaseFirestore.instance
              .collection(CollectionPath().posts)
              .doc(message!.messageMediaUrl)
              .get(),
          builder: (context, AsyncSnapshot<DocumentSnapshot> otherSnapshot) {
            final ds = otherSnapshot.data;
            if (!otherSnapshot.hasData || ds == null) {
              return CircularProgressIndicator();
            }

            Post post = Post(
                posterName: ds['posterName'],
                timeForMillis: ds['timeForMillis'],
                imageLink: ds['imageLink'],
                description: ds['description'],
                isForStory: ds['isForStory'],
                postId: ds['postId'],
                postContextId: ds['postContextId']);
            return Column(children: [
              Container(
                color: (appStore.isDarkMode)
                    ? Color.fromARGB(255, 54, 50, 50)
                    : Color.fromARGB(255, 239, 239, 239),
                child: Column(
                  children: [
                    (post.imageLink == null)
                        ? SizedBox()
                        : Container(
                            width: 200,
                            child: Image.network(
                              post.imageLink!,
                              fit: BoxFit.cover,
                            )),
                    FutureBuilder(
                        future: FirebaseFirestore.instance
                            .collection(CollectionPath().users)
                            .doc(post.posterName)
                            .get(),
                        builder: (c, AsyncSnapshot<DocumentSnapshot> otherSS2) {
                          final ds2 = otherSS2.data;
                          if (!otherSS2.hasData || ds2 == null) {
                            return CircularProgressIndicator();
                          }
                          UserDetails userDetails = UserDetails(
                              name: ds2['name'],
                              username: ds2['name'],
                              ppUrl: ds2['ppUrl'],
                              bgUrl: ds2['bgUrl'],
                              gender: ds2['gender'],
                              birthDay: ds2['birthDay'],
                              bio: ds2['bio'],
                              active: ds2['active'],
                              location: UserLocation.fromJson(ds2['location']),
                              id: ds2['id']);
                          return Text(
                            userDetails.name,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ).paddingTop(12).paddingBottom(
                              post.description.isEmptyOrNull ? 8 : 0);
                        }),
                    (post.description.isEmptyOrNull)
                        ? SizedBox()
                        : Text(post.description!).paddingAll(8)
                  ],
                ),
              ).cornerRadiusWithClipRRect(SVAppCommonRadius).paddingAll(8),
              (message.messageText.isEmptyOrNull)
                  ? SizedBox()
                  : Text(message.messageText!)
            ]);
          },
        ));
  }

  Widget _formChat(BuildContext context) {
    return Positioned(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          height: 90,
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: TextField(
            controller: messageController,
            style: TextStyle(color: oppositeColor),
            decoration: InputDecoration(
              hintText: s.typeYourMessage,
              prefixIcon: InkWell(
                  onTap: () {
                    handleAttachmentPressed(
                        context, <NameAndAction>[_nameAndActionItem()]);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                        color: Colors.indigo),
                    child: Icon(
                      Icons.attach_file,
                      color: (appStore.isDarkMode)
                          ? Color.fromARGB(255, 44, 45, 49)
                          : Colors.white,
                      size: 28,
                    ),
                  ).paddingRight(8)),
              suffixIcon: InkWell(
                  onTap: () {
                    sendAsText();
                  },
                  child: Container(
                    padding: EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                        color: Colors.indigo),
                    child: Icon(
                      Icons.send_rounded,
                      color: (appStore.isDarkMode)
                          ? Color.fromARGB(255, 44, 45, 49)
                          : Colors.white,
                      size: 28,
                    ),
                  )),
              filled: true,
              fillColor: (appStore.isDarkMode)
                  ? Color.fromARGB(255, 44, 45, 49)
                  : Colors.blueGrey[50],
              labelStyle: TextStyle(fontSize: 12),
              contentPadding: EdgeInsets.all(20),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                    color: (appStore.isDarkMode)
                        ? Color.fromARGB(255, 44, 45, 49)
                        : Colors.blueGrey[50]!),
                borderRadius: BorderRadius.circular(25),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                    color: (appStore.isDarkMode)
                        ? Color.fromARGB(255, 44, 45, 49)
                        : Colors.blueGrey[50]!),
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ),
      ),
    );
  }

  NameAndAction _nameAndActionItem() {
    return NameAndAction(s.photo, () async {
      final imagePath = await handleImageSelection();
      if (imagePath != null) {
        sendAsImage(imagePath);
      }
    });
  }

  String collRef = "";

  ctrlTypes() {
    if (currentUid == null || chatUid == null) {
      return;
    }
    firestoreService.ctrlChatType(currentUid!, chatUid!).then((type) => {
          if (type == 2)
            {firstUserId = chatUid, secondUserId = currentUid}
          else
            {firstUserId = currentUid, secondUserId = chatUid},
          if (type != 0) {seeMessages()},
          setState(
            () {
              collRef = firstUserId! + "_" + secondUserId!;
            },
          )
        });
  }

  seeMessages() {
    firestoreService.getMessages(firstUserId!, secondUserId!).then((list) => {
          firestoreService.seeMessages(
              list, currentUid!, firstUserId!, secondUserId!)
        });
  }

  sendAsImage(String path) async {
    final downloadUrl = await firestoreService.downloadImage(
        File(path), "messages/${firstUserId}_$secondUserId");
    if (downloadUrl == null) {
      return;
    }
    final success = await firestoreService.sendMessage(
        Message(
            id: Extensions.generateRandomString(12),
            from: currentUid!,
            to: chatUid!,
            timeForMillis: DateTime.now().millisecondsSinceEpoch,
            messageText: null,
            messageMediaUrl: downloadUrl,
            type: 2,
            hasSeen: false),
        firstUserId!,
        secondUserId!);
    if (!success) {
      showToast(s.sthWentWrong);
    }
    if (chatUserToken != null) {
      sendPushMessage(chatUserToken!, s.sharedanImage, "${currentUser?.name}");
    }
    setState(() {});
  }

  sendAsText() {
    if (!messageController.text.isEmptyOrNull) {
      firestoreService
          .sendMessage(
              Message(
                  id: Extensions.generateRandomString(12),
                  from: currentUid!,
                  to: chatUid!,
                  timeForMillis: DateTime.now().millisecondsSinceEpoch,
                  messageText: messageController.text,
                  messageMediaUrl: null,
                  type: 1,
                  hasSeen: false),
              firstUserId!,
              secondUserId!)
          .then((success) => {
                if (success)
                  {messageController.text = ""}
                else
                  {showToast(s.sthWentWrong)}
              });
      if (chatUserToken != null) {
        sendPushMessage(
            chatUserToken!, messageController.text, "${currentUser?.name}");
      }
      setState(() {});
    }
  }

  String? chatUserToken;

  getUserToken(String? id) async {
    if (id != null) {
      chatUserToken = await firestoreService.getUserToken(id);
    }
  }

  Widget storyLay(Message? messageModel, BuildContext context) {
    return InkWell(
        onTap: () async {
          final story = await firestoreService.getStory(chatUid!);
          List<SVStoryModel> stories = [];
          if (story != null) {
            stories = await getStories([story]);
          }
          SVStoryScreen(
            svStoryModels: stories,
            isCurrent: messageModel?.from == story?.userId &&
                messageModel?.from == AuthService().getUid(),
            index: 0,
          ).launch(context);
        },
        child: FutureBuilder(
          future: FirebaseFirestore.instance
              .collection(CollectionPath().stories)
              .doc(messageModel!.messageMediaUrl)
              .get(),
          builder: (context, AsyncSnapshot<DocumentSnapshot> otherSnapshot) {
            final ds = otherSnapshot.data;
            if (!otherSnapshot.hasData || ds == null) {
              return CircularProgressIndicator();
            }

            if (!ds.exists) {
              return Text(
                s.thisDataDeleted,
                style: TextStyle(fontStyle: FontStyle.italic),
              );
            }

            Story story = Story(
                id: ds['id'],
                timeForMillis: ds['timeForMillis'],
                imageLink: ds['imageLink'],
                userId: ds['userId']);
            return Column(children: [
              Container(
                color: (appStore.isDarkMode)
                    ? Color.fromARGB(255, 54, 50, 50)
                    : Color.fromARGB(255, 239, 239, 239),
                child: Column(
                  children: [
                    (story.imageLink == null)
                        ? SizedBox()
                        : Container(
                            width: 200,
                            child: Image.network(
                              story.imageLink!,
                              fit: BoxFit.cover,
                            )),
                    FutureBuilder(
                        future: FirebaseFirestore.instance
                            .collection(CollectionPath().users)
                            .doc(story.userId)
                            .get(),
                        builder: (c, AsyncSnapshot<DocumentSnapshot> otherSS2) {
                          final ds2 = otherSS2.data;
                          if (!otherSS2.hasData || ds2 == null) {
                            return CircularProgressIndicator();
                          }
                          UserDetails userDetails = UserDetails(
                              name: ds2['name'],
                              username: ds2['name'],
                              ppUrl: ds2['ppUrl'],
                              bgUrl: ds2['bgUrl'],
                              gender: ds2['gender'],
                              birthDay: ds2['birthDay'],
                              bio: ds2['bio'],
                              active: ds2['active'],
                              location: UserLocation.fromJson(ds2['location']),
                              id: ds2['id']);
                          return Text(
                            userDetails.name,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ).paddingTop(12).paddingBottom(8);
                        })
                  ],
                ),
              ).cornerRadiusWithClipRRect(SVAppCommonRadius).paddingAll(8),
              (messageModel.messageText.isEmptyOrNull)
                  ? SizedBox()
                  : Text(messageModel.messageText!)
            ]);
          },
        ));
  }
}
