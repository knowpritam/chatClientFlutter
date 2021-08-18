import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutterapp/globals.dart' as globals;
import 'package:flutterapp/persistance/SharedPreference.dart';

class PushNotificationsManager {

  PushNotificationsManager._();

  factory PushNotificationsManager() => _instance;

  static final PushNotificationsManager _instance = PushNotificationsManager._();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  bool _initialized = false;

  Future<void> init() async {
    if (!_initialized) {
      // For iOS request permission first.
      _firebaseMessaging.requestNotificationPermissions();
      _firebaseMessaging.configure();

      // For testing purposes print the Firebase Messaging token
      String token = await _firebaseMessaging.getToken();
      savePreference('notifToken', token);
      globals.notifToken = token;
      print("FirebaseMessaging token: $token");

      _initialized = true;
    }
  }
}