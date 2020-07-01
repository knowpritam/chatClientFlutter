import 'package:flutterapp/globals.dart' as globals;
import 'package:flutterapp/models/valid_users.dart';
import 'package:flutterapp/services/services.dart';
import 'package:flutterapp/models/message.dart';
import 'package:flutterapp/helpers/DBHelper.dart';
import 'dart:convert';

Map<String, UsersHistory> historyUsersMap = new Map();  // Stores lastMessage and numOfMessages against userId(from)
List<ChatMessageModel> chatList = new List();
UsersHistory user;

// Gets the chats(when user was offline) for this user from server and notifies the user
getHistoryAndUpdateUsers(String response) async {
  Iterable list = json.decode(response);
  chatList = list.map((model) => ChatMessageModel.fromJson(model)).toList();
  for(int i = chatList.length-1; i>=0;i--){
    if(historyUsersMap.containsKey(chatList[i].fromId)){
      UsersHistory user = historyUsersMap[chatList[i].fromId];
      user.numOfMessages+=1; // updating new numberOfMessages
      user.lastMessage = chatList[i].fromName+' : '+chatList[i].messageText; // updating new Last message
      historyUsersMap.update(chatList[i].fromId, (value) => user);
    }
    else{
      UsersHistory user = UsersHistory(lastMessage: chatList[i].messageText, numOfMessages: 1);
      historyUsersMap.putIfAbsent(chatList[i].fromId, () => user);
    }
  }
  await updateHistoryAndGetUsers(chatList, historyUsersMap);
  int a = 10;
}
// Update older messages to the chat and from user so that it shows up on chat tab for current user
updateHistoryAndGetUsers(List<ChatMessageModel> chats, Map historyUsersMap) async{
  var db = new DatabaseHelper();
  await db.saveHistoryChat(chats);
  int len = chats.length;
  if(len>0){
    ValidUser user = ValidUser(userId: chats[0].fromId, lastMessage: chats[0].fromName +": "+chats[0].messageText);
    await db.updateUsersAndSetMessageNumberCount(historyUsersMap);
    historyUsersMap.clear();
  }
}
