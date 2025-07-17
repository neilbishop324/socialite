import 'package:prokit_socialv/model/SVComment.dart';
import 'package:prokit_socialv/utils/SVConstants.dart';
import 'package:prokit_socialv/utils/Translations.dart';

import '../service/auth.dart';
import '../service/firestore_service.dart';
import 'SVPostModel.dart';

class SVCommentModel {
  String name;
  String? profileImage;
  String? time;
  String comment;
  int? likeCount;
  bool? isCommentReply;
  bool? like;

  SVCommentModel(
      {required this.name,
      this.profileImage,
      this.time,
      required this.comment,
      this.likeCount,
      this.isCommentReply,
      this.like});
}

Future<List<SVCommentModel>> getComments(
    List<Comment> comments, String postId) async {
  List<SVCommentModel> list = [];

  for (Comment comment in comments) {
    final user = await FirestoreService().getUser(comment.commenterId);
    final commentRef =
        "${CollectionPath().posts}/$postId/${CollectionPath().comments}/${comment.commentId}";
    final likeCount = await FirestoreService()
        .getCollSize("$commentRef/${CollectionPath().likes}");

    late bool userLiked;
    if (AuthService().getUid() == null) {
      userLiked = false;
    } else {
      userLiked = await FirestoreService()
          .userLiked(commentRef, AuthService().getUid()!);
    }

    String username =
        (user == null) ? Translations().deletedAccount : user.name;
    String userPpUrl =
        (user == null) ? SVConstants.imageLinkDefault : user.ppUrl;

    list.add(SVCommentModel(
        name: username,
        profileImage: userPpUrl,
        time: getTimeDifference(comment.timeForMillis, shortly: true),
        comment: comment.content,
        likeCount: likeCount,
        isCommentReply: false,
        like: userLiked));
  }

  return list;
}

Future<List<SVCommentModel>> getConfessionComments(
    List<Comment> comments, String confessionId) async {
  List<SVCommentModel> list = [];

  for (Comment comment in comments) {
    final user = await FirestoreService().getUser(comment.commenterId);
    final commentRef =
        "${CollectionPath().confessions}/$confessionId/${CollectionPath().comments}/${comment.commentId}";
    final likeCount = await FirestoreService()
        .getCollSize("$commentRef/${CollectionPath().likes}");

    late bool userLiked;
    if (AuthService().getUid() == null) {
      userLiked = false;
    } else {
      userLiked = await FirestoreService()
          .userLiked(commentRef, AuthService().getUid()!);
    }

    String username =
        (user == null) ? Translations().deletedAccount : user.name;
    String userPpUrl =
        (user == null) ? SVConstants.imageLinkDefault : user.ppUrl;

    list.add(SVCommentModel(
        name: username,
        profileImage: userPpUrl,
        time: getTimeDifference(comment.timeForMillis, shortly: true),
        comment: comment.content,
        likeCount: likeCount,
        isCommentReply: false,
        like: userLiked));
  }

  return list;
}
