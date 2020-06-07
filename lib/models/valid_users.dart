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

  ValidUser({this.userId, this.firstname, this.lastname,  this.online, this.username});

  factory ValidUser.fromJson(Map<String, dynamic> json) {
    return ValidUser(
      userId: json['_id'],
      firstname: json['firstname'],
      lastname: json['lastname'],
      online: json['online'],
      username: json['username'],
    );
  }

  ValidUser postFromJson(String str) {
    final jsonData = json.decode(str);
    return ValidUser.fromJson(jsonData);
  }
}