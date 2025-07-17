import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:prokit_socialv/models/SVCommentModel.dart';
import 'package:prokit_socialv/screens/home/components/SVPostComponent.dart';
import 'package:prokit_socialv/service/auth.dart';
import 'package:prokit_socialv/service/firestore_service.dart';
import 'package:prokit_socialv/utils/Translations.dart';

import '../../../utils/SVCommon.dart';

class MyPostScreen extends StatefulWidget {
  const MyPostScreen({Key? key, this.uid, this.fromSaved}) : super(key: key);

  @override
  State<MyPostScreen> createState() => _MyPostScreenState(uid, fromSaved);
  final String? uid;
  final bool? fromSaved;
}

class _MyPostScreenState extends State<MyPostScreen> {
  final String? uid;
  final bool? fromSaved;
  String? username;

  _MyPostScreenState(this.uid, this.fromSaved);

  @override
  void initState() {
    FirestoreService().getUser(uid).then((user) => {
          setState(() {
            username = user?.name;
          })
        });
    super.initState();
  }

  final s = Translations();

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) => Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: svGetScaffoldColor(),
        appBar: AppBar(
          backgroundColor: svGetScaffoldColor(),
          title: Text(
              (AuthService().getUid() == uid)
                  ? (fromSaved == true)
                      ? s.savedPosts
                      : s.myPosts
                  : "$username" + s.sPosts,
              style: boldTextStyle(size: 20)),
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: context.iconColor),
        ),
        body: SingleChildScrollView(
            child: SVPostComponent(
          uid: uid,
          fromSave: fromSaved,
          fromAnother: fromSaved != true,
        )),
      ),
    );
  }
}
