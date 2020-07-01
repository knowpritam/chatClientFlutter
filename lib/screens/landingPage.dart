
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
import 'package:flutterapp/helpers/HistoryHelper.dart';
import 'package:contacts_service/contacts_service.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutterapp/helpers/ErrorMessageHelper.dart';

class LandingPage extends StatefulWidget {
  @override
  LandingPageState createState() => LandingPageState();
}

class LandingPageState extends State<LandingPage> {
  Iterable<Contact> _contacts = null;
  List<ValidUser> validUserList = new List();             // Users which will be shown in Users tab
  List<ValidUser> userWithConversationList =  new List(); // Users which will be shown in chat tab
  List<ValidUser> listToUse =  new List();                // Takes value from either of the above two lists

  List<ValidUser> pendingUserList = new List();           // Users which will be shown in notifications
  Map<String, ValidUser> pendingUserMap = new Map();      // Map to maintain pending Users and will be used to identify and remove when the user is not pending
  Map<String, UsersHistory> historyUsersMap = new Map();  // Stores lastMessage and numOfMessages against userId(from)
  Map<String, ValidUser> validContactsForThisUserMap = new Map();

  List<ChatMessageModel> chatList = new List();           //
                  // Stores conversationId against userId
  var currentConversationId;                              // Stores currentConversationId
  final GlobalKey<State> _keyLoader = new GlobalKey<State>();
  final GlobalKey<State> _keyLoader1 = new GlobalKey<State>();
  String errorMessage;
  bool showMessageOnChatTab = false;
  var refreshKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    //getAllRegisteredUser();                               // Getting all users and putting in validUserList
    getUsersForConversation();
    getAllUsersIfNotFetchedAlready();
    super.initState();
    _connectSocket();
                                // Getting all users and putting in userWithConversationList
    getHistory();                                         // Getting history chat
    getUsersForConversation();
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

//  // Gets the chats(when user was offline) for this user from server and notifies the user
//  getHistory(){
//    String url = globals.url+'/messages/messagesForUser/'+globals.globalLoginResponse.userId;
//    int ad = 0;
//    getHistoryChat(url).then((response) => {
//      print(response.body),
//      // If response is not blank i.e. at least one chat message is there on server for this user
//      if(response.statusCode == 200 && response.body != '[]'){
//        deleteHistoryChat(url), // deleting the chat from server once received by client
//        setState(() {
//          Iterable list = json.decode(response.body);
//          chatList = list.map((model) => ChatMessageModel.fromJson(model)).toList();
//          for(int i = chatList.length-1; i>=0;i--){
//            if(historyUsersMap.containsKey(chatList[i].fromId)){
//              UsersHistory user = historyUsersMap[chatList[i].fromId];
//              user.numOfMessages+=1; // updating new numberOfMessages
//              user.lastMessage = chatList[i].fromName+' : '+chatList[i].messageText; // updating new Last message
//              historyUsersMap.update(chatList[i].fromId, (value) => user);
//            }
//            else{
//              UsersHistory user = UsersHistory(lastMessage: chatList[i].messageText, numOfMessages: 1);
//              historyUsersMap.putIfAbsent(chatList[i].fromId, () => user);
//            }
//          }
//          updateHistoryAndGetUsers(chatList, historyUsersMap);
//        }),
//      }
//    });
//  }
  // Gets the chats(when user was offline) for this user from server and notifies the user
  getHistory(){
    String url = globals.url+'/messages/messagesForUser/'+globals.globalLoginResponse.userId;
    int ad = 0;
    getHistoryChat(url).then((response) => {
      print(response.body),
      // If response is not blank i.e. at least one chat message is there on server for this user
      if(response.statusCode == 200 && response.body != '[]'){
        deleteHistoryChat(url), // deleting the chat from server once received by client
        getLocalHistory(response.body),
      }
    });
  }

