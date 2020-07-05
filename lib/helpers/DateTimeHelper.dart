import 'package:intl/intl.dart';

// Gets current time to be shown in chat UI
String getCurrentTime() {
  var now = new DateTime.now();
  var formatter = new DateFormat.Hm();
  String formattedTime = formatter.format(now);
  return formattedTime;
}

String convertUTCToIST(var utcDateTime){
  String utcDate = utcDateTime.toString().substring(0, 10);
  String utcTime = utcDateTime.toString().substring(11, 19);
  var dateTime = DateFormat("yyyy-MM-dd HH:mm:ss").parse(utcDate+' '+utcTime, true);
  var dateLocal = dateTime.toLocal();
  print(dateLocal);
  return convertDateTimeToReadableFormat(dateLocal);
}

String convertDateTimeToReadableFormat(var dateLocal){
  String dateLocalString = dateLocal.toString();
  String formattedDate ;
  DateTime now = DateTime.now();
  String formattedNowDate = DateFormat('MM-dd').format(now);
  String date = dateLocalString.substring(8,10);
  String month = dateLocalString.substring(5,7);
  String time = dateLocalString.substring(11, 16);

  String currentDate = formattedNowDate.substring(3,5);
  String currentMon = formattedNowDate.substring(0,2);

  if(date == currentDate && month == currentMon){
    formattedDate = "today at "+time;
  }
  else{
    formattedDate = DateFormat('EEE d MMM kk:mm').format(dateLocal);
  }
  return "last seen "+formattedDate;
}