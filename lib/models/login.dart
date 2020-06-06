import 'dart:convert';

String postToJson(Login data) {
  final dyn = data.toJson();
  return json.encode(dyn);
}

class Login {
  final String username;
  final String password;

  Login({this.username, this.password});

  factory Login.fromJson(Map<String, dynamic> json) {
    return Login(
      username: json['username'],
      password: json['password'],
    );
  }

  Map<String, dynamic> toJson() => {
    "username": username,
    "password": password
  };
}