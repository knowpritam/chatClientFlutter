
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutterapp/models/conversation_post.dart';
import 'package:flutterapp/globals.dart' as globals;
import 'package:flutterapp/models/valid_users.dart';
import 'package:flutterapp/services/services.dart';
import 'package:flutterapp/screens/chatscreen.dart';
import 'package:flutterapp/persistance/shared_preference.dart';
import 'package:flutterapp/widgets/Dialog.dart';
import 'package:flutterapp/models/message.dart';
import 'package:flutterapp/helpers/DBHelper.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutterapp/helpers/ErrorMessageHelper.dart';

class LandingPage extends StatefulWidget {
  @override
  LandingPageState createState() => LandingPageState();
}

class LandingPageState extends State<LandingPage> {
  List<ValidUser> validUserList = new List();             // Users which will be shown in Users tab
  List<ValidUser> userWithConversationList =  new List(); // Users which will be shown in chat tab
  List<ValidUser> listToUse =  new List();                // Takes value from either of the above two lists
  Map<String, UsersHistory> historyUsersMap = new Map();                        // Stores lastMessage and numOfMessages against userId(from)

  List<ChatMessageModel> chatList = new List();           //
  var userIdConversationMap = new Map();                  // Stores conversationId against userId
  var currentConversationId;                              // Stores currentConversationId
  final GlobalKey<State> _keyLoader = new GlobalKey<State>();
  String errorMessage;
  bool showMessageOnChatTab = false;

  @override
  void initState() {
    getAllRegisteredUser();                               // Getting all users and putting in validUserList
    super.initState();
    _connectSocket();
    getUsersForConversation();                            // Getting all users and putting in userWithConversationList
    getHistory();                                         // Getting history chat
  }

  _connectSocket(){
    Future.delayed(Duration(seconds: 2), () async {
      globals.Socket.initSocket();
      if(null == globals.Socket.socketUtils.getSocketIO()){
        globals.Socket.socketUtils.connectSocket().then((value) => {
          _connectListeners(),
        });
      }
      else{
        _connectListeners();
      }
    });
  }

  // Initializing all connection listeners which will listen to connection state
  _connectListeners(){
    globals.Socket.socketUtils.setConnectListener(onConnect);
    globals.Socket.socketUtils.setOnConnectionErrorListener(onConnectError);
    globals.Socket.socketUtils.setOnConnectionErrorTimeOutListener(onConnectTimeout);
    globals.Socket.socketUtils.setOnDisconnectListener(onDisconnect);
    globals.Socket.socketUtils.setOnErrorListener(onError);
    globals.Socket.socketUtils.setOnChatMessageReceivedListenerUserPage(onChatMessageReceivedUserPage);
  }

  // Listens to any new message which is received by this user and updated the message and notify user
  onChatMessageReceivedUserPage(data){
    setState(() {
      ChatMessageModel chatModel = ChatMessageModel.fromJson(data);
      updateAndGetUsers(chatModel);
      print(data);
    });
  }

  // Gets the chats(when user was offline) for this user from server and notifies the user
  getHistory(){
    String url = globals.url+'/messages/messagesForUser/'+globals.globalLoginResponse.userId;
    int ad = 0;
    getHistoryChat(url).then((response) => {
      print(response.body),
      // If response is not blank i.e. at least one chat message is there on server for this user
      if(response.statusCode == 200 && response.body != '[]'){
        deleteHistoryChat(url), // deleting the chat from server once received by client
        setState(() {
          Iterable list = json.decode(response.body);
          chatList = list.map((model) => ChatMessageModel.fromJson(model)).toList();
          for(int i = chatList.length-1; i>=0;i--){
            if(historyUsersMap.containsKey(chatList[i].fromId)){
              UsersHistory user = historyUsersMap[chatList[i].fromId];
              user.numOfMessages+=1; // updating new numberOfMessages
              user.lastMessage = chatList[i].messageText; // updating new Last message
              historyUsersMap.update(chatList[i].fromId, (value) => user);
            }
            else{
              UsersHistory user = UsersHistory(lastMessage: chatList[i].messageText, numOfMessages: 1);
              historyUsersMap.putIfAbsent(chatList[i].fromId, () => user);
            }
          }
          updateHistoryAndGetUsers(chatList, historyUsersMap);
        }),
      }
    });
  }

  // ************************************ DATABASE HELPER METHODS START *******************************

  // Message arrived when current user is on chat page then update the lastMessage and save the message to chat.
  updateAndGetUsers(ChatMessageModel chatModel) async{
    var db = new DatabaseHelper();
    await  db.saveChat(chatModel);
    ValidUser user = ValidUser(userId: chatModel.fromId, lastMessage: chatModel.fromName +": "+chatModel.messageText);
    await db.updateUser(user, "conversation");
    getUsersForConversation();
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('state = $state');
  }
  // Update older messages to the chat and from user so that it shows up on chat tab for current user
  updateHistoryAndGetUsers(List<ChatMessageModel> chats, Map historyUsersMap) async{
    var db = new DatabaseHelper();
    await db.saveHistoryChat(chats);
    int len = chats.length;
    if(len>0){
      ValidUser user = ValidUser(userId: chats[0].fromId, lastMessage: chats[0].fromName +": "+chats[0].messageText);
      await db.updateUsersAndSetMessageNumberCount(historyUsersMap);
      getUsersForConversation();
      historyUsersMap.clear();
    }
  }

