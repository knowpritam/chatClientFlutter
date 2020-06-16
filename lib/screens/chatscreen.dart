import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutterapp/globals.dart' as globals;
import 'package:flutterapp/models/message.dart';
import 'package:flutterapp/helpers/DBHelper.dart';
import 'package:flutterapp/widgets/ChatBubble.dart';
import 'package:intl/intl.dart';
import 'package:flutterapp/helpers/ErrorMessageHelper.dart';
import 'package:flutterapp/models/valid_users.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {

  TextEditingController _controller = TextEditingController();
  ScrollController _chatLVController = ScrollController(
      initialScrollOffset: 0.0);
  List<ChatMessageModel> messagesModel = new List();
  var messageList = new Map();
  List<String> messages = new List();

  @override
  void initState() {
    super.initState();
    globals.Socket.initSocket();
    if(null == globals.Socket.socketUtils.getSocketIO()){
      globals.Socket.socketUtils.connectSocket();
    }
    print('adasd');
    globals.Socket.socketUtils.setOnChatMessageReceivedListener(
        onChatMessageReceived);
    setState(() {
      getMessagesForChat();
    });
  }

  void _sendMessage() {
    setState(() {
      ChatMessageModel chatModel = ChatMessageModel(
          chatId: globals.currentConversationId,
          fromId: globals.globalLoginResponse.userId,
          toId: globals.otherUser.userId,
          fromName: globals.globalLoginResponse.firstname,
          toName: globals.otherUser.firstname,
          messageText: _controller.text);
      if (_controller.text.isNotEmpty) {
        addChatToDb(chatModel);
        updateUserToDb(_controller.text);
        globals.Socket.socketUtils.sendChatMessage(chatModel);
        chatModel.timeStamp = getCurrentTime();
        messagesModel.add(chatModel);
        _controller.text = "";
        _chatListScrollToBottom();
      }
    });
  }

  void onChatMessageReceived(data) {
    setState(() {
      ChatMessageModel chatModel = ChatMessageModel.fromJson(data);
      chatModel.timeStamp = getCurrentTime();
      addChatToDb(chatModel);
      updateUserToDb(chatModel.messageText);
      print(data);
      //messages.add(data["message"].trim());
      messagesModel.add(chatModel);
      _chatListScrollToBottom();
    });
  }

  void addChatToDb(ChatMessageModel chatModel) async {
    var db = new DatabaseHelper();
    await db.saveChat(chatModel);
  }

  void clearChatFromDb() async {
    var db = new DatabaseHelper();
    await db.deleteChat(globals.currentConversationId);
  }

  void getMessagesForChat() async {
    print("chatId");
    print(globals.currentConversationId);
    var db = new DatabaseHelper();
    db.getMessagesForChat(globals.currentConversationId).then((res) =>
    {
      setState(() {
        messagesModel = res;
        _chatListScrollToBottom();
      }),
    });
  }
  void updateUserToDb(String message) async {
    var db = new DatabaseHelper();
    ValidUser user = ValidUser(userId:globals.otherUser.userId, lastMessage: message);
    await db.updateUser(user);
  }
  /// Scroll the Chat List when it goes to bottom
  _chatListScrollToBottom() {
    Timer(Duration(milliseconds: 100), () {
      if (_chatLVController.hasClients) {
        _chatLVController.animateTo(
          _chatLVController.position.maxScrollExtent,
          duration: Duration(milliseconds: 100),
          curve: Curves.decelerate,
        );
      }
    });
  }

  String getCurrentTime() {
    var now = new DateTime.now();
    var formatter = new DateFormat.Hm();
    String formattedTime = formatter.format(now);
    return formattedTime;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        print('Backbutton pressed (device or appbar button), do whatever you want.');
        globals.Socket.socketUtils.setOffChatMessageReceivedListener();
        Navigator.pop(context, 'true');
        //we need to return a future
        return Future.value(false);
      },
      child: Scaffold(
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
        body: Column(
          children: <Widget>[
            Expanded(
              child: Container(
                child: ListView.builder(
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


