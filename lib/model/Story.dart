import 'package:cloud_firestore/cloud_firestore.dart';

class Story {
  final String userId;
  final int timeForMillis;
  final String? imageLink;
  final String id;
  const Story({
    required this.userId,
    required this.timeForMillis,
    required this.imageLink,
    required this.id,
  });

  Story.fromJson(Map<String, Object?> json)
      : this(
            userId: json['userId']! as String,
            timeForMillis: json['timeForMillis']! as int,
            imageLink: json['imageLink'] as String?,
            id: json['id']! as String);

  Map<String, Object?> toJson() {
    return {
      "userId": userId,
      "timeForMillis": timeForMillis,
      "imageLink": imageLink,
      "id": id
    };
  }

  factory Story.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return Story(
        userId: data?['userId'],
        timeForMillis: data?['timeForMillis'],
        imageLink: data?['imageLink'],
        id: data?['id']);
  }
}
