import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:prokit_socialv/main.dart';
import 'package:prokit_socialv/model/Chat.dart';
import 'package:prokit_socialv/screens/message/screens/SVMessagesScreen.dart';
import 'package:prokit_socialv/service/auth.dart';
import 'package:prokit_socialv/service/firestore_service.dart';
import 'package:prokit_socialv/utils/Translations.dart';

import '../../../utils/SVCommon.dart';

class SVContactsScreen extends StatefulWidget {
  @override
  State<SVContactsScreen> createState() => _SVContactsScreenState();
}

class _SVContactsScreenState extends State<SVContactsScreen> {
  Color appBarColor =
      appStore.isDarkMode ? Color.fromARGB(255, 18, 18, 18) : white;
  Color bgColor = appStore.isDarkMode ? black : white;
  Color oppColor = appStore.isDarkMode ? white : black;
  Color mainTextColor =
      appStore.isDarkMode ? white : Color.fromARGB(255, 34, 34, 34);
  Color otherTextColor = appStore.isDarkMode
      ? Color.fromARGB(255, 89, 89, 89)
      : Color.fromARGB(255, 60, 60, 60);

  final authService = AuthService();
  final firestoreService = FirestoreService();

  @override
  void initState() {
    getChats();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Translations s = Translations();
    return Observer(
        builder: (_) => Scaffold(
            backgroundColor: bgColor,
            appBar: AppBar(
              systemOverlayStyle:
                  SystemUiOverlayStyle(statusBarColor: appBarColor),
              backgroundColor: appBarColor,
              iconTheme: IconThemeData(color: oppColor),
              leadingWidth: 30,
              titleTextStyle: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 24, color: oppColor),
              title: Text(Intl.message(s.messages)),
              elevation: 0,
            ),
            body: _bodyWidget()));
  }

  int chatIndex = 0;

  List<Chat> chats = [];
  final s = Translations();

  Widget _bodyWidget() {
    return Stack(children: [
      Column(children: [
        Expanded(
            child: Container(
                width: double.infinity,
                decoration: BoxDecoration(color: bgColor),
                child: ListView.builder(
                    itemCount: chats.length,
                    itemBuilder: (BuildContext context, int index) {
                      final chat = chats[index];
                      return InkWell(
                        onTap: () {
                          SVMessagesScreen(uid: chat.chatUserId)
                              .launch(context);
                        },
                        child: Container(
                          width: MediaQuery.of(context).size.width - 20,
                          margin: EdgeInsets.only(
                              top: 5.0, bottom: 5.0, left: 10.0, right: 10.0),
                          padding: EdgeInsets.symmetric(
                              horizontal: 20.0, vertical: 10.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  CircleAvatar(
                                    radius: 32.0,
                                    backgroundImage: NetworkImage(chat.image),
                                  ),
                                  SizedBox(width: 10.0),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        chat.name,
                                        style: TextStyle(
                                          color: mainTextColor,
                                          fontSize: 15.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 5.0),
                                      Container(
                                        child: Text(
                                          ((chat.byCurrentUser)
                                                  ? s.you + ": "
                                                  : "") +
                                              ((chat.lastMessageType == 1)
                                                  ? "${chat.lastMessage}"
                                                  : (chat.lastMessageType == 2)
                                                      ? "🏞️ " + s.imageFile
                                                      : "📬 " + s.postFile),
                                          style: TextStyle(
                                            color: otherTextColor,
                                            fontSize: 15.0,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Column(
                                children: <Widget>[
                                  Text(
                                    chat.time,
                                    style: TextStyle(
                                      color: otherTextColor,
                                      fontSize: 15.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 5.0),
                                  Visibility(
                                      visible: chat.hasNewMessage,
                                      child: Container(
                                        color: Color.fromARGB(255, 7, 120, 220),
                                        width: 20,
                                        height: 20,
                                        child: Align(
                                            child: Text(
                                                chat.newMessageSize.toString(),
                                                style:
                                                    TextStyle(color: white))),
                                      ).cornerRadiusWithClipRRect(100))
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    })))
      ]),
    ]);
  }

  getChats() async {
    final userUid = authService.getUid();
    if (userUid == null) {
      return;
    }
    firestoreService.getChats(userUid).then((chatList) {
      setState(() {
        chats = sortList(chatList);
      });
    });
  }

  List<Chat> sortList(List<Chat> list) {
    List<Chat> sortedList = List.from(list);
    sortedList.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sortedList;
  }
}
