import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:flutter/widgets.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:prokit_socialv/model/LiveStream.dart' as live;
import 'package:prokit_socialv/models/SVPostModel.dart';
import 'package:prokit_socialv/screens/stream/pages/BroadcastScreen.dart';
import 'package:prokit_socialv/screens/stream/pages/GoLiveScreen.dart';
import 'package:prokit_socialv/service/firestore_service.dart';
import 'package:prokit_socialv/utils/SVColors.dart';
import 'package:prokit_socialv/utils/Translations.dart';

import '../../../main.dart';
import '../../../utils/Extensions.dart';
import '../../../utils/SVConstants.dart';

class StreamsScreen extends StatefulWidget {
  const StreamsScreen({Key? key}) : super(key: key);

  @override
  State<StreamsScreen> createState() => _StreamsScreenState();
}

class _StreamsScreenState extends State<StreamsScreen> {
  final oppositeColor = (appStore.isDarkMode) ? white : black;
  final s = Translations();
  bool globalPosts = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          s.liveStreams,
          style: TextStyle(color: oppositeColor),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: oppositeColor),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: SVAppColorPrimary,
        onPressed: () => GoLiveScreen().launch(context),
        icon: Icon(
          Icons.videocam,
          color: Colors.white,
        ),
        label: Text(
          s.goLive,
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          streams(context),
        ],
      ),
    );
  }

  Widget streams(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection(CollectionPath().liveStream)
          .orderBy("startedAt", descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData) {
          return Container(child: Align(child: CircularProgressIndicator()));
        }
        if (snapshot.data?.docs == null || snapshot.data!.docs.isEmpty) {
          return Expanded(
            flex: 1,
            child: Center(
              child: Text(
                s.noStreams,
                style: TextStyle(fontSize: 16),
              ),
            ),
          );
        }
        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            DocumentSnapshot documentSnapshot = snapshot.data!.docs[index];
            live.LiveStream liveStream = live.LiveStream(
              title: documentSnapshot['title']! as String,
              image: documentSnapshot['image']! as String,
              uid: documentSnapshot['uid']! as String,
              username: documentSnapshot['username']! as String,
              viewers: documentSnapshot['viewers']! as int,
              channelId: documentSnapshot['channelId']! as String,
              startedAt: documentSnapshot['startedAt']! as Timestamp,
            );
            return stream(context, liveStream);
          },
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
        );
      },
    );
  }

  Widget stream(BuildContext context, live.LiveStream liveStream) {
    double screenWidth = MediaQuery.of(context).size.width;
    return InkWell(
      onTap: () async {
        await FirestoreService().updateViewCount(liveStream.channelId, true);
        BroadcastScreen(isBroadcaster: false, channelId: liveStream.channelId)
            .launch(context);
      },
      child: Row(
        children: [
          Container(
            color: Color.fromARGB(255, 62, 62, 62),
            alignment: Alignment.center,
            child: Image.network(
              liveStream.image,
              width: (screenWidth - 56) / 2,
              height: ((9 * screenWidth) - 504) / 32,
            ),
          ).cornerRadiusWithClipRRect(10).paddingRight(24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  liveStream.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ).paddingBottom(4),
                Text(liveStream.username, style: secondaryTextStyle(size: 15))
                    .paddingBottom(4),
                Text(liveStream.viewers.toString() + " " + s.viewers,
                        style: secondaryTextStyle())
                    .paddingBottom(2),
                Text(
                    getTimeDifference((liveStream.startedAt as Timestamp)
                            .millisecondsSinceEpoch) +
                        " " +
                        s.ago,
                    style: secondaryTextStyle())
              ],
            ),
          ),
        ],
      ).paddingAll(16),
    );
  }
}
