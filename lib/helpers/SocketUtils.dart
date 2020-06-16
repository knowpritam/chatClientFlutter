import 'dart:io';
//import 'package:flutter_socket_io/flutter_socket_io.dart';
import 'package:adhara_socket_io/adhara_socket_io.dart';
//import 'package:flutter_socket_io/socket_io_manager.dart';
import 'package:flutterapp/models/message.dart';
import 'package:flutterapp/globals.dart' as globals;

class SocketUtils {
  //
  static SocketIO socketIO;
  SocketIOManager _manager;
  Future connectSocket() async{
    _init();
  }
  _init() async{
    _manager = SocketIOManager();
    socketIO = await _manager.createInstance(_socketOptions());
    socketIO.connect();
    print('socketId');
    print(socketIO.id);
    socketIO.emit("login",  [globals.globalLoginResponse.toJson()]);
  }
  _socketOptions() {
    final Map<String, String> userMap = {
    };
    return SocketOptions(
      "https://gentle-bayou-08991.herokuapp.com",
      enableLogging: true,
      transports: [Transports.WEB_SOCKET],
      query: userMap,
    );
  }

  _onSocketInfo(dynamic data) {
    print("Socket info: " + data);
  }

  getSocketIO(){
    return socketIO;
  }
  _socketStatus(dynamic data) {
    print("Socket status: " + data);
  }

  setOnChatMessageReceivedListener(Function onChatMessageReceived) {
    socketIO.on('chat_direct', (data) {
      print("Received $data");
      onChatMessageReceived(data);
    });
  }

  setOnChatMessageReceivedListenerUserPage(Function setOnChatMessageReceivedListenerUserPage) {
    socketIO.on('chat_indirect', (data) {
      print("Received $data");
      setOnChatMessageReceivedListenerUserPage(data);
    });
  }

  setOffChatMessageReceivedListenerUserPage() {
    socketIO.off('chat_indirect', (data) {
      print("Received $data");
    });
  }
  setOffChatMessageReceivedListener() {
    socketIO.off('chat_direct', (data) {
      print("Received $data");
    });
  }
  setOnMessageBackFromServer(Function onMessageBackFromServer) {
    if (socketIO != null) {
      socketIO.on('chat_direct', (data) {
        onMessageBackFromServer(data);
      });
    }

  }

//  void sendChatMessage(String msg) async {
//    if (socketIO != null) {
//      //dynamic jsonData = '{"message":{"type":"Text","content": ${(msg != null && msg.isNotEmpty) ? '"${msg}"' : '"Hello SOCKET IO PLUGIN :))"'},"owner":"589f10b9bbcd694aa570988d","avatar":"img/avatar-default.png"},"sender":{"userId":"589f10b9bbcd694aa570988d","first":"Ha","last":"Test 2","location":{"lat":10.792273999999999,"long":106.6430356,"accuracy":38,"regionId":null,"vendor":"gps","verticalAccuracy":null},"name":"Ha Test 2"},"receivers":["587e1147744c6260e2d3a4af"],"conversationId":"589f116612aa254aa4fef79f","name":null,"isAnonymous":null}';
//      ChatMessageModel chat = ChatMessageModel(chatId:globals.currentConversationId, from:globals.globalLoginResponse.userId,
//          to:globals.otherUser.userId, fromName:globals.globalLoginResponse.firstname, toName
//          :globals.otherUser.firstname, message: msg);
//      socketIO.emit("chat_direct", [chat.toJson()]);
//    }
//  }
  void sendChatMessage( ChatMessageModel chat) async {
    if (socketIO != null) {
      socketIO.emit("chat_direct", [chat.toJson()]);
    }
  }
//  _destroySocket() {
//    if (socketIO != null) {
//      SocketIOManager().destroySocket(socketIO);
//    }
//  }
  setConnectListener(Function onConnect) {
    socketIO.onConnect((data) {
      onConnect(data);
    });
  }

  setOnConnectionErrorListener(Function onConnectError) {
    socketIO.onConnectError((data) {
      onConnectError(data);
    });
  }

  setOnConnectionErrorTimeOutListener(Function onConnectTimeout) {
    socketIO.onConnectTimeout((data) {
      onConnectTimeout(data);
    });
  }

  setOnErrorListener(Function onError) {
    socketIO.onError((error) {
      onError(error);
    });
  }

  setOnDisconnectListener(Function onDisconnect) {
    socketIO.onDisconnect((data) {
      print("onDisconnect $data");
      onDisconnect(data);
    });
  }
}
