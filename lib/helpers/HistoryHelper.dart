import 'package:flutterapp/globals.dart' as globals;
import 'package:flutterapp/models/valid_users.dart';
import 'package:flutterapp/services/services.dart';
import 'package:flutterapp/models/message.dart';
import 'package:flutterapp/helpers/DBHelper.dart';
import 'dart:convert';

Map historyUsersMap = new Map();
List<ChatMessageModel> chatList = new List();
UsersHistory user;

// Gets the chats(when user was offline) for this user from server and notifies the user
getHistory(){
  String url = globals.url+'/messages/messagesForUser/'+globals.globalLoginResponse.userId;
  Iterable list;
  getHistoryChat(url).then((response) => {
    print(response.body),
    // If response is not blank i.e. at least one chat message is there on server for this user
    if(response.statusCode == 200 && response.body != '[]'){
      deleteHistoryChat(url), // deleting the chat from server once received by client
      list = json.decode(response.body),
      chatList = list.map((model) => ChatMessageModel.fromJson(model)).toList(),
      for(int i = chatList.length-1; i>=0;i--){
        if(historyUsersMap.containsKey(chatList[i].fromId)){
          user = historyUsersMap[chatList[i].fromId],
          user.numOfMessages+=1, // updating new numberOfMessages
          user.lastMessage = chatList[i].messageText, // updating new Last message
          historyUsersMap.update(chatList[i].fromId, (value) => user),
        }
        else{
          user = UsersHistory(lastMessage: chatList[i].messageText, numOfMessages: 1),
          historyUsersMap.putIfAbsent(chatList[i].fromId, () => user),
        }
      },
      updateHistoryAndGetUsers(chatList, historyUsersMap),
    }
  });
}

// ************************************ DATABASE HELPER METHODS START *******************************

// Update older messages to the chat and from user so that it shows up on chat tab for current user
updateHistoryAndGetUsers(List<ChatMessageModel> chats, Map historyUsersMap) async{
  var db = new DatabaseHelper();
  await db.saveHistoryChat(chats);
  int len = chats.length;
  if(len>0){
    ValidUser user = ValidUser(userId: chats[0].fromId, lastMessage: chats[0].fromName +": "+chats[0].messageText);
    await db.updateUsersAndSetMessageNumberCount(historyUsersMap);
    //getUsersForConversation();
  }
}


