import 'dart:convert';

ChatMessageModel chatMessageModelFromJson(String str) =>
    ChatMessageModel.fromJson(json.decode(str));

String chatMessageModelToJson(ChatMessageModel data) =>
    json.encode(data.toJson());

class ChatMessageModel {
  String chatId;
  String toId;
  String fromId;
  String fromName;
  String toName;
  String messageText;
  String chatType;
  String timeStamp;
  bool toUserOnlineStatus;

  ChatMessageModel({
    this.chatId,
    this.toId,
    this.fromId,
    this.fromName,
    this.toName,
    this.messageText,
    this.chatType,
    this.timeStamp,
    this.toUserOnlineStatus,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) =>
      ChatMessageModel(
        chatId: json["chatId"],
        toId: json["toId"],
        fromId: json["fromId"],
        fromName: json["fromName"],
        toName: json["toName"],
        messageText: json["messageText"],
        chatType: json["chat_type"],
        timeStamp: json["timeStamp"],
        toUserOnlineStatus: json['to_user_online_status'],
      );

  Map<String, dynamic> toJson() => {
    "chatId": chatId,
    "toId": toId,
    "fromId": fromId,
    "fromName": fromName,
    "toName": toName,
    "messageText": messageText,
    "chatType": chatType,
    "timeStamp": timeStamp,
  };

  Map<String, dynamic> toMap() {
    var map = new Map<String, dynamic>();
    map["chatId"] = chatId;
    map["toId"] = toId;
    map["fromId"] = fromId;
    map["fromName"] = fromName;
    map["toName"] = toName;
    map["messageText"] = messageText;
    map["chatType"] = chatType;
    map["timeStamp"] = timeStamp;
    return map;
  }
}
