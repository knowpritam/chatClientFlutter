import 'dart:convert';

LoginResponse postFromJson(String str) {
  final jsonData = json.decode(str);
  LoginResponse lr =  LoginResponse.fromJson(jsonData);
  return lr;
}

class LoginResponse {
  final String userId;
  final String token;
  final String firstName;
  final String lastName;
  final bool isSuccess;

  LoginResponse({this.userId, this.token, this.firstName, this.lastName, this.isSuccess});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      userId: json['_id'],
      token: json['token'],
      isSuccess: json['success'],
    );
  }

  LoginResponse postFromJson(String str) {
    final jsonData = json.decode(str);
    return LoginResponse.fromJson(jsonData);
  }
}