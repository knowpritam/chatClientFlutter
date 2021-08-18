import 'dart:convert';

ChatMessageModel chatMessageModelFromJson(String str) =>
    ChatMessageModel.fromJson(json.decode(str));

String chatMessageModelToJson(ChatMessageModel data) =>
    json.encode(data.toJson());

class ChatMessageModel {
  int messageId;
  String chatId;
  String toId;
  String fromId;
  String fromName;
  String toName;
  String messageText;
  String chatType;
  String status;
  String timeStamp;
  String serverMessageId;
  bool toUserOnlineStatus;

  ChatMessageModel({
    this.messageId,
    this.chatId,
    this.toId,
    this.fromId,
    this.fromName,
    this.toName,
    this.messageText,
    this.chatType,
    this.status,
    this.timeStamp,
    this.serverMessageId,
    this.toUserOnlineStatus,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) =>
      ChatMessageModel(
        messageId: json["messageId"],
        chatId: json["chatId"],
        toId: json["toId"],
        fromId: json["fromId"],
        fromName: json["fromName"],
        toName: json["toName"],
        messageText: json["messageText"],
        chatType: json["chat_type"],
        status: json["status"],
        timeStamp: json["timeStamp"],
        serverMessageId: json["_id"],
        toUserOnlineStatus: json['to_user_online_status'],
      );

  Map<String, dynamic> toJson() => {
    "messageId": messageId,
    "chatId": chatId,
    "toId": toId,
    "fromId": fromId,
    "fromName": fromName,
    "toName": toName,
    "messageText": messageText,
    "chatType": chatType,
    "status": status,
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
    map["status"] = status;
    map["timeStamp"] = timeStamp;
    map["serverMessageId"] = serverMessageId;
    return map;
  }

  Map<String, dynamic> toStatusMap(){
    var map = new Map<String, dynamic>();
    map["status"] = "delivered";
    return map;
  }
}
