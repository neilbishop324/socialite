import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:prokit_socialv/model/SVUser.dart';
import 'package:prokit_socialv/service/auth.dart';
import 'package:prokit_socialv/service/firestore_service.dart';
import 'package:prokit_socialv/utils/Translations.dart';

import '../model/SVPost.dart';
import '../utils/SVConstants.dart';

class SVPostModel {
  String? name;
  String? profileImage;
  String? postImage;
  String? time;
  String? description;
  int? commentCount;
  bool? like;
  List<String> likeList = [];
  bool? postSaved;
  bool? fromYF;

  SVPostModel(
      {this.name,
      this.profileImage,
      this.postImage,
      this.time,
      this.description,
      this.commentCount,
      this.like,
      this.postSaved,
      this.fromYF,
      required this.likeList});
}

Future<SVPostModel> getPost(Post post) async {
  final user = await FirestoreService().getUser(post.posterName);
  final commentsSize = await FirestoreService().getCollSize(
      "${CollectionPath().posts}/${post.postId}/${CollectionPath().comments}");
  final likeSS = await FirebaseFirestore.instance
      .collection(
          "${CollectionPath().posts}/${post.postId}/${CollectionPath().likes}")
      .get();
  final ids = likeSS.docs.map((doc) => doc["id"] as String).toList();
  late bool isfromYF;
  late bool savedPost;
  late bool userLiked;
  if (AuthService().getUid() == null) {
    userLiked = false;
    savedPost = false;
    isfromYF = false;
  } else {
    userLiked = await FirestoreService().userLiked(
        CollectionPath().posts + "/" + post.postId, AuthService().getUid()!);
    final savedPostSS = await FirebaseFirestore.instance
        .collection(CollectionPath().users)
        .doc(AuthService().getUid())
        .collection(CollectionPath().saved)
        .doc(post.postId)
        .get();
    savedPost = savedPostSS.exists;
    isfromYF = await fromYourFollowings(post.posterName, post.postContextId);
  }
  return (SVPostModel(
      name: user?.name,
      profileImage: user?.ppUrl,
      postImage: post.imageLink,
      time: getTimeDifference(post.timeForMillis, shortly: true),
      description: post.description,
      commentCount: commentsSize,
      likeList: ids,
      like: userLiked,
      postSaved: savedPost,
      fromYF: isfromYF));
}

String getTimeDifference(int fromMillis, {bool? shortly}) {
  final s = Translations();
  final firstDate = DateTime.fromMillisecondsSinceEpoch(fromMillis);
  final secondDate = DateTime.fromMillisecondsSinceEpoch(
      DateTime.now().millisecondsSinceEpoch);
  final difference = secondDate.difference(firstDate).abs();
  if (difference.inMinutes < 1) {
    return (shortly == true) ? "${difference.inSeconds}s" : s.recently;
  } else if (difference.inMinutes < 60) {
    return (shortly == true)
        ? "${difference.inMinutes}" + s.sMinute
        : "${difference.inMinutes} " + s.minutes;
  } else if (difference.inMinutes < 1440) {
    return (shortly == true)
        ? "${difference.inHours}" + s.sHour
        : "${difference.inHours} " + s.hours;
  } else {
    return (shortly == true)
        ? "${difference.inDays}" + s.sDay
        : "${difference.inDays} " + s.days;
  }
}

int getDayDifference(int fromMillis) {
  final firstDate = DateTime.fromMillisecondsSinceEpoch(fromMillis);
  final secondDate = DateTime.fromMillisecondsSinceEpoch(
      DateTime.now().millisecondsSinceEpoch);
  final difference = secondDate.difference(firstDate).abs();
  return difference.inDays;
}

Future<bool> fromYourFollowings(String posterId, String postContext) async {
  final ids =
      await FirestoreService().getUserFollowings(AuthService().getUid()!);
  if (ids.contains(posterId)) {
    return true;
  }
  if (posterId == AuthService().getUid()) {
    return true;
  }
  final groups = await FirestoreService().getGroups();
  final participatedGroups = await FirestoreService()
      .getParticipatedGroups(groups, AuthService().getUid()!);
  if (participatedGroups.map((e) => e.id).toList().contains(postContext)) {
    return true;
  }
  return false;
}