  getLocalHistory(String response) async{
    await getHistoryAndUpdateUsers(response);
    getUsersForConversation();
  }

//  getHistoryAndUpdateUsers(String response) async {
//    Iterable list = json.decode(response);
//    chatList = list.map((model) => ChatMessageModel.fromJson(model)).toList();
//    for(int i = chatList.length-1; i>=0;i--){
//      if(historyUsersMap.containsKey(chatList[i].fromId)){
//        UsersHistory user = historyUsersMap[chatList[i].fromId];
//        user.numOfMessages+=1; // updating new numberOfMessages
//        user.lastMessage = chatList[i].fromName+' : '+chatList[i].messageText; // updating new Last message
//        historyUsersMap.update(chatList[i].fromId, (value) => user);
//      }
//      else{
//        UsersHistory user = UsersHistory(lastMessage: chatList[i].messageText, numOfMessages: 1);
//        historyUsersMap.putIfAbsent(chatList[i].fromId, () => user);
//      }
//    }
//    await updateHistoryAndGetUsers(chatList, historyUsersMap);
//    int a = 10;
//  }
  // ************************************ DATABASE HELPER METHODS START *******************************

  // Message arrived when current user is on chat page then update the lastMessage and save the message to chat.
  updateAndGetUsers(ChatMessageModel chatModel) async{
    var db = new DatabaseHelper();
    await  db.saveChat(chatModel);
    ValidUser user = ValidUser(userId: chatModel.fromId, lastMessage: chatModel.fromName +": "+chatModel.messageText);
    await db.updateUser(user, "conversation");
    getUsersForConversation();
  }

//  // Update older messages to the chat and from user so that it shows up on chat tab for current user
//  updateHistoryAndGetUsers(List<ChatMessageModel> chats, Map historyUsersMap) async{
//    var db = new DatabaseHelper();
//    await db.saveHistoryChat(chats);
//    int len = chats.length;
//    if(len>0){
//      ValidUser user = ValidUser(userId: chats[0].fromId, lastMessage: chats[0].fromName +": "+chats[0].messageText);
//      await db.updateUsersAndSetMessageNumberCount(historyUsersMap);
//      historyUsersMap.clear();
//    }
//  }

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
      //userWithConversationList.add(user);
  }
  // Updating user numOfMessage to zero so that user does not see any "new message" while coming back to users page
  void updateNumMessagesToZeroUser(String userId) async {
    var db = new DatabaseHelper();
    ValidUser user = ValidUser(userId: userId, numOfMessages: 0);
    await db.updateNumMessageUser(user);
  }
        // ************************************ DATABASE HELPER METHODS END *******************************

  getAllUsersIfNotFetchedAlready(){
    Iterable list;
    readPreference('userList').then((value) => {  // checking if any conversation exists in preferences
        if(null != value && value.length>0){
        list = json.decode(value),
        validUserList= list.map((model) => ValidUser.fromJson(model)).toList(),
        print(validUserList),
        //checkForAnyPendingConversationRequest(),
      }
      else{
        getAllUser()
      }
    });
  }
  // Get all registered user from server
  getAllUser(){
    String url = globals.url+'/users';
    Dialogs.showLoadingDialog(context, _keyLoader,  "Getting users");
    getUsers(url).then((response) => {
      print(response.body),
      if(response.statusCode == 200){
        setState(() {
          populateValidContactsMap(response.body);
          //checkForAnyPendingConversationRequest();
          int a =10;
        }),
      }
    });
  }

  // Current user is also part of all the registered users, removing that from list
  void populateValidContactsMap(String responseBody){
    int currUserIndex = -1;
    Iterable list = json.decode(responseBody);
    List<ValidUser> validUserListTemp = list.map((model) => ValidUser.fromJson(model)).toList();
    for(int i=0; i<validUserListTemp.length;i++){
    ValidUser validUser = validUserListTemp[i];
    validContactsForThisUserMap.putIfAbsent(validUser.phone, () => validUser);
    if(validUser.userId == globals.globalLoginResponse.userId){ // updating currUserIndex for current user
      currUserIndex = i;
    }
  }
  getContacts();
//validUserList.removeAt(currUserIndex); // removing current user from the list
}

  Future<void> getContacts() async {
    //Make sure we already have permissions for contacts when we get to this
    //page, so we can just retrieve it
    Iterable<Contact> contacts;
    if(globals.contacts != null){
      contacts = globals.contacts;
    }
    else contacts = await ContactsService.getContacts();

    Set phoneNumSet = new Set();
    setState(() {
      _contacts = contacts;
      List<Contact> contactsList = _contacts.toList();
      validUserList.clear();
      for (int i=0; i< contactsList.length; i++) {
        String phoneNum = "";
        if(contactsList[i]!=null && contactsList[i].phones != null && contactsList[i].phones.length!=0 && contactsList[i].phones.first!=null){
          phoneNum = contactsList[i].phones.first.value.toString();
          //print(phoneNum);
          phoneNum = phoneNum.trim().replaceAll("-", "").replaceAll(" ", "").replaceAll("(", "").replaceAll(")", "");
          print(phoneNum);

          if(phoneNum.length >= 10){
            var actPhoneNum = phoneNum.substring(phoneNum.length-10);
            if(validContactsForThisUserMap.containsKey(actPhoneNum) && !phoneNumSet.contains(actPhoneNum) ){
              phoneNumSet.add(actPhoneNum);
              validUserList.add(validContactsForThisUserMap[actPhoneNum]);
            }
          }
        }
      }
      Navigator.of(_keyLoader.currentContext,rootNavigator: true).pop();//close the dialog
      savePreference('userList', jsonEncode(validUserList)); // saving the users to preferences
    });
  }

  // Checking if a conversation already exist with clicked user in preference or create/get a new conversation from server
  checkIfConversationExistOrCreateConversation(index, BuildContext context, String fromTab){
    var userIdConversationMap = new Map();
    if(fromTab == "chat"){ // if call is from chat tab then list to use will be userWithConversationList
      listToUse = userWithConversationList;
    }
    else if(fromTab == "pending"){ // if call is from pending chat dialog then list to use will be pendingUserList
      listToUse = pendingUserList;
      Navigator.of(_keyLoader1.currentContext,rootNavigator: true).pop();//close the dialog
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
          getOrCreateConversation(currentUser, otherUser, index, userIdConversationMap),
        }
      }
      else{
        getOrCreateConversation(currentUser, otherUser, index, userIdConversationMap),
      }
    });
  }

  // Get conversation from server if exists or create a new conversation
  getOrCreateConversation(Participant currentUser, Participant otherUser, int index, Map userIdConversationMap){
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
          pendingUserList.remove(listToUse[index]);
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
              pendingUserList.remove(listToUse[index]);
              savePreference('userIdConversationMap', jsonEncode(userIdConversationMap)); // save the conversation map to preference
            }),
            Navigator.of(_keyLoader.currentContext,rootNavigator: true).pop(),//close the dialog
            navigateToChatScreen(),
          }
        }),
      }
    });
  }
  List parseStringAndFindPhoneNumbers(String responseBody){
    List<String> phoneNumList = new List();
    String str = responseBody;
    while(str.contains("phone")){
      int ind = str.indexOf("phone");
      String phoneNum = str.substring(ind+8, ind+18);
      if(phoneNum!=globals.globalLoginResponse.phone)
        phoneNumList.add(phoneNum);
      str = str.substring(ind+20);
    }
    return phoneNumList;
  }

  checkForAnyPendingConversationRequest() async{
    Map userWithConversationMap = new Map();
    Map validUserMap = new Map();
    List phoneNumList;
    ValidUser validUser;
    pendingUserList.clear();
    Dialogs.showLoadingDialog(context, _keyLoader,  "Checking notifications for new conversation...");
    String url = globals.url+'/conversations/findConversationForUser/'+globals.globalLoginResponse.userId;
    getConversationsForUser(url).then((response) => {
      if(response != null && response.statusCode == 200 && response.body !='[]'){
        if(userWithConversationList!=null && validUserList!= null){
          populateLocalUserMaps(userWithConversationMap, validUserMap),
          phoneNumList = parseStringAndFindPhoneNumbers(response.body),
          for(int i=0;i<phoneNumList.length;i++){
            if(validUserMap.containsKey(phoneNumList[i]) && !userWithConversationMap.containsKey(phoneNumList[i])){
              validUser = validUserMap[phoneNumList[i]],
              setState(() {
                pendingUserList.add(validUser);
                Navigator.of(_keyLoader.currentContext,rootNavigator: true).pop();//close the dialog
                _displayDialog(context);
              }),
            },
          }
        },
        if(pendingUserList.length==0){
          Navigator.of(_keyLoader.currentContext,rootNavigator: true).pop(),//close the dialog
          errorMessage = "No pending conversations found from your contact list",
          showErrorMessage(errorMessage),
        }
      }
    });
  }

  populateLocalUserMaps(Map userWithConversationMap,  Map validUserMap){
    for(int i=0;i<userWithConversationList.length;i++){
      ValidUser validUser = userWithConversationList[i];
      userWithConversationMap.putIfAbsent(validUser.phone, () => validUser);
    }
    for(int i=0;i<validUserList.length;i++){
      ValidUser validUser = validUserList[i];
      validUserMap.putIfAbsent(validUser.phone, () => validUser);
    }
  }
  // Navigate to new chat screen
  navigateToChatScreen(){
    savePreference('showMessageOnChatTab', 'false');
    globals.showMessageOnChatTab = false;
    connectSocket();
    updateNumMessagesToZeroUser(globals.otherUser.userId);
    globals.currentPage="chat";
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
      //getHistory();
      getUsersForConversation();
    });
  }

  // ******************************* LISTENERS FOR SOCKET START *******************************
  onConnect(data) {
    print('Connected $data');
    if(globals.currentPage=="landing")
      getHistory();
    setState(() {
      globals.online = true;
      print(data);
      errorMessage = "Connected to cloud";
      showErrorMessage(errorMessage);
    });
  }

  onConnectError(data) {
    print('onConnectError $data');
    setState(() {
      print(data);
      errorMessage = "Error connecting to cloud";
      //showErrorMessage(errorMessage);
    });
  }

  onConnectTimeout(data) {
    print('onConnectTimeout $data');
    setState(() {
      print(data);
      errorMessage = "Timeout while connecting to server";
      //showErrorMessage(errorMessage);
    });
  }

  onError(data) {
    print('onError $data');
    setState(() {
      print(data);
      errorMessage = "Error connecting to server";
      //showErrorMessage(errorMessage);
    });
  }

  onDisconnect(data) {
    print('onDisconnect $data');
    setState(() {
      globals.online = false;
      print(data);
      errorMessage = "Disconnected from cloud";
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
          appBar: AppBar(title: Text('Let\'s Chat'),
            actions: <Widget>[
              Stack(
                children: <Widget>[
                  Padding(
                      padding: EdgeInsets.only(right: 20.0, top:15.0),
                      child: GestureDetector(
                        onTap: () {
                          checkForAnyPendingConversationRequest();
                        },
                        child: Icon(
                          Icons.update,
                          size: 26.0,
                        ),
                      )
                  ),
//                  Padding(
//                    padding: EdgeInsets.only(left: 15.0, top:10.0),
//                      child:  notifCount>0? CircleAvatar(
//                        backgroundColor: Colors.black54,
//                        radius: 10.0,
//                        child: new Text(notifCount.toString(),
//                          style: new TextStyle(color: Colors.white,
//                            fontSize: 12.0,),),
//                      ):null,
//                  ),
                ],
              )
            ],
          ),

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
                      allUsersTab(context),
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
      child: Text("Check for any conversation request (top right reload icon) or go to Users tab and start chatting, the user will start appearing here.",
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
                          Text(validUser.lastMessage != null ?validUser.lastMessage.toString():"no message",
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

  Widget allUsersTab(BuildContext context){
    return Column(
          children: <Widget>[
            Expanded(
                child: Container(
                  child: allUserList(context)
                )
            ),
            Container(
            ),
            Container(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                textDirection: TextDirection.rtl,
                children : <Widget>[
                  Padding(
                  padding: EdgeInsets.only(bottom:20.0, right: 20.0),
                    child: FloatingActionButton(
                      onPressed: () {
                        setState(() {
                          getAllUser();
                        });
                      },
                      tooltip: 'Reload Users',
                      child: Icon(Icons.refresh),
                      backgroundColor: Colors.teal,
                    ),
                  )

                ]
              )
            )
          ]
      );
  }

  Widget pendingChatTab(BuildContext context) {
    return
      ListView.builder(
      itemCount: pendingUserList.length,
      itemBuilder: (context, index) {
        ValidUser validUser = pendingUserList[index];
        return Card(
            child: InkWell(
              onTap: () =>
                  checkIfConversationExistOrCreateConversation(index, context, "pending"),
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
                          Text(validUser.firstname.toString()+" "+validUser.lastname.toString(), style: TextStyle(fontSize: 16),),
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

  Widget allUserList(BuildContext context) {
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

   _displayDialog(BuildContext context) async {
    return showDialog(
        context: context,
        builder: (context) {
          return SimpleDialog(
            key: _keyLoader1,
            title: Text('Chat Requests'),
            children: <Widget>[
              Container(
                height: 150.0, // Change as per your requirement
                width: 300.0,
                child: pendingChatTab(context),
              ),
            ],
          );
        });
  }
}


