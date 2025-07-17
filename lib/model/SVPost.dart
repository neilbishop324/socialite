import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String posterName;
  final int timeForMillis;
  final String? imageLink;
  final String? description;
  final bool isForStory;
  final String postId;
  final String postContextId;
  const Post(
      {required this.posterName,
      required this.timeForMillis,
      required this.imageLink,
      required this.description,
      required this.isForStory,
      required this.postId,
      required this.postContextId});

  Post.fromJson(Map<String, Object?> json)
      : this(
            posterName: json['posterName']! as String,
            timeForMillis: json['timeForMillis']! as int,
            imageLink: json['imageLink'] as String?,
            description: json['description'] as String?,
            isForStory: json['isForStory']! as bool,
            postId: json['postId']! as String,
            postContextId: json['postContextId'] as String);

  Map<String, Object?> toJson() {
    return {
      "posterName": posterName,
      "timeForMillis": timeForMillis,
      "imageLink": imageLink,
      "description": description,
      "isForStory": isForStory,
      "postId": postId,
      "postContextId": postContextId
    };
  }

  factory Post.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return Post(
        posterName: data?['posterName'],
        timeForMillis: data?['timeForMillis'],
        imageLink: data?['imageLink'],
        description: data?['description'],
        isForStory: data?['isForStory'],
        postId: data?['postId'],
        postContextId: data?['postContextId']);
  }
}
