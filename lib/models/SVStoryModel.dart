import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:prokit_socialv/models/SVPostModel.dart';
import 'package:prokit_socialv/service/auth.dart';
import 'package:prokit_socialv/service/firestore_service.dart';
import 'package:prokit_socialv/utils/SVConstants.dart';

import '../model/Story.dart';

class SVStoryModel {
  String? name;
  String? profileImage;
  String storyImage;
  String? time;
  bool? like;
  String id;
  int likeSize;

  SVStoryModel(
      {this.name,
      this.profileImage,
      required this.storyImage,
      this.time,
      this.like,
      required this.id,
      required this.likeSize});
}

Future<List<SVStoryModel>> getStories(List<Story> stories) async {
  List<SVStoryModel> list = [];

  for (Story story in stories) {
    final storyUser = await FirestoreService().getUser(story.userId);
    final userLikedSS = await FirebaseFirestore.instance
        .collection(CollectionPath().stories)
        .doc(story.userId)
        .collection(CollectionPath().likes)
        .doc(AuthService().getUid())
        .get();
    final likedSize = await FirestoreService().getCollSize(
        "${CollectionPath().stories}/${story.userId}/${CollectionPath().likes}");
    final userLiked = userLikedSS.exists;
    list.add(SVStoryModel(
        id: story.userId,
        name: storyUser?.name,
        profileImage: storyUser?.ppUrl,
        storyImage: story.imageLink!,
        time: getTimeDifference(story.timeForMillis),
        like: userLiked,
        likeSize: likedSize));
  }

  return list;
}
