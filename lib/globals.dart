library flutterapp.globals;
import 'package:flutter/material.dart';
import 'package:flutterapp/models/login_response.dart';
import 'package:flutterapp/models/valid_users.dart';
import 'package:flutterapp/helpers/SocketUtils.dart';
import 'package:contacts_service/contacts_service.dart';


bool isLoggedIn = false;
LoginResponse globalLoginResponse = LoginResponse();
String url = 'https://gentle-bayou-08991.herokuapp.com';
String currentConversationId;
bool showMessageOnChatTab;
bool online = true;
Iterable<Contact> contacts = null;
String currentPage = "";


ValidUser loggedInUser;
ValidUser otherUser;

class Socket {
  // Socket
  static SocketUtils socketUtils;

  static initSocket() {
    if (null == socketUtils) {
      socketUtils = SocketUtils();
    }
  }
}