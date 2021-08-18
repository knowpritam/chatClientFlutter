import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutterapp/globals.dart' as globals;
import 'package:flutterapp/models/message.dart';
import 'package:flutterapp/helpers/DBHelper.dart';
import 'package:flutterapp/widgets/ChatBubble.dart';
import 'package:flutterapp/helpers/DateTimeHelper.dart';
import 'package:flutterapp/helpers/ErrorMessageHelper.dart';
import 'package:flutterapp/models/valid_users.dart';
import 'package:keyboard_visibility/keyboard_visibility.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with AutomaticKeepAliveClientMixin<ChatScreen>{

  TextEditingController _controller = TextEditingController();
  ScrollController _chatLVController = ScrollController(
      initialScrollOffset: 0.0);
  List<ChatMessageModel> messagesModel = new List();
  Map<int, int> messageIdToMessageMap = new Map();
  String errorMessage;
  String onlineStatus ='';

  @override
  void initState() {
    KeyboardVisibilityNotification().addNewListener( // On keyboard visible, move the chat list view to top so that the last message is still visible
      onChange: (bool visible) {
        print('keyboard $visible');
        _chatListScrollToBottom();
      },
    );
    super.initState();
    globals.Socket.initSocket();
    if(null == globals.Socket.socketUtils.getSocketIO()){
      globals.Socket.socketUtils.connectSocket();
    }
    _checkOnlineStatus();
    _connectListeners();
    getMessagesForChat();
    _chatListScrollToBottom();
  }

  // check onlineStatus
  _checkOnlineStatus(){
    globals.Socket.socketUtils.getOnlineStatus(globals.globalLoginResponse.userId, globals.otherUser.userId);
  }
  // Initializing all connection listeners which will listen to connection state
  _connectListeners(){
    globals.Socket.socketUtils.setConnectListener(onConnect);
    globals.Socket.socketUtils.setOnConnectionErrorListener(onConnectError);
    globals.Socket.socketUtils.setOnConnectionErrorTimeOutListener(onConnectTimeout);
    globals.Socket.socketUtils.setOnDisconnectListener(onDisconnect);
    globals.Socket.socketUtils.setOnErrorListener(onError);
    globals.Socket.socketUtils.setOnChatMessageReceivedListener(onChatMessageReceived);
    globals.Socket.socketUtils.setOnChatMessageReceivedListenerOld(onChatMessageReceivedOld);
    globals.Socket.socketUtils.setOnUserOnlineStatus(onUserOnlineStatus);
    globals.Socket.socketUtils.setOnMessageDelivered(onMessageDelivered);
    globals.Socket.socketUtils.setOnBulkMessagesDelivered(onBulkMessageDelivered);
  }



  // Handles saving msg to local db and sending message to the server via socket connection
  void _sendMessage() {
    if(globals.online == false){
      errorMessage = "You are disconnected from cloud, please wait or check your network connection";
      showErrorMessage(errorMessage);
      return;
    }
    setState(() {
      ChatMessageModel chatModel = ChatMessageModel(
          chatId: globals.currentConversationId,
          fromId: globals.globalLoginResponse.userId,
          toId: globals.otherUser.userId,
          fromName: globals.globalLoginResponse.firstname,
          toName: globals.otherUser.firstname,
          messageText: _controller.text,
          status: "sent",
          timeStamp: getCurrentTime()
      );
      //messageIdToMessageMap.putIfAbsent(key, () => null)
      if (_controller.text.isNotEmpty) {
        messagesModel.add(chatModel);
        addChatToDb(chatModel).then((value) => {
          chatModel.messageId = value,
          messageIdToMessageMap.putIfAbsent(value, () => messagesModel.length-1),
          updateUserToDb("You : "+_controller.text, globals.globalLoginResponse.userId),
          _controller.text = "",
          globals.Socket.socketUtils.sendChatMessage(chatModel),

        });

        _chatListScrollToBottom();
      }
    });
  }

  // Listener for any new message received from this user when current user is online
  void onChatMessageReceived(data) {
    setState(() {
      ChatMessageModel chatModel = ChatMessageModel.fromJson(data);
      addChatToDb(chatModel);
      updateUserToDb(chatModel.fromName +": "+chatModel.messageText, chatModel.fromId);
      print(data);
      if(chatModel.fromId == globals.otherUser.userId){
        messagesModel.add(chatModel);
        _chatListScrollToBottom();
      }

    });
  }
