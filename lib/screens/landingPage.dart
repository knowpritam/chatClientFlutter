import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutterapp/helpers/SocketUtils.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:flutterapp/models/phonenumbers_post.dart';
import 'package:flutterapp/models/conversation_post.dart';
import 'package:flutterapp/globals.dart' as globals;
import 'package:flutterapp/models/valid_users.dart';
import 'package:flutterapp/services/services.dart';
import 'package:flutterapp/screens/chatscreen.dart';
import 'package:flutterapp/persistance/shared_preference.dart';

class LandingPage extends StatefulWidget {
  @override
  LandingPageState createState() => LandingPageState();
}


class LandingPageState extends State<LandingPage> {

  Iterable<Contact> _contacts;
  List<Numbers> phoneNumbers = new List();
  PhoneNumbers phoneNumbersType = PhoneNumbers();
  List<ValidUser> validUserList = new List();
  var validUserMap = new Map();
  var phoneToUserIdMap = new Map();
  var userIdConversationMap = new Map();
  var currentConversationId;
  bool _connectedToSocket;
  String _errorConnectMessage;

  @override
  void initState() {
    getAllRegiesterdUser();
    print("got contacts");
    super.initState();
    globals.Socket.initSocket();
    if(null == globals.Socket.socketUtils.getSocketIO()){
      globals.Socket.socketUtils.connectSocket();
    }
  }

  getAllRegiesterdUser(){
    String url = globals.url+'/users';
    getUsers(url).then((response) => {
      print(response.body),
      if(response.statusCode == 200){
        setState(() {
          savePreference('userList', response.body);
          validUserMap =getValidUsersMap(response.body);
          print(validUserMap[0].firstname.toString());
          int a =10;
        }),
      }
    });
  }

  Map getValidUsersMap(String responseBody){
    Iterable list = json.decode(responseBody);
    validUserList = list.map((model) => ValidUser.fromJson(model)).toList();
    return validUserList.asMap();
  }

  checkIfConversationExistOrCreateConversation(index){
    Participant currentUser = new Participant(participant : globals.globalLoginResponse.userId);
    Participant otherUser = new Participant(participant : validUserMap[index].userId);
    globals.otherUser = validUserMap[index];

    readPreference('userIdConversationMap').then((value) => {
      if(null != value && value.length>0){
        userIdConversationMap = json.decode(value),
        if(userIdConversationMap.containsKey(validUserMap[index].userId)){
          currentConversationId = userIdConversationMap[validUserMap[index].userId],
          globals.currentConversationId = currentConversationId,

          Navigator.of(context).push(
              MaterialPageRoute(
                builder: (BuildContext context) => ChatScreen(),
              ))
        }
        else{
          getOrCreateConversation(currentUser, otherUser, index),
        }
      }
      else{
        getOrCreateConversation(currentUser, otherUser, index),
      }
    });
  }
  initSocket(){
    globals.Socket.initSocket();
    globals.Socket.socketUtils.connectSocket();
  }
  getOrCreateConversation(Participant currentUser, Participant otherUser, int index){
    List<Participant> participantList = new List();
    participantList.add(currentUser);
    participantList.add(otherUser);
    Conversation conversation = Conversation(participants: participantList);
    String url = globals.url+'/conversations/findConversationForUsers';
    createPostConversation(url, conversation, globals.globalLoginResponse.token).then((response) => {
      print(response.body),
      if(response.statusCode == 200 && response.body.length>10){
        setState(() {
          Iterable list = json.decode(response.body);
          Map intermediateMap = list.toList().asMap()[0];
          String conversationId = intermediateMap["_id"];
          globals.currentConversationId = conversationId;
          userIdConversationMap.putIfAbsent(validUserMap[index].userId, () => conversationId);
          savePreference('userIdConversationMap', jsonEncode(userIdConversationMap));
        }),
        Navigator.of(context).push(
            MaterialPageRoute(
              builder: (BuildContext context) => ChatScreen(),
            ))
      }
      else{
        url =  globals.url+'/conversations',
        createPostConversation(url, conversation, globals.globalLoginResponse.token).then((response) => {
          print(response.body),
          if(response.statusCode == 200){
            setState(() {
              Iterable list = json.decode(response.body);
              Map intermediateMap = list.toList().asMap()[0];
              String conversationId = intermediateMap["_id"];
              globals.currentConversationId = conversationId;
              userIdConversationMap.putIfAbsent(validUserMap[index].userId, () => conversationId);
              savePreference('userIdConversationMap', jsonEncode(userIdConversationMap));
            }),
          }
        }),
      }
    });
  }

  populatephoneToUserIdMap(Map validUserMap){
    for(int i=0;i<validUserMap.length;i++){
      phoneToUserIdMap.putIfAbsent(validUserMap[i].phone.toString(), () => validUserMap[i].userId.toString());
    }
    savePreference('validUsersPhoneToIdMap', jsonEncode(phoneToUserIdMap));
  }

  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ListViews',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: Scaffold(
        appBar: AppBar(title: Text('Conversations')),
        body: ListView.builder(
          itemCount: validUserList.length,
          itemBuilder: (context, index) {
            return Card(
              child: ListTile(
                title: Text(validUserMap[index].firstname.toString()),
                leading: Icon(Icons.account_circle),
              onTap: () =>
                  checkIfConversationExistOrCreateConversation(index)
              ),
            );
          },
        ),
      ),
    );
  }
}


