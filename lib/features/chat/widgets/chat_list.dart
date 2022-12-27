import 'package:chat_demo/common/widgets/loader.dart';
import 'package:chat_demo/features/chat/controller/chat_controller.dart';
import 'package:chat_demo/models/message.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'my_message_card.dart';
import 'sender_message_card.dart';

class ChatList extends ConsumerStatefulWidget {
  const ChatList({super.key, required this.receiverUserId});

  final String receiverUserId;

  @override
  ConsumerState<ChatList> createState() => _ChatListState();
}

class _ChatListState extends ConsumerState<ChatList> {
  final ScrollController scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Message>>(
        stream:
            ref.read(chatControllerProvider).chatStream(widget.receiverUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Loader();
          }

          SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
            scrollController.animateTo(
              scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
            );
            // scrollController.jumpTo(scrollController.position.maxScrollExtent);
          });

          return ListView.builder(
            controller: scrollController,
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final message = snapshot.data!.elementAt(index);
              final timeSent = DateFormat.Hm().format(message.timeSent);

              if (message.senderId == FirebaseAuth.instance.currentUser!.uid) {
                return MyMessageCard(
                  message: message.text,
                  date: timeSent,
                  type: message.type,
                );
              }
              return SenderMessageCard(
                message: message.text,
                date: timeSent,
                type: message.type,
              );
            },
          );
        });
  }
}
