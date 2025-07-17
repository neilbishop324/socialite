import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:prokit_socialv/models/SVSearchModel.dart';
import 'package:prokit_socialv/screens/profile/screens/CreateGroupScreen.dart';
import 'package:prokit_socialv/screens/profile/screens/ShowGroupScreen.dart';
import 'package:prokit_socialv/service/auth.dart';
import 'package:prokit_socialv/service/firestore_service.dart';
import 'package:prokit_socialv/utils/Extensions.dart';
import 'package:prokit_socialv/utils/SVCommon.dart';
import 'package:prokit_socialv/utils/Translations.dart';

import '../../../model/Group.dart';
import '../../search/components/SVSearchCardComponent.dart';
import 'JoinGroupsScreen.dart';

class SVGroupProfileScreen extends StatefulWidget {
  const SVGroupProfileScreen({Key? key}) : super(key: key);

  @override
  State<SVGroupProfileScreen> createState() => _SVGroupProfileScreenState();
}

class _SVGroupProfileScreenState extends State<SVGroupProfileScreen> {
  final firestoreService = FirestoreService();

  @override
  void initState() {
    _getGroups();
    super.initState();
  }

  final s = Translations();

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          Navigator.pop(context, {setState(() {})});
          return true;
        },
        child: Scaffold(
          backgroundColor: svGetScaffoldColor(),
          appBar: AppBar(
            backgroundColor: svGetScaffoldColor(),
            iconTheme: IconThemeData(color: context.iconColor),
            title: Text(s.yourGroups, style: boldTextStyle(size: 20)),
            elevation: 0,
            centerTitle: true,
            actions: [
              IconButton(
                  onPressed: () {
                    handleAttachmentPressed(context, [
                      NameAndAction(s.createaGroup, () {
                        _createGroup(context);
                      }),
                      NameAndAction(s.joinGroups, () {
                        _joinGroups(context);
                      })
                    ]);
                  },
                  icon: Icon(Icons.more_horiz)),
            ],
          ),
          body: bodyWidget(context),
        ));
  }

  List<SVSearchModel> manageList = [];
  List<SVSearchModel> otherList = [];

  Widget bodyWidget(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.groupsYouManage, style: boldTextStyle()).paddingAll(16),
          (manageList.length > 0)
              ? ListView.separated(
                  padding: EdgeInsets.all(16),
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    return SVSearchCardComponent(element: manageList[index])
                        .onTap(() {
                      ShowGroupScreen(groupId: manageList[index].id)
                          .launch(context);
                    });
                  },
                  separatorBuilder: (BuildContext context, int index) {
                    return Divider(height: 20);
                  },
                  itemCount: manageList.length,
                )
              : normalButton(
                  text: s.createaGroup,
                  onPressed: () {
                    _createGroup(context);
                  }).paddingLeft(16),
          Text(s.others, style: boldTextStyle()).paddingAll(16),
          (otherList.length > 0)
              ? ListView.separated(
                  padding: EdgeInsets.all(16),
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    return SVSearchCardComponent(element: otherList[index])
                        .onTap(() {
                      ShowGroupScreen(groupId: otherList[index].id)
                          .launch(context);
                    });
                  },
                  separatorBuilder: (BuildContext context, int index) {
                    return Divider(height: 20);
                  },
                  itemCount: otherList.length,
                )
              : normalButton(
                  text: s.joinGroups,
                  onPressed: () {
                    _joinGroups(context);
                  }).paddingLeft(16),
        ],
      ),
    );
  }

  void _createGroup(BuildContext context) {
    CreateGroupScreen().launch(context);
  }

  void _joinGroups(BuildContext context) {
    JoinGroupsScreen().launch(context);
  }

  void _getGroups() async {
    final userId = AuthService().getUid();
    if (userId == null) {
      return;
    }
    final groups = await firestoreService.getGroups();
    final manageGroupList = groups
        .where((element) => element.adminId == AuthService().getUid())
        .toList();
    var participatedGroups =
        await firestoreService.getParticipatedGroups(groups, userId);

    participatedGroups = participatedGroups
        .where((element) => element.adminId != userId)
        .toList();
    setState(() {
      manageList = manageGroupList
          .map((e) => SVSearchModel(
              name: e.name,
              profileImage: e.ppUrl,
              subTitle: e.description,
              isOfficialAccount: false,
              id: e.id))
          .toList();
      otherList = participatedGroups
          .map((e) => SVSearchModel(
              name: e.name,
              profileImage: e.ppUrl,
              subTitle: e.description,
              isOfficialAccount: false,
              id: e.id))
          .toList();
    });
  }
}