// Listener for any older message(current user was offline) received from this user
  void onChatMessageReceivedOld(data){
    print('onChatMessageReceivedOld');
    var chatList = data.map((model) => ChatMessageModel.fromJson(model)).toList();
    if(chatList.length>0){
      ChatMessageModel chatModel = chatList[0];
      globals.Socket.socketUtils.sendDeliveredBulkNotif(chatModel.toId, chatModel.fromId);
    }
    setState(() {
      for(int i=chatList.length-1;i>=0;i--){
        ChatMessageModel chatModel = chatList[i];
        addChatToDb(chatModel);
        messagesModel.add(chatModel);
      }
    });
    if(chatList.length!=0)
      updateUserToDb(chatList[0].fromName +": "+chatList[0].messageText, chatList[0].fromId);
    _chatListScrollToBottom();
    print('onChatMessageReceivedOld');
  }

  void onUserOnlineStatus(data){
    setState(() {
      if(data == null){
        onlineStatus = 'offline';
      }
      else if(data == 'online')
        onlineStatus = data.toString();
      else{
        onlineStatus = convertUTCToIST(data);
      }
    });
  }

  void onMessageDelivered(data){
    ChatMessageModel chatModel = ChatMessageModel.fromJson(data);
    var db = new DatabaseHelper();
    db.updateChatMessageStatus(chatModel);
    setState(() {
      messagesModel[messageIdToMessageMap[chatModel.messageId]].status="delivered";
    });
  }

  void onBulkMessageDelivered(){
    getMessagesForChat();
  }

  /***********************************************DB Utilities for chat screen start********************************/
  Future<int> addChatToDb(ChatMessageModel chatModel) async {
    var db = new DatabaseHelper();
    return await db.saveChat(chatModel);
  }

  // Removing chats from local DB -- Chats are not stored on server so this is irreversible
  void clearChatFromDb() async {
    var db = new DatabaseHelper();
    await db.deleteChat(globals.currentConversationId);
    setState(() async{
      getMessagesForChat();
    });
  }

  // Getting message for this chat
  void getMessagesForChat() async {
    print("chatId");
    print(globals.currentConversationId);
    var db = new DatabaseHelper();
    db.getMessagesForChat(globals.currentConversationId).then((res) =>
    {
      setState(() {
        messagesModel = res;
      }),
    });
  }

  // Update last message to user which will be shown on the chat tab
  void updateUserToDb(String message, String fromId) async {
    var db = new DatabaseHelper();
    ValidUser user = ValidUser(userId:fromId, lastMessage: message);
    await fromId==globals.otherUser.userId ? db.updateUser(user, "chat", true) : db.updateUser(user, "chat", false);
  }

  /***********************************************DB Utilities for chat screen end********************************/

  // Scroll the Chat List when it goes to bottom
  _chatListScrollToBottom() {
    Timer(Duration(milliseconds: 100), () {
      if (_chatLVController.hasClients) {
        _chatLVController.animateTo(
          _chatLVController.position.maxScrollExtent,
          duration: Duration(milliseconds: 1),
          curve: Curves.decelerate,
        );
      }
    });
  }

  // ******************************* LISTENERS FOR SOCKET START *******************************
  onConnect(data) {
    print('Connected $data');
    if(globals.currentPage=="chat"){
      globals.Socket.socketUtils.sendUserDetailsForOlderChat(globals.otherUser.userId, globals.globalLoginResponse.userId);
    }
    _checkOnlineStatus();
    setState(() {
      globals.online = true;
      print(data);
      errorMessage = "Connected to cloud";
      //showErrorMessage(errorMessage);
    });
  }

  onConnectError(data) {
    print('onConnectError $data');
    setState(() {
      print(data);
      errorMessage = "Error connecting to server";
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
      //showErrorMessage(errorMessage);
    });
  }
  // ******************************* LISTENERS FOR SOCKET END *******************************

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomPadding: true,
        appBar:
        AppBar(
          title: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(globals.otherUser.firstname),
              Visibility(
                visible: true,
                child: Text(
                  onlineStatus,
                  style: TextStyle(
                    fontSize: 12.0,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.teal,
          actions: <Widget>[
            Padding(
                padding: EdgeInsets.only(right: 20.0),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      clearChatFromDb();
                    });
                  },
                  child: Icon(
                    Icons.delete,
                    size: 26.0,
                  ),
                )
            ),
          ],
        ),
        body: Column(
          children: <Widget>[
            Expanded(
              child: Container(
                child: ListView.builder(
                  shrinkWrap: true,
                  controller: _chatLVController,
                  padding: EdgeInsets.all(10.0),
                  itemCount: messagesModel.length,
                  itemBuilder: (BuildContext context, int index) {
                    ChatMessageModel chatMessage = messagesModel[index];
                    return _chatBubble(
                      chatMessage,
                    );
                  },
                ),
              ),
            ),

            Container(
              margin: EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25.0),
                boxShadow: [
                  BoxShadow(
                      offset: Offset(0, 3),
                      blurRadius: 10,
                      color: Colors.grey)
                ],
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      controller: _controller,
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.all(15.0),
                        hintText: 'Enter text',
                        border: InputBorder.none,
                      ),
                    ),

                  ),
                  Icon(
                    Icons.attach_file,
                    size: 30,
                    color: Colors.teal
                  ),
                  FloatingActionButton(
                    onPressed: _sendMessage,
                    tooltip: 'Send message',
                    child: Icon(Icons.send),
                    backgroundColor: Colors.teal,
                  ),
                ],
              ),
            ),
          ],
        ),
    );
  }

  _chatBubble(ChatMessageModel chatMessageModel) {
    bool fromMe = chatMessageModel.fromId == globals.globalLoginResponse.userId;
    Alignment alignment = fromMe ? Alignment.topRight : Alignment.topLeft;
    Alignment chatArrowAlignment =
    fromMe ? Alignment.topRight : Alignment.topLeft;
    TextStyle textStyle = TextStyle(
      fontSize: 16.0,
      color: fromMe ? Colors.white : Colors.black,
    );
    TextStyle timeStyle = TextStyle(
      fontSize: 10.0,
      color: fromMe ? Colors.white : Colors.black,
    );


    Color chatBgColor = fromMe ? Colors.teal : Colors.black12;
    Color tickColor = fromMe ? Colors.white : Colors.black12;
    EdgeInsets edgeInsets = fromMe
        ? EdgeInsets.fromLTRB(0, 15, 15, 5)
        : EdgeInsets.fromLTRB(10, 15, 5, 5);
    EdgeInsets margins = fromMe
        ? EdgeInsets.fromLTRB(80, 5, 0, 5)
        : EdgeInsets.fromLTRB(0, 5, 80, 5);
    EdgeInsets edgeInsetsTime = fromMe
        ? EdgeInsets.fromLTRB(0, 2, 0, 0)
        : EdgeInsets.fromLTRB(10, 2, 0, 0);
    EdgeInsets edgeInsetsStatus1 = fromMe
        ? EdgeInsets.fromLTRB(30, 0, 0, 10)
        : EdgeInsets.fromLTRB(40, 0, 0, 10);

    return Container(
      margin: margins,
      child: Align(
        alignment: alignment,
        child: Column(
          children: <Widget>[

            CustomPaint(
              painter: ChatBubble(
                color: chatBgColor,
                alignment: chatArrowAlignment,
              ),
              child: Container(
                margin: EdgeInsets.fromLTRB(10, 6, 10, 6),
                child:Wrap(
                  children: <Widget>[
                    Stack(
                      children: <Widget>[
                        Padding(
                          padding: edgeInsets,
                          child: Text(
                            chatMessageModel.messageText,
                            style: textStyle,
                          ),
                        ),
                        Padding(
                          padding: edgeInsetsTime,
                          child: Text(
                            chatMessageModel.timeStamp,
                            style: timeStyle,
                          ),
                        ),
                        Container(
                          margin: edgeInsetsStatus1,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: <Widget>[
                              if(chatMessageModel.status=='sent' && fromMe)
                              Icon(
                                Icons.done,
                                size: 14,
                                color:tickColor,
                              ),
                              if(chatMessageModel.status=='delivered' && fromMe)
                                Icon(
                                  Icons.done_all,
                                  size: 14,
                                  color:tickColor,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),

                  ],
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }

  @override
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => true;
}
List<IconData> icons = [
  Icons.image,
  Icons.camera,
  Icons.file_upload,
  Icons.folder,
  Icons.gif
];


