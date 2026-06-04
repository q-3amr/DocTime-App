import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
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
    _id = snapshot.get("id");
    _time = snapshot.get("time");
    _name = snapshot.get("name");
    _uid = snapshot.get("uid");
    _title = snapshot.get("title");
    _body = snapshot.get("body");
  }
}
