import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String from;
  final String to;
  final int timeForMillis;
  final String? messageText;
  final String? messageMediaUrl;
  final int type;
  final bool hasSeen;

  const Message(
      {required this.id,
      required this.from,
      required this.to,
      required this.timeForMillis,
      required this.messageText,
      required this.messageMediaUrl,
      required this.type,
      required this.hasSeen});

  Message.fromJson(Map<String, Object?> json)
      : this(
            id: json['id']! as String,
            from: json['from']! as String,
            to: json['to']! as String,
            timeForMillis: json['timeForMillis']! as int,
            messageText: json['messageText'] as String?,
            messageMediaUrl: json['messageMediaUrl'] as String?,
            type: json['type']! as int,
            hasSeen: json['hasSeen'] as bool);

  Map<String, Object?> toJson() {
    return {
      "id": id,
      "from": from,
      "to": to,
      "timeForMillis": timeForMillis,
      "messageText": messageText,
      "messageMediaUrl": messageMediaUrl,
      "type": type,
      "hasSeen": hasSeen
    };
  }

  factory Message.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return Message(
        id: data?['id'],
        from: data?['from'],
        to: data?['to'],
        timeForMillis: data?['timeForMillis'],
        messageText: data?['messageText'],
        messageMediaUrl: data?['messageMediaUrl'],
        type: data?['type'],
        hasSeen: data?['hasSeen']);
  }
}
