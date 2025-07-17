import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:prokit_socialv/model/SVUser.dart';
import 'package:prokit_socialv/models/SVSearchModel.dart';
import 'package:prokit_socialv/screens/fragments/SVProfileFragment.dart';
import 'package:prokit_socialv/screens/search/components/SVSearchCardComponent.dart';
import 'package:prokit_socialv/service/auth.dart';
import 'package:prokit_socialv/service/firestore_service.dart';
import 'package:prokit_socialv/service/message_service.dart';
import 'package:prokit_socialv/utils/Extensions.dart';
import 'package:prokit_socialv/utils/SVCommon.dart';
import 'package:prokit_socialv/utils/SVConstants.dart';
import 'package:prokit_socialv/utils/Translations.dart';

class SVSearchFragment extends StatefulWidget {
  @override
  State<SVSearchFragment> createState() => _SVSearchFragmentState();
}

class _SVSearchFragmentState extends State<SVSearchFragment> {
  List<SVSearchModel> recentList = [];
  List<UserDetails> recentUserList = [];

  List<SVSearchModel> filterableList = [];
  List<UserDetails> filterableUserList = [];

  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    afterBuildCreated(() {
      setStatusBarColor(svGetScaffoldColor());
    });
  }

  @override
  void didChangeDependencies() async {
    _getUsers();
    super.didChangeDependencies();
  }

  final s = Translations();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: svGetScaffoldColor(),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: svGetScaffoldColor(),
        iconTheme: IconThemeData(color: context.iconColor),
        leadingWidth: 30,
        title: Container(
          decoration:
              BoxDecoration(color: context.cardColor, borderRadius: radius(8)),
          child: AppTextField(
            onChanged: ((p0) {
              _filterList(p0);
              setState(() {});
            }),
            controller: _searchController,
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
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                    (_searchController.text.isEmptyOrNull)
                        ? (recentList.length > 0)
                            ? s.recent
                            : ''
                        : (filterableList.length > 0)
                            ? s.users
                            : '',
                    style: boldTextStyle())
                .paddingAll((_searchController.text.isEmptyOrNull &&
                        (recentList.length == 0 || filterableList.length == 0))
                    ? 0
                    : 16),
            ListView.separated(
              padding: EdgeInsets.all(16),
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                return SVSearchCardComponent(
                        element: (_searchController.text.isEmptyOrNull)
                            ? recentList[index]
                            : filterableList[index])
                    .onTap(() {
                  SVProfileFragment(
                    uid: (_searchController.text.isEmptyOrNull)
                        ? recentList[index].id
                        : filterableList[index].id,
                  ).launch(context);
                  if (!_searchController.text.isEmptyOrNull) {
                    _searchUser(filterableList[index].id);
                  }
                });
              },
              separatorBuilder: (BuildContext context, int index) {
                return Divider(height: 20);
              },
              itemCount: (_searchController.text.isEmptyOrNull)
                  ? recentList.length
                  : filterableList.length,
            ),
          ],
        ),
      ),
    );
  }

  void _getUsers() {
    FirestoreService().getUsers().then((users) async => {
          _getFilterableList(users),
          _getRecentList(users),
          setState(
            () {},
          )
        });
  }

  final db = FirebaseFirestore.instance;

  void _searchUser(String postId) {
    final uid = AuthService().getUid();
    if (uid == null) {
      return;
    }
    db
        .collection(CollectionPath().users)
        .doc(uid)
        .collection(CollectionPath().search)
        .doc(postId)
        .set({"id": postId});
  }

  void _getFilterableList(List<UserDetails> users) async {
    filterableUserList =
        await FirestoreService().filterUsers(users, AuthService().getUid()!);
    filterableList = filterableUserList
        .map((e) => SVSearchModel(
            name: e.name,
            profileImage: e.ppUrl,
            subTitle: e.bio,
            isOfficialAccount: false,
            id: e.id))
        .toList();
  }

  void _getRecentList(List<UserDetails> users) async {
    final uid = AuthService().getUid();
    if (uid == null) {
      return;
    }
    final searchSS = await db
        .collection(CollectionPath().users)
        .doc(uid)
        .collection(CollectionPath().search)
        .get();
    final ids = searchSS.docs.map((doc) => doc["id"] as String).toList();

    for (UserDetails userDetails in users) {
      if (ids.contains(userDetails.id)) {
        recentUserList.add(userDetails);
      }
    }

    setState(() {
      recentList = recentUserList
          .map((e) => SVSearchModel(
              name: e.name,
              profileImage: e.ppUrl,
              subTitle: e.bio,
              isOfficialAccount: false,
              id: e.id))
          .toList();
    });
  }

  void _filterList(String input) {
    if (input.isEmptyOrNull) {
      filterableList = filterableUserList
          .map((e) => SVSearchModel(
              name: e.name,
              profileImage: e.ppUrl,
              subTitle: e.bio,
              isOfficialAccount: false,
              id: e.id))
          .toList();
    } else {
      filterableList = filterableList
          .where((element) =>
              (element.name ?? "")
                  .toLowerCase()
                  .contains(input.toLowerCase()) ||
              (element.subTitle ?? "")
                  .toLowerCase()
                  .contains(input.toLowerCase()))
          .toList();
    }
  }
}
