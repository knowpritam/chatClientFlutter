import 'dart:convert';

String postToJsonUser(PhoneNumbers data) {
  final dyn = data.toJson();
  String test = json.encode(dyn);
  return test;
}

class PhoneNumbers {
  List<Numbers> phone;

  PhoneNumbers({this.phone});

  factory PhoneNumbers.fromJson(Map<String, dynamic> json) {
    return PhoneNumbers(
      phone: json['phone'],
    );
  }

  Map<String, dynamic> toJson() => {
    "phone": phone,
  };
}

class Numbers{
  int number;

  Numbers({this.number});

  factory Numbers.fromJson(Map<String, dynamic> json) {
    return Numbers(
      number: json['number'],
    );
  }

  Map<String, dynamic> toJson() => {
    "number": number
  };
}