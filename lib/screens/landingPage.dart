
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:contacts_service/contacts_service.dart';
import 'package:flutterapp/models/phonenumbers_post.dart';
import 'package:flutterapp/models/conversation_post.dart';
import 'package:flutterapp/globals.dart' as globals;
import 'package:flutterapp/models/valid_users.dart';
import 'package:flutterapp/services/services.dart';
import 'package:flutterapp/screens/chatscreen.dart';
import 'package:flutterapp/persistance/shared_preference.dart';
import 'package:flutterapp/widgets/Dialog.dart';
import 'package:flutterapp/models/message.dart';
import 'package:flutterapp/helpers/DBHelper.dart';
import 'package:intl/intl.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutterapp/helpers/ErrorMessageHelper.dart';

class LandingPage extends StatefulWidget {
  @override
  LandingPageState createState() => LandingPageState();
}

class LandingPageState extends State<LandingPage> {
  Iterable<Contact> _contacts;
  List<Numbers> phoneNumbers = new List();
  PhoneNumbers phoneNumbersType = PhoneNumbers();
  List<ValidUser> validUserList = new List();
  List<ValidUser> userWithConversationList =  new List();
  List<ValidUser> listToUse =  new List();

  var indexToUserIdMap = new Map();
  var phoneToUserIdMap = new Map();
  var userIdConversationMap = new Map();
  var currentConversationId;
  final GlobalKey<State> _keyLoader = new GlobalKey<State>();
  String errorMessage;
  bool showMessageOnChatTab = false;

  @override
  void initState() {
    getAllRegisteredUser();

    print("got contacts");
    super.initState();
    _connectSocket();
    getUsersForConversation();
  }
  _connectSocket(){
    Future.delayed(Duration(seconds: 2), () async {
      globals.Socket.initSocket();
      if(null == globals.Socket.socketUtils.getSocketIO()){
        globals.Socket.socketUtils.connectSocket().then((value) => {
          _connectListsners(),
        });
      }
      else{
        _connectListsners();
      }
    });
  }
  _connectListsners(){
    globals.Socket.socketUtils.setConnectListener(onConnect);
    globals.Socket.socketUtils.setOnConnectionErrorListener(onConnectError);
    globals.Socket.socketUtils.setOnConnectionErrorTimeOutListener(onConnectTimeout);
    globals.Socket.socketUtils.setOnDisconnectListener(onDisconnect);
    globals.Socket.socketUtils.setOnErrorListener(onError);
    globals.Socket.socketUtils.setOnChatMessageReceivedListenerUserPage(onChatMessageReceivedUserPage);
  }
  onChatMessageReceivedUserPage(data){
    setState(() {
      ChatMessageModel chatModel = ChatMessageModel.fromJson(data);
      chatModel.timeStamp = getCurrentTime();
      updateAndGetUsers(chatModel);
      //validUserList[valid]
      //showErrorMessage("New  Message from "+"${chatModel.fromName}"+" : "+"${chatModel.messageText}");
      print(data);
    });
  }

  updateAndGetUsers(ChatMessageModel chatModel) async{
    await addChatToDb(chatModel);
    await updateUserToDb(chatModel.fromId, chatModel.fromName +": "+chatModel.messageText);
    await getUsersForConversation();
  }
  String getCurrentTime() {
    var now = new DateTime.now();
    var formatter = new DateFormat.Hm();
    String formattedTime = formatter.format(now);
    return formattedTime;
  }
  void addChatToDb(ChatMessageModel chatModel) async {
    var db = new DatabaseHelper();
    await db.saveChat(chatModel);
  }

  getAllRegisteredUser(){
    String url = globals.url+'/users';

    getUsers(url).then((response) => {
      print(response.body),
      if(response.statusCode == 200){
        setState(() {
          savePreference('userList', response.body);
          populateValidUsersMap(response.body);
          int a =10;
        }),
      }
    });
  }

  void populateValidUsersMap(String responseBody){
    int currUserIndex = -1;
    Iterable list = json.decode(responseBody);
    validUserList = list.map((model) => ValidUser.fromJson(model)).toList();
    for(int i=0; i<validUserList.length;i++){
      ValidUser validUser = validUserList[i];
      if(validUser.userId == globals.globalLoginResponse.userId){
        currUserIndex = i;
      }
    }
    validUserList.removeAt(currUserIndex);
  }

