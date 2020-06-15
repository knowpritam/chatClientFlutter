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
  final bool isSuccess;

  LoginResponse({this.userId, this.token, this.firstname, this.lastname, this.isSuccess});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      userId: json['_id'],
      token: json['token'],
      firstname: json['firstname'],
      lastname: json['lastname'],

      isSuccess: json['success'],
    );
  }
  Map<String, dynamic> toJson() => {
    "userId": userId,
  };
  LoginResponse postFromJson(String str) {
    final jsonData = json.decode(str);
    return LoginResponse.fromJson(jsonData);
  }
}