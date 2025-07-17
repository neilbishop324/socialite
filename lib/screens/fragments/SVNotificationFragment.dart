import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:prokit_socialv/main.dart';
import 'package:prokit_socialv/models/SVNotificationModel.dart';
import 'package:prokit_socialv/screens/notification/components/SVLikeNotificationComponent.dart';
import 'package:prokit_socialv/screens/notification/components/SVRequestNotificationComponent.dart';
import 'package:prokit_socialv/service/auth.dart';
import 'package:prokit_socialv/service/firestore_service.dart';
import 'package:prokit_socialv/utils/SVCommon.dart';
import 'package:prokit_socialv/utils/SVConstants.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:prokit_socialv/model/Notification.dart' as not_pac;
import 'package:prokit_socialv/utils/Translations.dart';

class SVNotificationFragment extends StatefulWidget {
  @override
  State<SVNotificationFragment> createState() => _SVNotificationFragmentState();
}

class _SVNotificationFragmentState extends State<SVNotificationFragment> {
  List<SVNotificationModel> svNotificationList = [];
  List<not_pac.Notification> notificationList = [];
  FirestoreService firestoreService = FirestoreService();

  Widget getNotificationComponent(
      {int? type, required SVNotificationModel element}) {
    if (type == 1) {
      return SVLikeNotificationComponent(element: element);
    } else {
      return SVRequestNotificationComponent(element: element);
    }
  }

  @override
  void initState() {
    super.initState();

    _getNotifications();
    afterBuildCreated(() {
      setStatusBarColor(svGetScaffoldColor());
    });
  }

  final s = Translations();
  bool dataDownloaded = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: svGetScaffoldColor(),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: svGetScaffoldColor(),
        iconTheme: IconThemeData(color: context.iconColor),
        title: Text(s.notifications, style: boldTextStyle(size: 20)),
        elevation: 0,
        centerTitle: true,
      ),
      body: (dataDownloaded)
          ? (svNotificationList.isEmpty)
              ? noNotification()
              : GroupedListView<dynamic, String>(
                  stickyHeaderBackgroundColor: svGetScaffoldColor(),
                  elements: svNotificationList,
                  groupBy: (element) =>
                      (element as SVNotificationModel).groupDate!,
                  groupComparator: (value1, value2) => value1.compareTo(value2),
                  itemComparator: (item1, item2) =>
                      (item1 as SVNotificationModel)
                          .groupDate!
                          .compareTo((item2 as SVNotificationModel).groupDate!),
                  order: GroupedListOrder.DESC,
                  useStickyGroupSeparators: true,
                  groupSeparatorBuilder: (String value) => Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      value,
                      textAlign: TextAlign.start,
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: appStore.isDarkMode ? white : black),
                    ).paddingLeft(20),
                  ),
                  itemBuilder: (c, element) {
                    return ListTile(
                        title: getNotificationComponent(
                            type: (element as SVNotificationModel)
                                .notificationType,
                            element: element));
                  },
                )
          : Container(
              child: Align(
                child: CircularProgressIndicator(
                  color: Color(0xff2F65B9),
                ).paddingSymmetric(vertical: 180),
              ),
            ),
    );
  }

  void _getNotifications() async {
    notificationList =
        await firestoreService.getSavedNotifications(AuthService().getUid());
    final svModelList = await getNotifications(notificationList);
    setState(() {
      dataDownloaded = true;
      svNotificationList = svModelList;
    });
  }

  noNotification() {
    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            s.thereIsNoNotification,
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