  // GET all users which current user has started conversation with from db
  void getUsersForConversation() async {
    var db = new DatabaseHelper();
    await db.getUsers().then((res) =>
    {
      setState(() {
        userWithConversationList = res;
      }),
    });
  }

  // Adding user to db with numOfMessages as 0 and then updating the list to show on chat page.
  void addUserToDb(ValidUser user) async {
    var db = new DatabaseHelper();
    user.numOfMessages = 0;
    await db.saveUser(user);
    userWithConversationList.insert(0, user);
  }
 // Updating user numOfMessage to zero so that user does not see any "new message" while coming back to users page
  void updateNumMessagesToZeroUser(String userId) async {
    var db = new DatabaseHelper();
    ValidUser user = ValidUser(userId: userId, numOfMessages: 0);
    await db.updateNumMessageUser(user);
  }
  // ************************************ DATABASE HELPER METHODS END *******************************

  // Get all registered user from server db
  getAllRegisteredUser(){
    String url = globals.url+'/users';
    getUsers(url).then((response) => {
      print(response.body),
      if(response.statusCode == 200){
        setState(() {
          savePreference('userList', response.body); // saving the users to preferences
          removeCurrentUserFromUserTab(response.body);
          int a =10;
        }),
      }
    });
  }

  // Current user is also part of all the registered users, removing that from list
  void removeCurrentUserFromUserTab(String responseBody){
    int currUserIndex = -1;
    Iterable list = json.decode(responseBody);
    validUserList = list.map((model) => ValidUser.fromJson(model)).toList();
    for(int i=0; i<validUserList.length;i++){
      ValidUser validUser = validUserList[i];
      if(validUser.userId == globals.globalLoginResponse.userId){ // updating currUserIndex for current user
        currUserIndex = i;
      }
    }
    validUserList.removeAt(currUserIndex); // removing current user from the list
  }

  // Checking if a conversation already exist with clicked user in preference or create/get a new conversation from server
  checkIfConversationExistOrCreateConversation(index, BuildContext context, String fromTab){
    if(fromTab == "chat"){ // if call is from chat tab then list to use will be userWithConversationList
      listToUse = userWithConversationList;
    }
    else listToUse = validUserList; // if call is from users tab then list to use will be validUserList
    Participant currentUser = new Participant(participant : globals.globalLoginResponse.userId);
    Participant otherUser = new Participant(participant : listToUse[index].userId);
    globals.otherUser = listToUse[index];
    readPreference('userIdConversationMap').then((value) => {  // checking if any conversation exists in preferences
      if(null != value && value.length>0){
        userIdConversationMap = json.decode(value),
        if(userIdConversationMap.containsKey(listToUse[index].userId)){ // checking if conversation already exist for clicked user
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

  // Get conversation from server if exists or create a new conversation
  getOrCreateConversation(Participant currentUser, Participant otherUser, int index){
    List<Participant> participantList = new List();
    participantList.add(currentUser);
    participantList.add(otherUser);
    Dialogs.showLoadingDialog(context, _keyLoader,  "Starting conversation ...");
    Conversation conversation = Conversation(participants: participantList);
    String url = globals.url+'/conversations/findConversationForUsers';
    createConversation(url, conversation, globals.globalLoginResponse.token).then((response) => {  // Getting conversation btw current user and clicked user
      print(response.body),
      if(response.statusCode == 200 && response.body.length>10){  // if the response is not blank (conversation exists)
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
        Navigator.of(_keyLoader.currentContext,rootNavigator: true).pop(),//close the dialog
        navigateToChatScreen(),
      }
      else{ // If response for GET conversation is blank then create a new conversation
        url =  globals.url+'/conversations',
        createConversation(url, conversation, globals.globalLoginResponse.token).then((response) => {
          print(response.body),
          if(response.statusCode == 200){
            setState(() {
              Iterable list = json.decode('['+response.body+']');
              Map intermediateMap = list.toList().asMap()[0];
              String conversationId = intermediateMap["_id"];
              globals.currentConversationId = conversationId;
              userIdConversationMap.putIfAbsent(listToUse[index].userId, () => conversationId);
              addUserToDb(listToUse[index]);
              savePreference('userIdConversationMap', jsonEncode(userIdConversationMap)); // save the conversation map to preference
            }),
            Navigator.of(_keyLoader.currentContext,rootNavigator: true).pop(),//close the dialog
            navigateToChatScreen(),
          }
        }),
      }
    });
  }

  // Navigate to new chat screen
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

  // Enabling the listener for messageReceived on landing page so that any new message can be shown to the user.
  setSocketListenerOn(){
    globals.Socket.socketUtils.setOnChatMessageReceivedListenerUserPage(onChatMessageReceivedUserPage);
    setState(() {
      getHistory();
      getUsersForConversation();
    });
  }

  // ******************************* LISTENERS FOR SOCKET START *******************************
  onConnect(data) {
    print('Connected $data');
    setState(() {
      print(data);
      getHistory();
      getUsersForConversation();
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
// ******************************* LISTENERS FOR SOCKET END *******************************
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


