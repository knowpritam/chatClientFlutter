import 'dart:convert';

String postToJsonConversation(Conversation data) {
  final dyn = data.toJson();
  String test = json.encode(dyn);
  return test;
}

class Conversation {
  List<Participant> participants;

  Conversation({this.participants});

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      participants: json['participants'],
    );
  }

  Map<String, dynamic> toJson() => {
    "participants": participants,
  };
}

class Participant{
  String participant;

  Participant({this.participant});

  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      participant: json['participant'],
    );
  }

  Map<String, dynamic> toJson() => {
    "participant": participant
  };
}