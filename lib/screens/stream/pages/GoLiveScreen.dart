import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:prokit_socialv/screens/stream/pages/BroadcastScreen.dart';
import 'package:prokit_socialv/service/firestore_service.dart';

import '../../../main.dart';
import '../../../utils/SVCommon.dart';
import '../../../utils/Translations.dart';

class GoLiveScreen extends StatefulWidget {
  const GoLiveScreen({Key? key}) : super(key: key);

  @override
  State<GoLiveScreen> createState() => _GoLiveScreenState();
}

class _GoLiveScreenState extends State<GoLiveScreen> {
  final oppositeColor = (appStore.isDarkMode) ? white : black;
  final s = Translations();

  final titleController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          s.goLive,
          style: TextStyle(color: oppositeColor),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: oppositeColor),
      ),
      body: Align(
        alignment: Alignment.center,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              selectThumbnail(),
              normalTextField(
                focusNode: FocusNode(),
                labelText: s.title,
                controller: titleController,
              ).paddingSymmetric(horizontal: 16, vertical: 8),
              normalButton(
                text: s.goLive,
                onPressed: () => goLiveNow(context),
                matchParent: true,
              ).paddingAll(16)
            ],
          ),
        ),
      ),
    );
  }

  String? imageUri;

  Widget selectThumbnail() {
    return DottedBorderWidget(
      color: appStore.isDarkMode ? white : black,
      gap: 6,
      radius: 20,
      strokeWidth: 1,
      child: InkWell(
        onTap: () async {
          imageUri = await handleImageSelection();
          setState(() {});
        },
        child: Container(
          alignment: Alignment.center,
          height: 200,
          child: imageUri == null
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.folder_open,
                      size: 40,
                    ).paddingBottom(10),
                    Text(
                      s.selectThumb,
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    )
                  ],
                )
              : Image.file(File(imageUri!)),
        ).cornerRadiusWithClipRRect(20),
      ),
    ).paddingAll(24);
  }

  goLiveNow(BuildContext context) async {
    final firebaseService = FirestoreService();
    if (titleController.text.isEmptyOrNull) {
      showToast(s.titleRequired);
      return;
    }
    if (imageUri == null) {
      showToast(s.imageRequired);
      return;
    }
    String channelId = await firebaseService.startLiveStream(
        context, titleController.text, imageUri!);

    if (channelId.isNotEmpty) {
      showToast(s.liveStreamSuccess);
      BroadcastScreen(
        isBroadcaster: true,
        channelId: channelId,
      ).launch(context);
    }
  }
}
