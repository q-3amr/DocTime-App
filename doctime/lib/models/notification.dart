import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  // دي class بتحتوي على ال attributes اللي بتوصف ال notification في التطبيق
  String? _id;
  String? _uid;
  String? _body;
  String? _name;
  String? _title;
  Timestamp? _time;

  Timestamp get time => _time!;
  String get title => _title!;
  String get name => _name!;
  String get body => _body!;
  String get uid => _uid!;
  String get id => _id!;

  NotificationModel.fromSnapshot(DocumentSnapshot snapshot) {
    // دي constructor بتاخد ال snapshot اللي جاي من ال Firestore وتعمل منه instance من ال NotificationModel عشان نقدر نستخدمه في التطبيق
    _id = snapshot.get("id");
    _time = snapshot.get("time");
    _name = snapshot.get("name");
    _uid = snapshot.get("uid");
    _title = snapshot.get("title");
    _body = snapshot.get("body");
  }
}
