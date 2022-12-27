import 'package:chat_demo/features/auth/controller/auth_controller.dart';
import 'package:chat_demo/models/chat_contact.dart';
import 'package:chat_demo/models/message.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chat_demo/features/chat/repositories/chat_repository.dart';

final chatControllerProvider = Provider<ChatController>((ref) {
  return ChatController(
    chatRepository: ref.watch(chatRepositoryProvider),
    ref: ref,
  );
});

class ChatController {
  final ChatRepository chatRepository;
  final ProviderRef ref;

  ChatController({
    required this.chatRepository,
    required this.ref,
  });

  Stream<List<ChatContact>> chatContacts() => chatRepository.getChatContacts();

  Stream<List<Message>> chatStream(String receiverUserId) =>
      chatRepository.getChatStream(receiverUserId);

  void sendTextMessage(
    BuildContext context, {
    required String text,
    required String receiverUserId,
  }) {
    ref.read(userDataProvider).whenData((value) {
      chatRepository.sendTextMessage(
        context,
        text: text,
        receiverUserId: receiverUserId,
        senderUser: value!,
      );
    });
  }
}
