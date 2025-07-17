import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:prokit_socialv/model/Group.dart';
import 'package:prokit_socialv/models/SVSearchModel.dart';
import 'package:prokit_socialv/screens/profile/screens/ShowGroupScreen.dart';
import 'package:prokit_socialv/service/auth.dart';
import 'package:prokit_socialv/service/firestore_service.dart';
import 'package:prokit_socialv/utils/Translations.dart';

import '../../../utils/SVCommon.dart';
import '../../search/components/SVSearchCardComponent.dart';

class JoinGroupsScreen extends StatefulWidget {
  const JoinGroupsScreen({Key? key}) : super(key: key);

  @override
  State<JoinGroupsScreen> createState() => _JoinGroupsScreenState();
}

class _JoinGroupsScreenState extends State<JoinGroupsScreen> {
  final _searchController = TextEditingController();
  var filterableList = <SVSearchModel>[];
  var filterableGroupList = <Group>[];
  final firestore = FirestoreService();

  @override
  void initState() {
    firestore.getGroups().then((groups) => {
          filterableGroupList = groups
              .where((element) => element.adminId != AuthService().getUid())
              .toList(),
          filterableList = filterableGroupList
              .map((e) => SVSearchModel(
                  name: e.name,
                  profileImage: e.ppUrl,
                  subTitle: e.description,
                  isOfficialAccount: false,
                  id: e.id))
              .toList(),
          setState(() {})
        });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
        builder: (_) => Scaffold(
              resizeToAvoidBottomInset: false,
              backgroundColor: svGetScaffoldColor(),
              appBar: AppBar(
                backgroundColor: svGetScaffoldColor(),
                iconTheme: IconThemeData(color: context.iconColor),
                leadingWidth: 30,
                title: Container(
                  decoration: BoxDecoration(
                      color: context.cardColor, borderRadius: radius(8)),
                  child: AppTextField(
                    onChanged: ((p0) {
                      _filterList(p0);
                      setState(() {});
                    }),
                    controller: _searchController,
                    textFieldType: TextFieldType.NAME,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: Translations().searchHere,
                      hintStyle: secondaryTextStyle(color: svGetBodyColor()),
                      prefixIcon: Image.asset(
                              'images/socialv/icons/ic_Search.png',
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
                    ListView.separated(
                      padding: EdgeInsets.all(16),
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        return SVSearchCardComponent(
                                element: filterableList[index])
                            .onTap(() {
                          ShowGroupScreen(groupId: filterableList[index].id)
                              .launch(context);
                        });
                      },
                      separatorBuilder: (BuildContext context, int index) {
                        return Divider(height: 20);
                      },
                      itemCount: filterableList.length,
                    ),
                  ],
                ),
              ),
            ));
  }

  void _filterList(String input) {
    if (input.isEmptyOrNull) {
      filterableList = filterableGroupList
          .map((e) => SVSearchModel(
              name: e.name,
              profileImage: e.ppUrl,
              subTitle: e.description,
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
