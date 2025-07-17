import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:prokit_socialv/model/Notification.dart';
import 'package:prokit_socialv/models/SVPostModel.dart';
import 'package:prokit_socialv/service/firestore_service.dart';
import 'package:prokit_socialv/utils/SVConstants.dart';
import 'package:prokit_socialv/utils/Translations.dart';

import '../model/SVPost.dart';

class SVNotificationModel {
  String? name;
  String? secondName;
  String? profileImage;
  String? time;
  int? notificationType;
  String? postImage;
  String? groupDate;

  SVNotificationModel(
      {this.name,
      this.profileImage,
      this.time,
      this.notificationType,
      this.postImage,
      this.secondName,
      this.groupDate});
}

Future<List<SVNotificationModel>> getNotifications(
    List<Notification> notifications) async {
  final list = <SVNotificationModel>[];
  for (Notification notification in notifications) {
    final postUser = await FirestoreService().getUser(notification.userId);
    String? postImageUrl;
    if (notification.postId != null) {
      final post = await getPost(notification.postId!);
      postImageUrl = post?.imageLink;
    }
    String? groupDate = getGroupDate(notification.timeForMillis);
    if (postUser != null) {
      list.add(SVNotificationModel(
          name: postUser.name,
          profileImage: postUser.ppUrl,
          time: getTimeDifference(notification.timeForMillis),
          notificationType: notification.type,
          postImage: postImageUrl,
          groupDate: groupDate));
    }
  }
  return list;
}

String? getGroupDate(int timeForMillis) {
  final s = Translations();
  final firstDate = DateTime.fromMillisecondsSinceEpoch(timeForMillis);
  final secondDate = DateTime.fromMillisecondsSinceEpoch(
      DateTime.now().millisecondsSinceEpoch);
  final difference = secondDate.difference(firstDate).abs();
  if (difference.inDays <= 1) {
    return s.today;
  } else if (difference.inDays <= 7) {
    return s.thisWeek;
  } else if (difference.inDays <= 30) {
    return s.thisMonth;
  }
  return s.earlier;
}

Future<Post?> getPost(String postId) async {
  final _firestore = FirebaseFirestore.instance;
  final postSnapshot = await _firestore
      .collection(CollectionPath().posts)
      .doc(postId)
      .withConverter<Post>(
        fromFirestore: (snapshot, _) => Post.fromJson(snapshot.data()!),
        toFirestore: (post, _) => post.toJson(),
      )
      .get();

  return postSnapshot.data();
}
