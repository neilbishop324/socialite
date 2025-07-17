class UserDetails {
  final String name;
  final String username;
  final String ppUrl;
  final String bgUrl;
  final String gender;
  final String birthDay;
  final String bio;
  final bool active;
  final UserLocation location;
  final String id;
  const UserDetails(
      {required this.name,
      required this.username,
      required this.ppUrl,
      required this.bgUrl,
      required this.gender,
      required this.birthDay,
      required this.bio,
      required this.active,
      required this.location,
      required this.id});

  UserDetails.fromJson(Map<String, Object?> json)
      : this(
          name: json['name']! as String,
          username: json['username']! as String,
          ppUrl: json['ppUrl']! as String,
          bgUrl: json['bgUrl']! as String,
          gender: json['gender']! as String,
          birthDay: json['birthDay']! as String,
          bio: json['bio']! as String,
          active: json['active']! as bool,
          location:
              UserLocation.fromJson(json['location']! as Map<String, Object?>),
          id: json['id']! as String,
        );

  Map<String, Object?> toJson() {
    return {
      "name": name,
      "username": username,
      "ppUrl": ppUrl,
      "bgUrl": bgUrl,
      "gender": gender,
      "birthDay": birthDay,
      "bio": bio,
      "active": active,
      "location": location.toJson(),
      "id": id,
    };
  }
}

class UserLocation {
  final String city;
  final String state;
  final String country;
  const UserLocation(
      {required this.city, required this.state, required this.country});

  UserLocation.fromJson(Map<String, Object?> json)
      : this(
            city: json['city']! as String,
            state: json['state']! as String,
            country: json['country']! as String);

  Map<String, Object?> toJson() {
    return {"city": city, "state": state, "country": country};
  }
}
