import 'dart:convert';

// ignore_for_file: public_member_api_docs, sort_constructors_first
class VipPackage {
  final String id;
  final String name;
  final int period;
  final String periodType;
  final String iconLink;
  final int price;
  final int status;
  VipPackage({
    required this.id,
    required this.name,
    required this.period,
    required this.periodType,
    required this.iconLink,
    required this.price,
    required this.status,
  });

  VipPackage copyWith({
    String? id,
    String? name,
    int? period,
    String? periodType,
    String? iconLink,
    int? price,
    int? status,
  }) {
    return VipPackage(
      id: id ?? this.id,
      name: name ?? this.name,
      period: period ?? this.period,
      periodType: periodType ?? this.periodType,
      iconLink: iconLink ?? this.iconLink,
      price: price ?? this.price,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'period': period,
      'periodType': periodType,
      'iconLink': iconLink,
      'price': price,
      'status': status,
    };
  }

  factory VipPackage.fromMap(Map<String, dynamic> map) {
    return VipPackage(
      id: map['id'] as String,
      name: map['name'] as String,
      period: map['period'] as int,
      periodType: map['periodType'] as String,
      iconLink: map['iconLink'] as String,
      price: map['price'] as int,
      status: map['status'] as int,
    );
  }

  String toJson() => json.encode(toMap());

  factory VipPackage.fromJson(String source) =>
      VipPackage.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'VipPackage(id: $id, name: $name, period: $period, periodType: $periodType, iconLink: $iconLink, price: $price, status: $status)';
  }

  @override
  bool operator ==(covariant VipPackage other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.name == name &&
        other.period == period &&
        other.periodType == periodType &&
        other.iconLink == iconLink &&
        other.price == price &&
        other.status == status;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        period.hashCode ^
        periodType.hashCode ^
        iconLink.hashCode ^
        price.hashCode ^
        status.hashCode;
  }
}
