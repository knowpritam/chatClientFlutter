import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:contacts_service/contacts_service.dart';
import 'package:flutterapp/models/phonenumbers_post.dart';
import 'package:flutterapp/models/login_response.dart';
import 'package:flutterapp/models/valid_users.dart';
import 'package:flutterapp/services/services.dart';

class LandingPage extends StatefulWidget {
  @override
  LandingPageState createState() => LandingPageState();
}


class LandingPageState extends State<LandingPage> {

  Iterable<Contact> _contacts;
  List<Numbers> phoneNumbers = new List();
  PhoneNumbers phoneNumbersType = PhoneNumbers();
  List<ValidUser> validUserList = new List();
  var validUserMap = new Map();

  @override
  void initState() {
    getContacts();
    print("got contacts");
    super.initState();
  }

  void loop(List<Contact> contactsList, List<Numbers> phoneNumbers) {
    for (int i=0; i< contactsList.length; i++) {
      String val = contactsList[i].phones.first.value.toString();
      print(val);
      phoneNumbers.add(Numbers(number: int.parse(val)));
    }
  }

  Future<void> getContacts() async {
    //Make sure we already have permissions for contacts when we get to this
    //page, so we can just retrieve it
    final Iterable<Contact> contacts = await ContactsService.getContacts();
    setState(() {
      _contacts = contacts;
      List<Contact> contactsList = _contacts.toList();
      loop(contactsList, phoneNumbers);
      phoneNumbersType = PhoneNumbers(phone : phoneNumbers);
      getRegisteredNumbers(phoneNumbersType);
    });
  }

  getRegisteredNumbers(PhoneNumbers phoneNumbersType){
    String url = 'https://gentle-bayou-08991.herokuapp.com/users/findActiveUsers';
    createPostUser(url, phoneNumbersType).then((response) => {
      print(response.body),
      if(response.statusCode == 200){
        setState(() {
          Iterable list = json.decode(response.body);
          validUserList = list.map((model) => ValidUser.fromJson(model)).toList();
          print(validUserList);
          validUserMap = validUserList.asMap();
          print(validUserMap[0].firstname.toString());
          int a =10;
        }),
      }
    });
  }

  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ListViews',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: Scaffold(
        appBar: AppBar(title: Text('Conversations')),
        body: ListView.builder(
          itemCount: validUserList.length,
          itemBuilder: (context, index) {
            return Card(
              child: ListTile(
                title: Text(validUserMap[index].firstname.toString()),
                leading: Icon(Icons.wb_sunny),
              ),
            );
          },
        ),
      ),
    );
  }
}

class BodyLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _myListView(context);
  }
}

// replace this function with the code in the examples
Widget _myListView(BuildContext context) {

  // backing data
  final europeanCountries = ['Albania', 'Andorra', 'Armenia', 'Austria',
    'Azerbaijan', 'Belarus', 'Belgium', 'Bosnia and Herzegovina', 'Bulgaria',
    'Croatia', 'Cyprus', 'Czech Republic', 'Denmark', 'Estonia', 'Finland',
    'France', 'Georgia', 'Germany', 'Greece', 'Hungary', 'Iceland', 'Ireland',
    'Italy', 'Kazakhstan', 'Kosovo', 'Latvia', 'Liechtenstein', 'Lithuania',
    'Luxembourg', 'Macedonia', 'Malta', 'Moldova', 'Monaco', 'Montenegro',
    'Netherlands', 'Norway', 'Poland', 'Portugal', 'Romania', 'Russia',
    'San Marino', 'Serbia', 'Slovakia', 'Slovenia', 'Spain', 'Sweden',
    'Switzerland', 'Turkey', 'Ukraine', 'United Kingdom', 'Vatican City'];

  return ListView.builder(
    itemCount: europeanCountries.length,
    itemBuilder: (context, index) {
      return ListTile(
        title: Text(europeanCountries[index]),
        leading: Icon(Icons.wb_sunny),
      );
    },
  );

}