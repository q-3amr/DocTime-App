import 'package:uuid/uuid.dart';

enum MessageSender { user, bot }

class ChatMessage {
  final String id;
  final String text;
  final MessageSender sender;
  final DateTime timestamp;

  ChatMessage({
    String? id,
    required this.text,
    required this.sender,
    DateTime? timestamp,
  })  : id = id ?? Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  bool get isUser => sender == MessageSender.user;
}
