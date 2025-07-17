import 'dart:convert';

// ignore_for_file: public_member_api_docs, sort_constructors_first
class Gift {
  final String id;
  final String name;
  final String mediaFileLink;
  final int creditCount;
  Gift({
    required this.id,
    required this.name,
    required this.mediaFileLink,
    required this.creditCount,
  });

  Gift copyWith({
    String? id,
    String? name,
    String? mediaFileLink,
    int? creditCount,
  }) {
    return Gift(
      id: id ?? this.id,
      name: name ?? this.name,
      mediaFileLink: mediaFileLink ?? this.mediaFileLink,
      creditCount: creditCount ?? this.creditCount,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'mediaFileLink': mediaFileLink,
      'creditCount': creditCount,
    };
  }

  factory Gift.fromMap(Map<String, dynamic> map) {
    return Gift(
      id: map['id'] as String,
      name: map['name'] as String,
      mediaFileLink: map['mediaFileLink'] as String,
      creditCount: map['creditCount'] as int,
    );
  }

  String toJson() => json.encode(toMap());

  factory Gift.fromJson(String source) =>
      Gift.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Gift(id: $id, name: $name, mediaFileLink: $mediaFileLink, creditCount: $creditCount)';
  }

  @override
  bool operator ==(covariant Gift other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.name == name &&
        other.mediaFileLink == mediaFileLink &&
        other.creditCount == creditCount;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        mediaFileLink.hashCode ^
        creditCount.hashCode;
  }
}
