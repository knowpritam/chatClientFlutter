import 'dart:async';
import 'dart:io' as io;

import 'package:flutterapp/models/message.dart';
import 'package:flutterapp/models/valid_users.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutterapp/globals.dart' as globals;

class DatabaseHelper {
  static final DatabaseHelper _instance = new DatabaseHelper.internal();
  factory DatabaseHelper() => _instance;
  static Database _db;

  Future<Database> get db async {
    if (_db != null) return _db;
    _db = await initDb();
    return _db;
  }

  DatabaseHelper.internal();

  initDb() async {
    io.Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "main.db");
    var theDb = await openDatabase(path, version: 1, onCreate: _onCreate);
    return theDb;
  }

  void _onCreate(Database db, int version) async {
    // When creating the db, create the table
    print('dropped');
    await db.execute(
        "CREATE TABLE IF NOT EXISTS chat_messages(messageId INTEGER PRIMARY KEY AUTOINCREMENT, chatId TEXT,toId TEXT, fromId TEXT, fromName TEXT, toName TEXT, messageText TEXT, chatType TEXT, status TEXT, timeStamp TEXT, serverMessageId TEXT, created_at DATETIME DEFAULT CURRENT_TIMESTAMP);");
    await db.execute(
        "CREATE TABLE IF NOT EXISTS valid_users(userId TEXT,firstname TEXT, lastname TEXT, username TEXT, phone TEXT, numOfMessages INTEGER, lastMessage TEXT, created_at DATETIME DEFAULT CURRENT_TIMESTAMP,  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP);");

  }

  // save list of chat messages retrieved from server
      Future saveHistoryChat(List<ChatMessageModel> chats) async {
        for (int i = chats.length-1; i >=0; i--) {
          saveChat(chats[i]);
        }
      }

      // Save chat to db
      Future<int> saveChat(ChatMessageModel chat) async {
        var dbClient = await db;
        int res = -1;
        if(chat.serverMessageId!=null){
          List<Map> messagesWithServerMessageIdList = await dbClient.rawQuery('SELECT * FROM chat_messages where serverMessageId = "${chat.serverMessageId}"');
          if(messagesWithServerMessageIdList.length==0){
            await dbClient.insert("chat_messages", chat.toMap());
            List<Map> list = await dbClient.rawQuery('select last_insert_rowid()');
            res = list[0]["last_insert_rowid()"];
          }
        }
        else{
          await dbClient.insert("chat_messages", chat.toMap());
          List<Map> list = await dbClient.rawQuery('select last_insert_rowid()');
          res = list[0]["last_insert_rowid()"];
        }
    return res;
  }

  Future<bool> updateChatMessageStatus(ChatMessageModel chat) async {
    var dbClient = await db;
    int res =   await dbClient.update("chat_messages", chat.toStatusMap(),
        where: "messageId = ?", whereArgs: [chat.messageId]);
    return res > 0 ? true : false;
  }

  Future<bool> updateChatBulkMessagesStatus(String fromId, String toId) async {
    var dbClient = await db;
    ChatMessageModel chat = ChatMessageModel(status: "sent");
    int res =   await dbClient.update("chat_messages", chat.toStatusMap(),
        where: "fromId = ? and toId = ?", whereArgs: [fromId, toId]);

    List<Map> list1 = await dbClient.rawQuery('SELECT * FROM chat_messages where fromId = "${fromId}" and toId = "${toId}"');

    return res > 0 ? true : false;
  }

  // get messages from the db in sorted order of insertion
  Future<List<ChatMessageModel>> getMessagesForChat(String chatId) async {
    var dbClient = await db;
    List<Map> list = await dbClient.rawQuery('SELECT * FROM chat_messages where chatId = "${chatId}" order by messageId desc');
    List<ChatMessageModel> chatList = new List();
    for (int i = list.length-1; i >=0; i--) {
      var chat = new ChatMessageModel(chatId: list[i]["chatId"], toId:list[i]["toId"], fromId:list[i]["fromId"], fromName: list[i]["fromName"], toName:list[i]["toName"], messageText:list[i]["messageText"],
          chatType: list[i]["chatType"], timeStamp:list[i]["timeStamp"], status: list[i]["status"]);
      chatList.add(chat);
    }
    print(chatList.length);
    return chatList;
  }

  // delete all chat for a particular conversation
  Future<int> deleteChat(String chatId) async {
    var dbClient = await db;
    int res =  await dbClient.rawDelete('DELETE FROM chat_messages where chatId = "${chatId}"');
    return res;
  }

  // save a new user so that it shows up on chat tab
  Future<int> saveUser(ValidUser user) async {
    var dbClient = await db;
    int res = await dbClient.insert("valid_users", user.toMap());
  }

  // get users
  Future<List<ValidUser>> getUsers() async {
    var dbClient = await db;
    List<Map> list = await dbClient.rawQuery('SELECT * FROM valid_users order by created_at asc');
    List<ValidUser> userList = new List();
    for (int i = 0; i < list.length; i++) {
      var user = new ValidUser(userId: list[i]["userId"], firstname:list[i]["firstname"], lastname:list[i]["lastname"], username:list[i]["username"], phone:list[i]["phone"],
          numOfMessages: list[i]["numOfMessages"], lastMessage:list[i]["lastMessage"]);
      userList.add(user);
    }
    print(userList.length);
    return userList;
  }

  // update user in case of a new message to reflect the last message and number of new messages
  Future<bool> updateUser(ValidUser user, String page, bool userInChatFlag) async {
    var dbClient = await db;
    int numOfMessages = 0;
    if(page =='conversation' || !userInChatFlag){
      List<Map> list = await dbClient.rawQuery('SELECT * FROM valid_users where userId = "${user.userId}"');
      if(null != list[0]["numOfMessages"]){
        numOfMessages = list[0]["numOfMessages"];
      }
      user.numOfMessages = numOfMessages+1;
    }
    int res =   await dbClient.update("valid_users", user.toUpdateMap(),
        where: "userId = ?", whereArgs: <String>[user.userId]);
    return res > 0 ? true : false;
  }

  // update users table with older messages
  void updateUsersAndSetMessageNumberCount(Map historyUsersMap)  async{
    for(MapEntry<String, UsersHistory> entry in historyUsersMap.entries){
      UsersHistory hisUser = entry.value;
      String key = entry.key;
      ValidUser user = ValidUser(userId: key, lastMessage: hisUser.lastMessage, numOfMessages:hisUser.numOfMessages );
      await updateUserAndSetMessageNumberCount(user);
    }
  }

  // Update user
  Future<bool> updateUserAndSetMessageNumberCount(ValidUser user) async {
    var dbClient = await db;
    int numOfMessages = 0;
    List<Map> list = await dbClient.rawQuery('SELECT * FROM valid_users where userId = "${user.userId}"');
    if(null != list[0]["numOfMessages"]){
      numOfMessages = list[0]["numOfMessages"];
    }
    user.numOfMessages+=numOfMessages;
    int res =   await dbClient.update("valid_users", user.toUpdateMap(),
        where: "userId = ?", whereArgs: <String>[user.userId]);

    List<Map> list1 = await dbClient.rawQuery('SELECT * FROM valid_users where userId = "${user.userId}"');
    return res > 0 ? true : false;
  }

  Future<bool> updateNumMessageUser(ValidUser user) async {
    var dbClient = await db;
    int res =   await dbClient.update("valid_users", user.toUpdateNumMessagesMap(),
        where: "userId = ?", whereArgs: <String>[user.userId]);
    return res > 0 ? true : false;
  }

}