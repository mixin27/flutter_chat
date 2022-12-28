import 'package:chat_demo/common/enums/message_enum.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MessageReply {
  final String message;
  final bool isMe;
  final MessageEnum messageType;

  MessageReply(this.message, this.isMe, this.messageType);
}

final messageReplyProvider = StateProvider<MessageReply?>((ref) {
  return null;
});
