import 'dart:convert';

ChatMessageModel chatMessageModelFromJson(String str) =>
    ChatMessageModel.fromJson(json.decode(str));

String chatMessageModelToJson(ChatMessageModel data) =>
    json.encode(data.toJson());

class ChatMessageModel {
  String chatId;
  String to;
  String from;
  String fromName;
  String toName;
  String message;
  String chatType;
  bool toUserOnlineStatus;

  ChatMessageModel({
    this.chatId,
    this.to,
    this.from,
    this.fromName,
    this.toName,
    this.message,
    this.chatType,
    this.toUserOnlineStatus,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) =>
      ChatMessageModel(
        chatId: json["chat_id"],
        to: json["to"],
        from: json["from"],
        fromName: json["fromName"],
        toName: json["toName"],
        message: json["message"],
        chatType: json["chat_type"],
        toUserOnlineStatus: json['to_user_online_status'],
      );

  Map<String, dynamic> toJson() => {
    "chat_id": chatId,
    "to": to,
    "from": from,
    "fromName": fromName,
    "toName": toName,
    "message": message,
    "chat_type": chatType,
  };
}
