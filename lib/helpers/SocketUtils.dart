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
    await _init();
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

  void sendChatMessage( ChatMessageModel chat) async {
    if (socketIO != null) {
      socketIO.emit("chat_direct", [chat.toJson()]);
    }
  }

  setConnectListener(Function onConnect) {
    socketIO.onConnect((data) {
      socketIO.emit("login",  [globals.globalLoginResponse.toJson()]);
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
