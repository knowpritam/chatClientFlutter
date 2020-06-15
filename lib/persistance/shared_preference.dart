import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

Future<String> readPreference(var key) async {
  final prefs = await SharedPreferences.getInstance();
  final value = prefs.getString(key);
  print('read: $value');
  return value;
}

savePreference(var key, var value) async {
  final prefs = await SharedPreferences.getInstance();
  prefs.setString(key, value);
  print('saved $value');
}

__adfadfa(){

}