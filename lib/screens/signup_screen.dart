
import 'package:flutter/material.dart';
import 'package:flutterapp/globals.dart' as globals;
import 'package:flutterapp/services/services.dart';
import 'package:flutterapp/models/signup_post.dart';
import 'package:flutterapp/widgets/Dialog.dart';

class SignupScreen extends StatelessWidget {
  TextEditingController nameController = TextEditingController();
  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController reEnterPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final GlobalKey<State> _keyLoader = new GlobalKey<State>();

  signupUser(BuildContext context){
    String url = globals.url+'/users/signup';
    SignupModel signupModel = SignupModel(
        username: nameController.text,
        password: passwordController.text,
        firstname: firstNameController.text,
        lastname: lastNameController.text
    );
    Dialogs.showLoadingDialog(context, _keyLoader,  "Please wait ... ");
    createUser(url, signupModel).then((response) =>
      {
        if(response.body.contains("Successful")){
          Navigator.of(_keyLoader.currentContext,rootNavigator: true).pop(),//close the dialoge
          Navigator.pop(context, true)
        }
      });
    }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Sample App'),
          backgroundColor: Colors.teal,
        ),
        body: Form(
          key: _formKey,
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
                      'Sign up',
                      style: TextStyle(fontSize: 20),
                    )),
                Container(
                  padding: EdgeInsets.all(10),
                  child: TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
                      labelText: "Username",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(32.0),
                        borderSide: BorderSide(color: Colors.teal),),
                    ),
                    validator: (value) {
                      if(value.length < 6){
                        return 'User name should be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(10),
                  child: TextFormField(
                    controller: firstNameController,
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
                      labelText: "Firstname",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(32.0),
                        borderSide: BorderSide(color: Colors.teal),
                      ),
                    ),
                    validator: (value) {
                      if (value.isEmpty) {
                        return 'Firstname is required';
                      }
                      return null;
                    },
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(10),
                  child: TextFormField(
                    controller: lastNameController,
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
                      labelText: "Lastname",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(32.0)),
                    ),
                    validator: (value) {
                      if (value.isEmpty) {
                        return 'Lastname is required';
                      }
                      return null;
                    },
                  ),
                ),
                Container(
                  padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
                  child: TextFormField(
                    obscureText: true,
                    controller: passwordController,
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
                      labelText: "Password",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(32.0)),
                    ),
                    validator: (value) {
                      if(value.length < 6){
                        return 'Password should be at least 6 characters';
                      }
                      return null;
                    },
                  ),

                ),
                Container(
                  padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
                  child: TextFormField(
                    obscureText: true,
                    controller: reEnterPasswordController,
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
                      labelText: "Retype password",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(32.0)),
                    ),
                    validator: (value) {
                      if(value != passwordController.text){
                        return 'Value entered does not match with password';
                      }
                      return null;
                    },
                  ),
                ),
                
                Container(
                    height: 70,
                    padding: EdgeInsets.fromLTRB(10, 20, 10, 0),
                    child: RaisedButton(
                      textColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0)
                      ),
                      color: Colors.teal,
                      onPressed: () {
                        // Validate returns true if the form is valid, otherwise false.
                        if (_formKey.currentState.validate()) {
                          signupUser(context);
                        }
                      },
                      child: Text('Submit'),
                    ),
                ),

              ],
            )));
  }
}