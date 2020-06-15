import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'package:flutterapp/globals.dart' as globals;
import 'package:flutterapp/models/message.dart';
import 'package:flutterapp/helpers/SocketUtils.dart';
import 'package:flutterapp/models/valid_users.dart';
import 'package:intl/intl.dart';
import 'package:flutter/scheduler.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {

  int _counter = 0;
  TextEditingController _controller = TextEditingController();
  ScrollController _chatLVController = ScrollController(initialScrollOffset: 0.0);
  List<ChatMessageModel> messagesModel = new List();
  var messageList = new Map();
  List<String> messages = new List();

  @override
  void initState() {
    messages.add("Test");
    super.initState();
    globals.Socket.initSocket();
    //globals.Socket.socketUtils.connectSocket();
    globals.Socket.socketUtils.setOnChatMessageReceivedListener(onChatMessageReceived);
  }
  @override
  void setState(fn) {
    // TODO: implement setState
    int a  =10;
    super.setState(fn);
  }
  void onChatMessageReceived(data){
    setState(() {
      //var jsonData = json.decode(data.toString());
      ChatMessageModel chatModel = ChatMessageModel.fromJson(data);
//      ChatMessageModel chatModel = ChatMessageModel.fromJson(jsonData);
      print(data);
      messages.add(data["message"]);
      messagesModel.add(chatModel);
      _chatListScrollToBottom();
      int A = 10;
    });
  }
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () {
          print('Backbutton pressed (device or appbar button), do whatever you want.');
          globals.Socket.socketUtils.setOffChatMessageReceivedListener();
          Navigator.pop(context, true);
          //we need to return a future
          return Future.value(false);
        },
    child: Scaffold(
      appBar: AppBar(
        title: Text(globals.otherUser.firstname),
        backgroundColor: Colors.teal,
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
                  return Card(
                    child: Padding(
                      padding: EdgeInsets.all(10.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            chatMessage.message,
                            style: TextStyle(
                              fontSize: 16.0,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            chatMessage.fromName,
                            style: TextStyle(
                              fontSize: 12.0,
                              color: Colors.teal,
                            ),
                          ),
                        ],
                      ),
                    ),
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
                        contentPadding: EdgeInsets.all( 15.0),
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
  void _sendMessage() {
    setState(() {
      if (_controller.text.isNotEmpty) {
        globals.Socket.socketUtils.sendChatMessage(_controller.text);
        _controller.text = "";
      }
    });
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
}

List<IconData> icons = [
  Icons.image,
  Icons.camera,
  Icons.file_upload,
  Icons.folder,
  Icons.gif
];


