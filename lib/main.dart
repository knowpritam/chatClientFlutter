
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutterapp/models/login_response.dart';
import 'package:flutterapp/persistance/SharedPreference.dart';
import 'package:flutterapp/services/PushNotification.dart';
import 'package:flutterapp/globals.dart' as globals;
import 'file:///C:/Users/knowp/AndroidStudioProjects/flutter_app/lib/screens/LandingPage.dart';
import 'file:///C:/Users/knowp/AndroidStudioProjects/flutter_app/lib/screens/LoginPage.dart';

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
    new PushNotificationsManager().init();
    readPreference('notifToken').then((value) => {  // checking if any conversation exists in preferences
      if(null != value && value.length>0){
        globals.notifToken = value,
        //checkForAnyPendingConversationRequest(),
      }
    });
    LoginResponse loginResponse;
    readPreference('showMessageOnChatTab').then((value) =>{
      if(value=='true') {
        globals.showMessageOnChatTab= true
      }
      else globals.showMessageOnChatTab = false,
    });
    // checking from preference if user is already logged in
    readPreference('loginResponse').then((loginPref) => {
      if(null != loginPref){
        loginResponse = postFromJson(loginPref),
        loginResponse.notifToken = globals.notifToken,
        globals.globalLoginResponse = loginResponse,
        if(loginResponse.token != null){
          // User already logged in
          globals.Socket.initSocket(),
          if(null == globals.Socket.socketUtils.getSocketIO()){
            globals.Socket.socketUtils.connectSocket(),
          },
          Navigator.pop(context, true),
          globals.currentPage="landing",
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (BuildContext context) => LandingPage(),
            ))
        }
      }
      // User not logged in, navigate to login page
      else{
        Navigator.pop(context, true),
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