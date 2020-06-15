import 'dart:convert';

ValidUser postFromJsonUsers(String str) {
  final jsonData = json.decode(str);
  ValidUser lr =  ValidUser.fromJson(jsonData);
  return lr;
}

class ValidUser {
  final String userId;
  final String firstname;
  final String lastname;
  final bool online;
  final String username;
  final String phone;

  ValidUser({this.userId, this.firstname, this.lastname,  this.online, this.username, this.phone});

  factory ValidUser.fromJson(Map<String, dynamic> json) {
    return ValidUser(
      userId: json['_id'],
      firstname: json['firstname'],
      lastname: json['lastname'],
      online: json['online'],
      username: json['username'],
      phone: json['phone'],
    );
  }
  Map<String, dynamic> toJson() => {
    "_id": userId,
    "firstname": firstname,
    "lastname": lastname,
    "online": online,
    "username": username,
  };
  ValidUser postFromJson(String str) {
    final jsonData = json.decode(str);
    return ValidUser.fromJson(jsonData);
  }
}