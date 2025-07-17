class Notification {
  final String userId;
  final int type;
  final String? postId;
  final String id;
  final int timeForMillis;
  const Notification(
      {required this.userId,
      required this.type,
      required this.postId,
      required this.id,
      required this.timeForMillis});

  Notification.fromJson(Map<String, Object?> json)
      : this(
            userId: json['userId']! as String,
            type: json['type']! as int,
            postId: json['postId'] as String?,
            id: json['id'] as String,
            timeForMillis: json['timeForMillis'] as int);

  Map<String, Object?> toJson() {
    return {
      "userId": userId,
      "type": type,
      "postId": postId,
      "id": id,
      "timeForMillis": timeForMillis
    };
  }
}
