import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:prokit_socialv/model/SVUser.dart';
import 'package:prokit_socialv/service/firestore_service.dart';
import 'package:prokit_socialv/utils/SVColors.dart';
import 'package:prokit_socialv/utils/SVCommon.dart';

import '../../../main.dart';
import '../../../service/auth.dart';
import '../../../utils/Translations.dart';

class NewConfessionScreen extends StatefulWidget {
  const NewConfessionScreen({Key? key}) : super(key: key);

  @override
  State<NewConfessionScreen> createState() => _NewConfessionScreenState();
}

class _NewConfessionScreenState extends State<NewConfessionScreen> {
  final oppositeColor = (appStore.isDarkMode) ? white : black;
  final s = Translations();
  bool isAnonymous = false;

  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  UserDetails? currentUser;

  @override
  void initState() {
    final userId = AuthService().getUid();
    FirestoreService().getUser(userId).then((user) => {currentUser = user});
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          s.makeAConfession,
          style: TextStyle(color: oppositeColor),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: oppositeColor),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _makeConfession(),
        icon: Icon(
          Icons.post_add,
          color: white,
        ),
        backgroundColor: SVAppColorPrimary,
        label: Text(
          s.share,
          style: TextStyle(color: white),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            normalTextField(
              focusNode: FocusNode(),
              controller: _titleController,
              labelText: s.title,
              maxLength: 120,
            ).paddingAll(12),
            normalTextField(
              focusNode: FocusNode(),
              controller: _descController,
              labelText: s.desc,
              keyboardType: TextInputType.multiline,
              maxLines: 10,
              maxLength: 3000,
            ).paddingAll(12),
            Row(
              children: [
                Switch(
                  value: isAnonymous,
                  onChanged: (anonym) => {
                    setState(
                      () => {
                        isAnonymous = anonym,
                      },
                    ),
                  },
                ).paddingOnly(left: 6, right: 12),
                Text(
                  s.anonim,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                )
              ],
            ),
          ],
        ).paddingAll(12),
      ),
    );
  }

  _makeConfession() async {
    final title = _titleController.text;
    final desc = _descController.text;

    if (title.isEmptyOrNull) {
      showToast(s.titleRequired);
      return;
    }

    if (desc.isEmptyOrNull) {
      showToast(s.descRequired);
      return;
    }

    if (currentUser == null) {
      return;
    }
    final responseOk = await FirestoreService()
        .shareConfession(title, desc, isAnonymous, currentUser!.id);
    if (responseOk) {
      showToast(s.successConfess);
      finish(context);
    }
  }
}
