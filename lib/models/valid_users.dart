import 'dart:collection';
import 'dart:convert';

ValidUser postFromJsonUsers(String str) {
  final jsonData = json.decode(str);
  ValidUser lr =  ValidUser.fromJson(jsonData);
  return lr;
}

class ValidUser{
  final String userId;
  final String firstname;
  final String lastname;
  final String username;
  final String phone;
  int numOfMessages;
  String lastMessage;

  ValidUser({this.userId, this.firstname, this.lastname, this.username, this.phone, this.numOfMessages, this.lastMessage});

  factory ValidUser.fromJson(Map<String, dynamic> json) {
    return ValidUser(
      userId: json['_id'],
      firstname: json['firstname'],
      lastname: json['lastname'],
      username: json['username'],
      phone: json['phone'],
      numOfMessages: json['numOfMessages'],
      lastMessage: json['lastMessage'],
    );
  }
  Map<String, dynamic> toJson() => {
    "_id": userId,
    "firstname": firstname,
    "lastname": lastname,
    "username": username,
    "numOfMessages": numOfMessages,
    "lastMessage": lastMessage,
  };
  ValidUser postFromJson(String str) {
    final jsonData = json.decode(str);
    return ValidUser.fromJson(jsonData);
  }
  Map<String, dynamic> toMap() {
    var map = new Map<String, dynamic>();
    map["userId"] = userId;
    map["firstname"] = firstname;
    map["lastname"] = lastname;
    map["username"] = username;
    map["phone"] = phone;
    map["numOfMessages"] = numOfMessages;
    map["lastMessage"] = lastMessage;
    return map;
  }

  Map<String, dynamic> toUpdateMap() {
    var map = new Map<String, dynamic>();
    map["numOfMessages"] = numOfMessages;
    map["lastMessage"] = lastMessage;
    return map;
  }

  Map<String, dynamic> toUpdateNumMessagesMap() {
    var map = new Map<String, dynamic>();
    map["numOfMessages"] = numOfMessages;
    return map;
  }
}