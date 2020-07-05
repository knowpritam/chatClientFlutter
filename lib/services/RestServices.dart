import 'package:flutterapp/models/signup_post.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:flutterapp/models/login.dart';
import 'package:flutterapp/globals.dart' as globals;
import 'package:flutterapp/models/conversation_post.dart';

import 'dart:io';

// get chats(when user was offline) for the logged in user
Future<http.Response> getHistoryChat(String url ) async{
  final response = await http.get('$url',
    headers: {
      HttpHeaders.authorizationHeader : 'bearer ' +globals.globalLoginResponse.token,
    },
  );
  return response;
}

// delete chats for the logged in user from server
Future<http.Response> deleteHistoryChat(String url ) async{
  final response = await http.delete('$url',
    headers: {
      HttpHeaders.authorizationHeader : 'bearer ' +globals.globalLoginResponse.token,
    },
  );
  return response;
}

// get(if exists) or create conversation between two users
Future<http.Response> createConversation(String url, Conversation post, String authToken) async{
  final response = await http.post('$url',
      headers: {
        HttpHeaders.contentTypeHeader: 'application/json',
        HttpHeaders.authorizationHeader : 'bearer ' +authToken,
      },
      body: postToJsonConversation(post)
  );
  return response;
}

// get all conversations for logged in user
Future<http.Response> getConversationsForUser(String url ) async{
  final response = await http.get('$url',
    headers: {
      HttpHeaders.authorizationHeader : 'bearer ' +globals.globalLoginResponse.token,
    },
  );
  return response;
}

// Login REST call
Future<http.Response> loginUser(String url, Login post) async{
  final response = await http.post('$url',
      headers: {
        HttpHeaders.contentTypeHeader: 'application/json',
        HttpHeaders.authorizationHeader : ''
      },
      body: postToJson(post)
  );
  return response;
}

// create a new user (Signup)
Future<http.Response> createUser(String url, SignupModel post) async {
  String postPayload = postToJsonSignup(post);
  final response = await http.post('$url',
      headers: {
        HttpHeaders.contentTypeHeader: 'application/json',
      },
      body: postPayload
  );
  return response;
}

// get all user
Future<http.Response> getUsers(String url) async{
  final response = await http.get('$url');
  return response;
}