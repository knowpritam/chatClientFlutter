import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:flutterapp/models/login_response.dart';
import 'package:flutterapp/models/login.dart';
import 'dart:io';

String url = 'https://gentle-bayou-08991.herokuapp.com/users/login';

//Future<Login> getPost() async{
//  final response = await http.get('$url/1');
//  return postFromJson(response.body);
//}

Future<http.Response> createPost(Login post) async{
  final response = await http.post('$url',
      headers: {
        HttpHeaders.contentTypeHeader: 'application/json',
        HttpHeaders.authorizationHeader : ''
      },
      body: postToJson(post)
  );
  return response;
}