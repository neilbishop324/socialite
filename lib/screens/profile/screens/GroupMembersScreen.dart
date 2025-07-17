import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:prokit_socialv/model/SVUser.dart';
import 'package:prokit_socialv/models/SVSearchModel.dart';
import 'package:prokit_socialv/screens/fragments/SVProfileFragment.dart';
import 'package:prokit_socialv/service/firestore_service.dart';
import 'package:prokit_socialv/utils/Extensions.dart';
import 'package:prokit_socialv/utils/Translations.dart';

import '../../../utils/SVCommon.dart';
import '../../../utils/SVConstants.dart';
import '../../search/components/SVSearchCardComponent.dart';

class GroupMembersScreen extends StatefulWidget {
  const GroupMembersScreen({Key? key, required this.id, required this.isMember})
      : super(key: key);
  final String id;
  final bool isMember;

  @override
  State<GroupMembersScreen> createState() =>
      _GroupMembersScreenState(id, isMember);
}

class _GroupMembersScreenState extends State<GroupMembersScreen> {
  _GroupMembersScreenState(this.groupId, this.isMember);
  final String groupId;
  final bool isMember;

  @override
  void initState() {
    _getMembers();
    super.initState();
  }

  final s = Translations();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: svGetScaffoldColor(),
      appBar: AppBar(
        backgroundColor: svGetScaffoldColor(),
        iconTheme: IconThemeData(color: context.iconColor),
        title: Text(s.groupMembers, style: boldTextStyle(size: 20)),
        elevation: 0,
        centerTitle: true,
      ),
      body: bodyWidget(context),
    );
  }

  List<SVSearchModel> members = [];

  Widget bodyWidget(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListView.separated(
            padding: EdgeInsets.all(16),
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              return SVSearchCardComponent(element: members[index]).onTap(() {
                SVProfileFragment(uid: members[index].id).launch(context);
              });
            },
            separatorBuilder: (BuildContext context, int index) {
              return Divider(height: 20);
            },
            itemCount: members.length,
          )
        ],
      ),
    );
  }

  void _getMembers() async {
    final ids = await FirestoreService().getIds(
        "${CollectionPath().groups}/$groupId/${CollectionPath().members}");
    final usersRef = FirebaseFirestore.instance
        .collection(CollectionPath().users)
        .where("id", whereIn: ids)
        .withConverter<UserDetails>(
          fromFirestore: (snapshot, _) =>
              UserDetails.fromJson(snapshot.data()!),
          toFirestore: (user, _) => user.toJson(),
        );

    List<QueryDocumentSnapshot<UserDetails>> usersDocs =
        await usersRef.get().then((value) => value.docs);
    final users = usersDocs.map((e) => e.data()).toList();

    setState(() {
      members = users
          .map((e) => SVSearchModel(
              name: e.name,
              profileImage: e.ppUrl,
              subTitle: e.bio,
              isOfficialAccount: false,
              id: e.id))
          .toList();
    });
  }
}
