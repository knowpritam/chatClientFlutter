import 'dart:convert';

LoginResponse postFromJson(String str) {
  final jsonData = json.decode(str);
  LoginResponse lr =  LoginResponse.fromJson(jsonData);
  return lr;
}

class LoginResponse {
  final String userId;
  final String token;
  final String firstname;
  final String lastname;
  final String phone;
  final bool isSuccess;
  String notifToken;

  LoginResponse({this.userId, this.token, this.firstname, this.lastname,this.phone, this.isSuccess, this.notifToken});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      userId: json['_id'],
      token: json['token'],
      firstname: json['firstname'],
      lastname: json['lastname'],
      phone: json['phone'],
      isSuccess: json['success'],
      notifToken: json['notifToken'],
    );
  }
  Map<String, dynamic> toJson() => {
    "userId": userId,
    "notifToken" : notifToken,
  };
  LoginResponse postFromJson(String str) {
    final jsonData = json.decode(str);
    return LoginResponse.fromJson(jsonData);
  }
}