import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutterapp/globals.dart' as globals;
import 'package:flutterapp/models/message.dart';
import 'package:flutterapp/helpers/DBHelper.dart';
import 'package:flutterapp/widgets/ChatBubble.dart';
import 'package:intl/intl.dart';
import 'package:flutterapp/helpers/ErrorMessageHelper.dart';
import 'package:flutterapp/models/valid_users.dart';
import 'package:flutterapp/helpers/HistoryHelper.dart';
import 'package:flutterapp/services/services.dart';
import 'package:keyboard_visibility/keyboard_visibility.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {

  TextEditingController _controller = TextEditingController();
  ScrollController _chatLVController = ScrollController(
      initialScrollOffset: 0.0);
  List<ChatMessageModel> messagesModel = new List();
  String errorMessage;
  // Add variable to top of class
  Alignment childAlignment = Alignment.center;

  @override
  void initState() {
    KeyboardVisibilityNotification().addNewListener(
      onChange: (bool visible) {
        print('keyboard $visible');
        _chatListScrollToBottom();
        // Add state updating code
        setState(() {
          childAlignment = visible ? Alignment.topCenter : Alignment.center;

        });
      },
    );
    super.initState();
    globals.Socket.initSocket();
    if(null == globals.Socket.socketUtils.getSocketIO()){
      globals.Socket.socketUtils.connectSocket();
    }
    print('adasd');
    // Registering socket to listen to received message on chat screen
    _connectListeners();
    setState(() {
      getMessagesAndScrollToEnd();
    });
  }

  // Initializing all connection listeners which will listen to connection state
  _connectListeners(){
    globals.Socket.socketUtils.setConnectListener(onConnect);
    globals.Socket.socketUtils.setOnConnectionErrorListener(onConnectError);
    globals.Socket.socketUtils.setOnConnectionErrorTimeOutListener(onConnectTimeout);
    globals.Socket.socketUtils.setOnDisconnectListener(onDisconnect);
    globals.Socket.socketUtils.setOnErrorListener(onError);
    globals.Socket.socketUtils.setOnChatMessageReceivedListener(onChatMessageReceived);
  }

  //
  void getMessagesAndScrollToEnd() async{
    await getMessagesForChat();
    _chatListScrollToBottom();
  }
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
          timeStamp: getCurrentTime()
      );
      if (_controller.text.isNotEmpty) {
        addChatToDb(chatModel);
        updateUserToDb("You : "+_controller.text);
        globals.Socket.socketUtils.sendChatMessage(chatModel);
        messagesModel.add(chatModel);
        _controller.text = "";
        _chatListScrollToBottom();
      }
    });
  }

  String getCurrentTime() {
    var now = new DateTime.now();
    var formatter = new DateFormat.Hm();
    String formattedTime = formatter.format(now);
    return formattedTime;
  }

  // Listener for any new message received from this user
  void onChatMessageReceived(data) {
    setState(() {
      ChatMessageModel chatModel = ChatMessageModel.fromJson(data);
      addChatToDb(chatModel);
      updateUserToDb(chatModel.fromName +": "+chatModel.messageText);
      print(data);
      messagesModel.add(chatModel);
      _chatListScrollToBottom();
    });
  }

  void addChatToDb(ChatMessageModel chatModel) async {
    var db = new DatabaseHelper();
    await db.saveChat(chatModel);
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
      if(this.mounted){
        setState(() {
          messagesModel = res;
        }),
      }
    });
  }

  // Update last message to user which will be shown on the chat tab
  void updateUserToDb(String message) async {
    var db = new DatabaseHelper();
    ValidUser user = ValidUser(userId:globals.otherUser.userId, lastMessage: message);
    await db.updateUser(user, "chat");
  }

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
    getMessagesAndScrollToEnd();
  }
// ******************************* LISTENERS FOR SOCKET START *******************************
  onConnect(data) {
    print('Connected $data');
    if(globals.currentPage=="chat")
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
      showErrorMessage(errorMessage);
    });
  }
// ******************************* LISTENERS FOR SOCKET END *******************************

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        globals.currentPage="landing";
        print('Backbutton pressed (device or appbar button), do whatever you want.');
        globals.Socket.socketUtils.setOffChatMessageReceivedListener();
        Navigator.pop(context);
        //we need to return a future
        return Future.value(false);
      },
      child: Scaffold(
          resizeToAvoidBottomPadding: true,
        appBar: AppBar(
          title: Text(globals.otherUser.firstname),
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
        body: AnimatedContainer(
          curve: Curves.easeOut,
          duration: Duration(
            milliseconds: 400,
          ),
          width: double.infinity,
          height: double.infinity,
          //padding: const EdgeInsets.all(20),
          alignment: Alignment.topCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Flexible(
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
        ),

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
      color: fromMe ? Colors.white : Colors.black54,
    );
    TextStyle timeStyle = TextStyle(
      fontSize: 10.0,
      color: fromMe ? Colors.white : Colors.black54,
    );
    Color chatBgColor = fromMe ? Colors.teal : Colors.black12;
    EdgeInsets edgeInsets = fromMe
        ? EdgeInsets.fromLTRB(0, 15, 15, 5)
        : EdgeInsets.fromLTRB(10, 15, 5, 5);
    EdgeInsets margins = fromMe
        ? EdgeInsets.fromLTRB(80, 5, 0, 5)
        : EdgeInsets.fromLTRB(0, 5, 80, 5);
    EdgeInsets edgeInsetsTime = fromMe
        ? EdgeInsets.fromLTRB(0, 0, 0, 0)
        : EdgeInsets.fromLTRB(10, 0, 0, 0);

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
                margin: EdgeInsets.fromLTRB(10, 10, 10, 10),
                child: Stack(
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
List<IconData> icons = [
  Icons.image,
  Icons.camera,
  Icons.file_upload,
  Icons.folder,
  Icons.gif
];


