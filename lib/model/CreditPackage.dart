import 'dart:convert';

// ignore_for_file: public_member_api_docs, sort_constructors_first
class CreditPackage {
  final String id;
  final int price;
  final int creditCount;
  CreditPackage({
    required this.id,
    required this.price,
    required this.creditCount,
  });

  CreditPackage copyWith({
    String? id,
    int? price,
    int? creditCount,
  }) {
    return CreditPackage(
      id: id ?? this.id,
      price: price ?? this.price,
      creditCount: creditCount ?? this.creditCount,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'price': price,
      'creditCount': creditCount,
    };
  }

  factory CreditPackage.fromMap(Map<String, dynamic> map) {
    return CreditPackage(
      id: map['id'] as String,
      price: map['price'] as int,
      creditCount: map['creditCount'] as int,
    );
  }

  String toJson() => json.encode(toMap());

  factory CreditPackage.fromJson(String source) =>
      CreditPackage.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'CreditPackage(id: $id, price: $price, creditCount: $creditCount)';
  }

  @override
  bool operator ==(covariant CreditPackage other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.price == price &&
        other.creditCount == creditCount;
  }

  @override
  int get hashCode {
    return id.hashCode ^ price.hashCode ^ creditCount.hashCode;
  }
}
