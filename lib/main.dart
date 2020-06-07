
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/cupertino.dart';

import 'package:flutterapp/models/login_response.dart';
import 'package:flutterapp/screens/signup_screen.dart';
import 'globals.dart' as globals;
import 'package:flutterapp/services/services.dart';
import 'package:flutterapp/models/login.dart';
import 'package:flutterapp/permission/contact.dart';
import 'file:///C:/Users/knowp/AndroidStudioProjects/flutter_app/lib/screens/landingPage.dart';

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

  loginAPI(){
    LoginResponse loginResponse;
    Login login = Login(
      username: nameController.text,
      password: passwordController.text
    );
    String url = 'https://gentle-bayou-08991.herokuapp.com/users/login';
    createPost(url, login).then((response) => {
        if(response.statusCode == 200){
          loginResponse = postFromJson(response.body),
          globals.globalLoginResponse = loginResponse,
          print(loginResponse),
          //getContactAccess(),
          checkContactAccess().then((status) => {
            if(status){
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (BuildContext context) => LandingPage(),
                  ))
            }
            else{
              errorMessage = "Please provide permission to access contacts to proceed further",
              showLErrorMessage(errorMessage),
            }
          }),

        }
        else{
          print(response.statusCode),
          errorMessage = "Login Failed, please recheck the details",
          showLErrorMessage(errorMessage),
        }
      });
  }


  showLErrorMessage(String errorMessage){
    Fluttertoast.showToast(
        msg: errorMessage,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIos: 1,
        backgroundColor: Colors.black,
        textColor: Colors.white,
        fontSize: 16.0
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Sample App'),
          backgroundColor: Colors.teal,
        ),
        body: Padding(
            padding: EdgeInsets.all(10),
            child: ListView(
              children: <Widget>[
                Container(
                    alignment: Alignment.center,
                    padding: EdgeInsets.all(10),
                    child: Text(
                      'Let\'s Chat',
                      style: TextStyle(
                          color: Colors.teal,
                          fontWeight: FontWeight.w500,
                          fontSize: 30),
                    )),
                Container(
                    alignment: Alignment.center,
                    padding: EdgeInsets.all(10),
                    child: Text(
                      'Sign in',
                      style: TextStyle(fontSize: 20),
                    )),
                Container(
                  padding: EdgeInsets.all(10),
                  child: TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                        contentPadding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
                        hintText: "User Name",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(32.0)),
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
                  child: TextField(
                    obscureText: true,
                    controller: passwordController,
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
                      hintText: "Password",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(32.0)),
                    ),
                  ),
                ),
                FlatButton(
                  onPressed: (){
                    //forgot password screen
                  },
                  textColor: Colors.teal,
                  child: Text('Forgot Password'),
                ),
                Container(
                    height: 50,
                    padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                    child: RaisedButton(
                      textColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0)
                      ),
                      color: Colors.teal,
                      child: Text('Login'),
                      onPressed: () {
                        print(nameController.text);
                        print(passwordController.text);
                        loginAPI();
                      },
                    )),
                Container(
                    child: Row(
                      children: <Widget>[
                        Text('Doesn\'t have an account?'),
                        FlatButton(
                          textColor: Colors.teal,
                          padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                          child: Text(
                            'Sign up',
                            style: TextStyle(fontSize: 20),
                          ),
                          onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (BuildContext context) => SignupScreen(),
                              ))
                        )
                      ],
                      mainAxisAlignment: MainAxisAlignment.center,
                    ))
              ],
            )));
  }
}