import 'dart:convert';


String postToJsonSignup(SignupModel data) {
  final dyn = data.toJson();
  String postPayload = json.encode(dyn);
  return postPayload;
}
class SignupModel {
  SignupModel({
    this.username,
    this.password,
    this.firstname,
    this.lastname,
    this.phone,
  });

  String username;
  String password;
  String firstname;
  String lastname;
  String phone;

  factory SignupModel.fromJson(Map<String, dynamic> json) => SignupModel(
    username: json["username"],
    password: json["password"],
    firstname: json["firstname"],
    lastname: json["lastname"],
    phone: json["phone"],
  );

  Map<String, dynamic> toJson() => {
    "username": username,
    "password": password,
    "firstname": firstname,
    "lastname": lastname,
    "phone": phone,
  };
}
