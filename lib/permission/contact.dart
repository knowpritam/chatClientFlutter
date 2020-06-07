import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/cupertino.dart';

void getContactAccess() async{
    //return await _getPermission();
    final PermissionHandler _permissionHandler = PermissionHandler();
    await _permissionHandler.requestPermissions([PermissionGroup.contacts]);
  }
Future<bool> checkContactAccess() async {
  final PermissionHandler _permissionHandler = PermissionHandler();
  await _permissionHandler.requestPermissions([PermissionGroup.contacts]);
  var permissionStatus = await _permissionHandler.checkPermissionStatus(PermissionGroup.contacts);
  if(permissionStatus == PermissionStatus.granted){
    return true;
  }
  else return false;
}
//  //Check contacts permission
//  Future<PermissionStatus> _getPermission() async {
//    final PermissionStatus permission = await Permission.contacts.status;
//    if (permission != PermissionStatus.granted &&
//        permission != PermissionStatus.denied) {
//      final Map<Permission, PermissionStatus> permissionStatus =
//      await [Permission.contacts].request();
//      return permissionStatus[Permission.contacts] ??
//          PermissionStatus.undetermined;
//    } else {
//      return permission;
//    }
//  }

