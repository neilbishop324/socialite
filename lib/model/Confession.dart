// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class Confession {
  final String title;
  final String description;
  final bool isAnonym;
  final int likeCount;
  final int giftCount;
  final int commentCount;
  final String id;
  final String userId;
  final timestamp;

  Confession(
    this.title,
    this.description,
    this.isAnonym,
    this.likeCount,
    this.giftCount,
    this.commentCount,
    this.id,
    this.userId,
    this.timestamp,
  );

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'title': title,
      'description': description,
      'isAnonym': isAnonym,
      'likeCount': likeCount,
      'giftCount': giftCount,
      'commentCount': commentCount,
      'id': id,
      'userId': userId,
      'timestamp': timestamp,
    };
  }

  factory Confession.fromMap(Map<String, dynamic> map) {
    return Confession(
        map['title'] as String,
        map['description'] as String,
        map['isAnonym'] as bool,
        map['likeCount'] as int,
        map['giftCount'] as int,
        map['commentCount'] as int,
        map['id'] as String,
        map['userId'] as String,
        map['timestamp']);
  }
}
