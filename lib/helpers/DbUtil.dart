import 'package:flutterapp/globals.dart';
import 'package:flutterapp/helpers/DBHelper.dart';
import 'package:flutterapp/models/message.dart';

updateMessagesBulkToDelivered(data, Function onBulkMessagesDelivered) async{
  var db = new DatabaseHelper();
  await db.updateChatBulkMessagesStatus(data["fromId"], data["toId"]);
  onBulkMessagesDelivered();
}