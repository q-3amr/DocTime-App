import 'package:flutter/foundation.dart';

import '../services/message.dart';

class NotificationProvider with ChangeNotifier {
  MessageServices _messageServices = MessageServices();

  NotificationProvider() {
    notifyListeners();
  }

  Future<void> sendNotificationToUser(
      {String? fcmToken, String? title, String? body}) async {
    await _messageServices.sendNotificationToUser(
      body: body,
      fcmToken: fcmToken,
      title: title,
    );
  }

  Future<void> sendNotificationToGroup(
      String group, String title, String body) async {
    await _messageServices.sendNotificationToGroup(
      body: body,
      group: group,
      title: title,
    );
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _messageServices.unsubscribeFromTopic(
      topic: topic,
    );
  }

  Future<void> subscribeToTopic(String topic) async {
    await _messageServices.subscribeToTopic(
      topic: topic,
    );
  }
}
