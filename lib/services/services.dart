import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:flutterapp/models/login.dart';
import 'package:flutterapp/models/phonenumbers_post.dart';
import 'package:flutterapp/models/conversation_post.dart';

import 'dart:io';

Future<http.Response> createPost(String url, Login post) async{
  final response = await http.post('$url',
      headers: {
        HttpHeaders.contentTypeHeader: 'application/json',
        HttpHeaders.authorizationHeader : ''
      },
      body: postToJson(post)
  );
  return response;
}

Future<http.Response> createPostUser(String url, PhoneNumbers post) async{
  final response = await http.post('$url',
      headers: {
        HttpHeaders.contentTypeHeader: 'application/json',
        HttpHeaders.authorizationHeader : ''
      },
      body: postToJsonUser(post)
  );
  return response;
}

Future<http.Response> getUsers(String url) async{
  final response = await http.get('$url');
  return response;
}

Future<http.Response> createPostConversation(String url, Conversation post, String authToken) async{
  String postPayload = postToJsonConversation(post);
  final response = await http.post('$url',
      headers: {
        HttpHeaders.contentTypeHeader: 'application/json',
        HttpHeaders.authorizationHeader : 'bearer ' +authToken,
      },
      body: postToJsonConversation(post)
  );
  return response;
}