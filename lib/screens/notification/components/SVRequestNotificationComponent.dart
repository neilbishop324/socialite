import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:prokit_socialv/models/SVNotificationModel.dart';
import 'package:prokit_socialv/utils/SVColors.dart';
import 'package:prokit_socialv/utils/SVCommon.dart';
import 'package:prokit_socialv/utils/SVConstants.dart';
import 'package:prokit_socialv/utils/Translations.dart';

class SVRequestNotificationComponent extends StatelessWidget {
  final SVNotificationModel element;

  SVRequestNotificationComponent({required this.element});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.network(element.profileImage ?? SVConstants.imageLinkDefault,
                height: 40, width: 40, fit: BoxFit.cover)
            .cornerRadiusWithClipRRect(8),
        8.width,
        Column(
          children: [
            Row(
              children: [
                Text(element.name.validate(), style: boldTextStyle(size: 14)),
                2.width,
                Text(' ' + Translations().followedYou,
                    style: secondaryTextStyle(color: svGetBodyColor())),
              ],
              mainAxisSize: MainAxisSize.min,
            ),
            6.height,
            Text('${element.time.validate()} ' + Translations().ago,
                style: secondaryTextStyle(color: svGetBodyColor(), size: 12)),
          ],
          crossAxisAlignment: CrossAxisAlignment.start,
        ),
      ],
    ).paddingAll(16);
  }
}