  checkIfConversationExistOrCreateConversation(index, BuildContext context, String fromTab){
    if(fromTab == "chat"){
      listToUse = userWithConversationList;
    }
    else listToUse = validUserList;

    Participant currentUser = new Participant(participant : globals.globalLoginResponse.userId);
    Participant otherUser = new Participant(participant : listToUse[index].userId);
    globals.otherUser = listToUse[index];

    readPreference('userIdConversationMap').then((value) => {
      if(null != value && value.length>0){
        userIdConversationMap = json.decode(value),
        if(userIdConversationMap.containsKey(listToUse[index].userId)){
          currentConversationId = userIdConversationMap[listToUse[index].userId],
          globals.currentConversationId = currentConversationId,
          navigateToChatScreen(),
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
  getOrCreateConversation(Participant currentUser, Participant otherUser, int index){
    List<Participant> participantList = new List();
    participantList.add(currentUser);
    participantList.add(otherUser);
    Dialogs.showLoadingDialog(context, _keyLoader,  "Starting conversation ...");
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
          userIdConversationMap.putIfAbsent(listToUse[index].userId, () => conversationId);
          addUserToDb(listToUse[index]);
          userWithConversationList.insert(0, listToUse[index]);
          savePreference('userIdConversationMap', jsonEncode(userIdConversationMap));
        }),
        Navigator.of(_keyLoader.currentContext,rootNavigator: true).pop(),//close the dialoge
        navigateToChatScreen(),
      }
      else{
        url =  globals.url+'/conversations',
        createPostConversation(url, conversation, globals.globalLoginResponse.token).then((response) => {
          print(response.body),
          if(response.statusCode == 200){
            setState(() {
              Iterable list = json.decode('['+response.body+']');
              Map intermediateMap = list.toList().asMap()[0];
              String conversationId = intermediateMap["_id"];
              globals.currentConversationId = conversationId;
              userIdConversationMap.putIfAbsent(listToUse[index].userId, () => conversationId);
              addUserToDb(listToUse[index]);

              savePreference('userIdConversationMap', jsonEncode(userIdConversationMap));
            }),
            Navigator.of(_keyLoader.currentContext,rootNavigator: true).pop(),//close the dialog
            navigateToChatScreen(),
          }
        }),
      }
    });
  }
  void addUserToDb(ValidUser user) async {
    var db = new DatabaseHelper();
    user.numOfMessages = 0;
    await db.saveUser(user);
    userWithConversationList.insert(0, user);
  }

  void updateUserToDb(String userId, String message) async {
    var db = new DatabaseHelper();
    ValidUser user = ValidUser(userId: userId, lastMessage: message);
    await db.updateUser(user, "conversation");
  }
  void updateNumMessagesToZeroUser(String userId) async {
    var db = new DatabaseHelper();
    ValidUser user = ValidUser(userId: userId, numOfMessages: 0);
    await db.updateNumMessageUser(user);
  }
  void getUsersForConversation() async {
    var db = new DatabaseHelper();
    await db.getUsers().then((res) =>
    {
      setState(() {
        userWithConversationList = res;
      }),
    });
  }

  navigateToChatScreen(){
    savePreference('showMessageOnChatTab', 'false');
    globals.showMessageOnChatTab = false;
    connectSocket();
    updateNumMessagesToZeroUser(globals.otherUser.userId);
    Navigator.of(context).push(
        MaterialPageRoute(
          builder: (BuildContext context) => ChatScreen(),
    )).whenComplete(() => setSocketListenerOn());
  }
  connectSocket() async{
    if(null == globals.Socket.socketUtils.getSocketIO()){
      globals.Socket.socketUtils.connectSocket().then((value) => {
        globals.Socket.socketUtils.setOffChatMessageReceivedListenerUserPage(),
      });
    }
    else{
      globals.Socket.socketUtils.setOffChatMessageReceivedListenerUserPage();
    }
  }
  setSocketListenerOn(){
    globals.Socket.socketUtils.setOnChatMessageReceivedListenerUserPage(onChatMessageReceivedUserPage);
    setState(() {
      getUsersForConversation();
    });
  }
  onConnect(data) {
    print('Connected $data');
    setState(() {
      print(data);
      errorMessage = "Connected to server";
      showErrorMessage(errorMessage);
    });
  }

  onConnectError(data) {
    print('onConnectError $data');
    setState(() {
      print(data);
      errorMessage = "Error connecting to server";
      showErrorMessage(errorMessage);
    });
  }

