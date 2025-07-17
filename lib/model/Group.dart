class Group {
  final String name;
  final String ppUrl;
  final String bgUrl;
  final String description;
  final String id;
  final String adminId;
  const Group(
      {required this.name,
      required this.ppUrl,
      required this.bgUrl,
      required this.description,
      required this.id,
      required this.adminId});

  Group.fromJson(Map<String, Object?> json)
      : this(
          name: json['name']! as String,
          ppUrl: json['ppUrl']! as String,
          bgUrl: json['bgUrl']! as String,
          description: json['description']! as String,
          id: json['id']! as String,
          adminId: json['adminId']! as String,
        );

  Map<String, Object?> toJson() {
    return {
      "name": name,
      "ppUrl": ppUrl,
      "bgUrl": bgUrl,
      "description": description,
      "id": id,
      "adminId": adminId
    };
  }
}
