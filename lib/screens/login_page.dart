
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/cupertino.dart';

import 'package:flutterapp/models/login_response.dart';
import 'package:flutterapp/screens/signup_screen.dart';
import 'package:flutterapp/globals.dart' as globals;
import 'package:flutterapp/services/services.dart';
import 'package:flutterapp/models/login.dart';
import 'package:flutterapp/models/valid_users.dart';
import 'package:flutterapp/helpers/SocketUtils.dart';
import 'package:flutterapp/helpers/ErrorMessageHelper.dart';
import 'package:flutterapp/persistance/shared_preference.dart';
import 'file:///C:/Users/knowp/AndroidStudioProjects/flutter_app/lib/screens/landingPage.dart';

void main() {
  runApp(MaterialApp(
    home: LoginPage(),
  ));
}

class LoginPage extends StatefulWidget {
  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  TextEditingController nameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  String errorMessage = "";
  SocketUtils socketUtils = SocketUtils();

  loginAPI(){
    LoginResponse loginResponse;
    ValidUser loggedInUser;
    Login login = Login(
        username: nameController.text,
        password: passwordController.text
    );
    String url = globals.url+'/users/login';
    loginUser(url, login).then((response) => {
      if(response.statusCode == 200){
        // save response to preference which will be used for further validations
        savePreference('loginResponse', response.body),
        savePreference('showMessageOnChatTab', 'true'),
        globals.showMessageOnChatTab= true,
        loginResponse = postFromJson(response.body),
        globals.globalLoginResponse = loginResponse,
        loggedInUser = new ValidUser(userId: loginResponse.userId, firstname: loginResponse.firstname, lastname: loginResponse.lastname,
             username: loginResponse.firstname, phone: "2"),
        globals.loggedInUser = loggedInUser,
        print(loginResponse),
        // initializing socket
        initSocket(),
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (BuildContext context) => LandingPage(),
            ))
      }
      else{
        // Show error for failed login attempt
        print(response.statusCode),
        errorMessage = "Login Failed, please check and reenter the details",
        showErrorMessage(errorMessage),
      }
    });
  }

  initSocket(){
    globals.Socket.initSocket();
    globals.Socket.socketUtils.connectSocket();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(''),
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
                      labelText: "Username",
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
                      labelText: "Password",
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