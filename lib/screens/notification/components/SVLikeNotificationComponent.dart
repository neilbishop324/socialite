import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:prokit_socialv/models/SVNotificationModel.dart';
import 'package:prokit_socialv/utils/SVCommon.dart';
import 'package:prokit_socialv/utils/SVConstants.dart';
import 'package:prokit_socialv/utils/Translations.dart';

class SVLikeNotificationComponent extends StatelessWidget {
  final SVNotificationModel element;

  SVLikeNotificationComponent({required this.element});
  final s = Translations();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Image.network(element.profileImage ?? SVConstants.imageLinkDefault,
                    height: 40, width: 40, fit: BoxFit.cover)
                .cornerRadiusWithClipRRect(8),
            8.width,
            Column(
              children: [
                Row(
                  children: [
                    Text(element.name.validate(),
                        style: boldTextStyle(size: 14)),
                    2.width,
                    Text(' ' + s.likedYourPost,
                        style: secondaryTextStyle(color: svGetBodyColor())),
                  ],
                  mainAxisSize: MainAxisSize.min,
                ),
                6.height,
                Text(
                    '${element.time.validate()}${(element.time == s.recently ? "" : " " + s.ago)}',
                    style:
                        secondaryTextStyle(color: svGetBodyColor(), size: 12)),
              ],
              crossAxisAlignment: CrossAxisAlignment.start,
            ),
          ],
        ),
        Image.network(element.postImage ?? SVConstants.backgroundLinkDefault,
                height: 48, width: 48, fit: BoxFit.cover)
            .cornerRadiusWithClipRRect(4),
      ],
    ).paddingAll(16);
  }
}
