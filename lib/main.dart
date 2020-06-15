
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutterapp/models/login_response.dart';
import 'package:flutterapp/persistance/shared_preference.dart';
import 'package:flutterapp/globals.dart' as globals;
import 'file:///C:/Users/knowp/AndroidStudioProjects/flutter_app/lib/screens/landingPage.dart';
import 'file:///C:/Users/knowp/AndroidStudioProjects/flutter_app/lib/screens/login_page.dart';

void main() {
  runApp(MaterialApp(
    home: MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  @override
  _State createState() => _State();
}

class _State extends State<MyApp> {
  TextEditingController nameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  String errorMessage = "";

  @override
  void initState() {
    LoginResponse loginResponse;
    readPreference('loginResponse').then((loginPref) => {
      if(null != loginPref){
        loginResponse = postFromJson(loginPref),
        globals.globalLoginResponse = loginResponse,
        if(loginResponse.token != null){
          // User already logged in

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (BuildContext context) => LandingPage(),
            ))
        }
      }
      else{
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (BuildContext context) => LoginPage(),
            ))
      }
    });

    super.initState();

  }

  @override
  Widget build(BuildContext context){
    return new Scaffold(
      body: new Center(
        child: new Text(""),
      ),
    );
  }
}