import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String commenterId;
  final int timeForMillis;
  final String content;
  final String commentId;
  const Comment(
      {required this.commenterId,
      required this.timeForMillis,
      required this.content,
      required this.commentId});

  Comment.fromJson(Map<String, Object?> json)
      : this(
            commenterId: json['commenterId']! as String,
            timeForMillis: json['timeForMillis']! as int,
            content: json['content']! as String,
            commentId: json['commentId']! as String);

  Map<String, Object?> toJson() {
    return {
      "commenterId": commenterId,
      "timeForMillis": timeForMillis,
      "content": content,
      "commentId": commentId
    };
  }

  factory Comment.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return Comment(
        commenterId: data?['commenterId'],
        timeForMillis: data?['timeForMillis'],
        content: data?['content'],
        commentId: data?['commentId']);
  }
}
