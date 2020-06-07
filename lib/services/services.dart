import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:flutterapp/models/login_response.dart';
import 'package:flutterapp/models/login.dart';
import 'package:flutterapp/models/phonenumbers_post.dart';
import 'dart:io';


//Future<Login> getPost() async{
//  final response = await http.get('$url/1');
//  return postFromJson(response.body);
//}

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