  onConnectTimeout(data) {
    print('onConnectTimeout $data');
    setState(() {
      print(data);
      errorMessage = "Timeout while connecting to server";
      showErrorMessage(errorMessage);
    });
  }

  onError(data) {
    print('onError $data');
    setState(() {
      print(data);
      errorMessage = "Error connecting to server";
      showErrorMessage(errorMessage);
    });
  }

  onDisconnect(data) {
    print('onDisconnect $data');
    setState(() {
      print(data);
      errorMessage = "Disconnected from server";
      showErrorMessage(errorMessage);
    });
  }

  @override
  Widget build(BuildContext context) {
    TextStyle textStyle = TextStyle(
      fontSize: 16.0,
      color: Colors.black54,
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ListViews',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: Scaffold(
          appBar: AppBar(title: Text('Let\'s Chat')),
          body:DefaultTabController(
            length: 2,
            child: Column(
              children: <Widget>[
                Container(
                  constraints: BoxConstraints.expand(height: 50),
                  child: TabBar(tabs: [
                    Tab(
                      child: Text(
                        "Chats",
                        style: textStyle,
                      ),
                    ),
                    Tab(
                      child: Text(
                        "Users",
                        style: textStyle,
                      ),
                    ),
                  ]),
                ),
                Expanded(
                  child: Container(
                    child: TabBarView(children: [
                      globals.showMessageOnChatTab ? _listEmptyText(): chatTab(context),
                      allUserTab(context),
                    ]),
                  ),
                )
              ],
            ),
          ),
      ),
    );
  }

  Widget _listEmptyText(){
    return Padding(
      padding :  EdgeInsets.all(10),
      child: Text("Please go to users tab and start chatting, the user will start appearing here.",
        style: TextStyle(fontSize: 16, color: Colors.teal),
      ),
    ) ;

  }

  Widget chatTab(BuildContext context) {
    return ListView.builder(
      itemCount: userWithConversationList.length,
      itemBuilder: (context, index) {
        ValidUser validUser = userWithConversationList[index];
        return Card(
            child: InkWell(
              onTap: () =>
                  checkIfConversationExistOrCreateConversation(index, context, "chat"),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(5, 5, 10, 5),
                      child: Icon(
                        Icons.account_circle,
                        size: 24.0,
                        color: Colors.teal,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        // align the text to the left instead of centered
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(validUser.firstname.toString(), style: TextStyle(fontSize: 16),),
                          Text(validUser.lastMessage != null ?validUser.lastMessage.toString():" ",
                            style: TextStyle(fontSize: 12, color: Colors.black54),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            softWrap: true
                          ),
                        ],
                      ),
                    ),
                    (validUser.numOfMessages!=null && validUser.numOfMessages>0)?
                    unreadNotification(context, validUser):
                    Text(" read",
                      style: new TextStyle(color: Colors.white,
                        fontSize: 12.0,),),
                  ],
                ),
              ),
            )
        );
      },
    );
  }

  Widget unreadNotification(BuildContext context, ValidUser validUser){
    return Container(
      child: Row(
          children: <Widget>[
            CircleAvatar(
              backgroundColor: Colors.teal,
              radius: 10.0,
              child: new Text(validUser.numOfMessages.toString(),
                style: new TextStyle(color: Colors.white,
                  fontSize: 12.0,),),
            ),
            Text(" unread",
              style: new TextStyle(color: Colors.black54,
                fontSize: 12.0,),),
          ]
      )

    );

  }

  Widget allUserTab(BuildContext context) {
    return ListView.builder(
      itemCount: validUserList.length,
      itemBuilder: (context, index) {
        ValidUser validUser = validUserList[index];
        return Card(
            child: InkWell(
              onTap: () =>
                  checkIfConversationExistOrCreateConversation(index, context, "users"),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(5, 5, 10, 5),
                      child: Icon(
                        Icons.account_circle,
                        size: 24.0,
                        color: Colors.teal,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        // align the text to the left instead of centered
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(validUser.firstname.toString()+' '+validUser.lastname.toString()+' ('+validUser.username.toString()+')', style: TextStyle(fontSize: 16),),
                          //Text('Kanchan: Hw r u?', style: TextStyle(fontSize: 10, color: Colors.black45),),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
        );
      },
    );
  }
}


