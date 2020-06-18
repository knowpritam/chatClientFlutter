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
        "CREATE TABLE IF NOT EXISTS chat_messages(chatId TEXT,toId TEXT, fromId TEXT, fromName TEXT, toName TEXT, messageText TEXT, chatType TEXT, timeStamp TEXT, created_at DATETIME DEFAULT CURRENT_TIMESTAMP);");
    await db.execute(
        "CREATE TABLE IF NOT EXISTS valid_users(userId TEXT,firstname TEXT, lastname TEXT, username TEXT, phone TEXT, numOfMessages INTEGER, lastMessage TEXT, created_at DATETIME DEFAULT CURRENT_TIMESTAMP,  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP);");

  }

  Future<int> saveChat(ChatMessageModel chat) async {
    var dbClient = await db;
    int res = await dbClient.insert("chat_messages", chat.toMap());
    return res;
  }

  Future<List<ChatMessageModel>> getMessagesForChat(String chatId) async {
    var dbClient = await db;
    List<Map> list = await dbClient.rawQuery('SELECT * FROM chat_messages where chatId = "${chatId}" order by created_at desc');
    List<ChatMessageModel> chatList = new List();
    for (int i = list.length-1; i >=0; i--) {
      var chat = new ChatMessageModel(chatId: list[i]["chatId"], toId:list[i]["toId"], fromId:list[i]["fromId"], fromName: list[i]["fromName"], toName:list[i]["toName"], messageText:list[i]["messageText"],
          chatType: list[i]["chatType"], timeStamp:list[i]["timeStamp"]);
      chatList.add(chat);
    }
    print(chatList.length);
    return chatList;
  }

  Future<int> deleteChat(String chatId) async {
    var dbClient = await db;
    int res =
    await dbClient.rawDelete('DELETE FROM chat_messages where chatId = "${chatId}"');
    return res;
  }

  Future<int> saveUser(ValidUser user) async {
    var dbClient = await db;
    int res = await dbClient.insert("valid_users", user.toMap());
    return res;
  }

  Future<List<ValidUser>> getUsers() async {
    var dbClient = await db;
    List<Map> list = await dbClient.rawQuery('SELECT * FROM valid_users order by updated_at asc');
    List<ValidUser> userList = new List();
    for (int i = 0; i < list.length; i++) {
      var user = new ValidUser(userId: list[i]["userId"], firstname:list[i]["firstname"], lastname:list[i]["lastname"], username:list[i]["username"], phone:list[i]["phone"],
          numOfMessages: list[i]["numOfMessages"], lastMessage:list[i]["lastMessage"]);
      userList.add(user);
    }
    print(userList.length);
    return userList;
  }

  Future<bool> updateUser(ValidUser user, String page) async {
    var dbClient = await db;
    int numOfMessages = 0;
    if(page =='conversation'){
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

  Future<bool> updateNumMessageUser(ValidUser user) async {
    var dbClient = await db;
    int res =   await dbClient.update("valid_users", user.toUpdateNumMessagesMap(),
        where: "userId = ?", whereArgs: <String>[user.userId]);
    return res > 0 ? true : false;
  }
}