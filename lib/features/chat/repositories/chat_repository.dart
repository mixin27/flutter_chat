import 'dart:io';

import 'package:chat_demo/common/enums/message_enum.dart';
import 'package:chat_demo/common/providers/message_reply_provider.dart';
import 'package:chat_demo/common/repositories/firebase_storage_repository.dart';
import 'package:chat_demo/common/utils/utils.dart';
import 'package:chat_demo/models/chat_contact.dart';
import 'package:chat_demo/models/group.dart';
import 'package:chat_demo/models/message.dart';
import 'package:chat_demo/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(
    firestore: FirebaseFirestore.instance,
    firebaseAuth: FirebaseAuth.instance,
  );
});

class ChatRepository {
  final FirebaseFirestore firestore;
  final FirebaseAuth firebaseAuth;

  ChatRepository({required this.firestore, required this.firebaseAuth});

  Stream<List<ChatContact>> getChatContacts() {
    return firestore
        .collection('users')
        .doc(firebaseAuth.currentUser!.uid)
        .collection('chats')
        .snapshots()
        .asyncMap((event) async {
      List<ChatContact> contacts = [];
      for (var document in event.docs) {
        var chatContact = ChatContact.fromMap(document.data());
        var userData = await firestore
            .collection('users')
            .doc(chatContact.contactId)
            .get();
        var user = UserModel.fromMap(userData.data()!);

        contacts.add(
          ChatContact(
            name: user.name,
            profilePic: user.profilePic,
            contactId: chatContact.contactId,
            timeSent: chatContact.timeSent,
            lastMessage: chatContact.lastMessage,
          ),
        );
      }
      return contacts;
    });
  }

  Stream<List<GroupModel>> getChatGroupContacts() {
    return firestore.collection('groups').snapshots().asyncMap((event) async {
      List<GroupModel> groups = [];
      for (var document in event.docs) {
        var group = GroupModel.fromMap(document.data());

        if (group.memberUids.contains(firebaseAuth.currentUser!.uid)) {
          groups.add(group);
        }
      }
      return groups;
    });
  }

  Stream<List<Message>> getChatStream(String receiverUserId) {
    return firestore
        .collection('users')
        .doc(firebaseAuth.currentUser!.uid)
        .collection('chats')
        .doc(receiverUserId)
        .collection('messages')
        .orderBy('timeSent')
        .snapshots()
        .asyncMap((event) async {
      List<Message> messages = [];
      for (var document in event.docs) {
        messages.add(Message.fromMap(document.data()));
      }
      return messages;
    });
  }

  Stream<List<Message>> getGroupChatStream(String groupId) {
    return firestore
        .collection('groups')
        .doc(groupId)
        .collection('chats')
        .orderBy('timeSent')
        .snapshots()
        .asyncMap((event) async {
      List<Message> messages = [];
      for (var document in event.docs) {
        messages.add(Message.fromMap(document.data()));
      }
      return messages;
    });
  }

  void _saveDataToContactsSubCollection(
    UserModel sender,
    UserModel? receiver,
    String text,
    DateTime timeSent,
    String receiverUserId,
    bool isGroupChat,
  ) async {
    if (isGroupChat) {
      await firestore.collection('groups').doc(receiverUserId).update({
        'lastMessage': text,
        'timeSent': DateTime.now().millisecondsSinceEpoch,
      });
    } else {
      // users -> receiver user id -> chats -> current user id -> set data
      var receiverChatContact = ChatContact(
        name: sender.name,
        profilePic: sender.profilePic,
        contactId: sender.uid,
        timeSent: timeSent,
        lastMessage: text,
      );
      await firestore
          .collection('users')
          .doc(receiverUserId)
          .collection('chats')
          .doc(firebaseAuth.currentUser!.uid)
          .set(receiverChatContact.toMap());

      // users -> current user id -> chats -> receiver user id -> set data
      var senderChatContact = ChatContact(
        name: receiver!.name,
        profilePic: receiver.profilePic,
        contactId: receiver.uid,
        timeSent: timeSent,
        lastMessage: text,
      );
      await firestore
          .collection('users')
          .doc(firebaseAuth.currentUser!.uid)
          .collection('chats')
          .doc(receiverUserId)
          .set(senderChatContact.toMap());
    }
  }

  void _saveMessageToMessageSubCollection({
    required String receiverUserId,
    required String text,
    required DateTime timeSent,
    required String messageId,
    required String senderUserName,
    required String senderProfilePic,
    required String? receiverUserName,
    required MessageEnum messageType,
    required MessageReply? messageReply,
    required MessageEnum repliedMessageType,
    required bool isGroupChat,
  }) async {
    final message = Message(
      senderId: firebaseAuth.currentUser!.uid,
      senderProfilePic: senderProfilePic,
      receiverId: receiverUserId,
      text: text,
      type: messageType,
      timeSent: timeSent,
      messageId: messageId,
      isSeen: false,
      repliedMessage: messageReply == null ? '' : messageReply.message,
      repliedTo: messageReply == null
          ? ''
          : messageReply.isMe
              ? senderUserName
              : receiverUserName ?? '',
      repliedMessageType: repliedMessageType,
    );

    if (isGroupChat) {
      // groups -> group id -> chats -> message
      await firestore
          .collection('groups')
          .doc(receiverUserId)
          .collection('chats')
          .doc(messageId)
          .set(message.toMap());
    } else {
      // users -> sender id -> receiver id -> messages -> message id -> message
      await firestore
          .collection('users')
          .doc(firebaseAuth.currentUser!.uid)
          .collection('chats')
          .doc(receiverUserId)
          .collection('messages')
          .doc(messageId)
          .set(message.toMap());
      // users -> receiver id -> sender id -> messages -> message id -> message
      await firestore
          .collection('users')
          .doc(receiverUserId)
          .collection('chats')
          .doc(firebaseAuth.currentUser!.uid)
          .collection('messages')
          .doc(messageId)
          .set(message.toMap());
    }
  }

  void sendTextMessage(
    BuildContext context, {
    required String text,
    required String receiverUserId,
    required UserModel senderUser,
    MessageReply? messageReply,
    required bool isGroupChat,
  }) async {
    // users -> sender id -> receiver id -> messages -> message id -> message
    try {
      var timeSent = DateTime.now();
      UserModel? receiverUserData;

      if (!isGroupChat) {
        var userDataMap =
            await firestore.collection('users').doc(receiverUserId).get();
        receiverUserData = UserModel.fromMap(userDataMap.data()!);
      }

      var messageId = const Uuid().v1();

      _saveDataToContactsSubCollection(
        senderUser,
        receiverUserData,
        text,
        timeSent,
        receiverUserId,
        isGroupChat,
      );

      _saveMessageToMessageSubCollection(
        receiverUserId: receiverUserId,
        text: text,
        timeSent: timeSent,
        messageId: messageId,
        senderUserName: senderUser.name,
        senderProfilePic: senderUser.profilePic,
        receiverUserName: receiverUserData?.name,
        messageType: MessageEnum.text,
        messageReply: messageReply,
        repliedMessageType:
            messageReply == null ? MessageEnum.text : messageReply.messageType,
        isGroupChat: isGroupChat,
      );
    } catch (e) {
      showSnackbar(context: context, content: e.toString());
    }
  }

  void sendFileMessage(
    BuildContext context, {
    required File file,
    required String receiverUserId,
    required UserModel senderUser,
    required ProviderRef ref,
    required MessageEnum messageType,
    MessageReply? messageReply,
    required bool isGroupChat,
  }) async {
    try {
      var timeSent = DateTime.now();
      var messageId = const Uuid().v1();

      String fileUrl =
          await ref.read(firebaseStorageRepositoryProvider).storeFileToFirebase(
                ref:
                    'chat/${messageType.type}/${senderUser.uid}/$receiverUserId/$messageId',
                file: file,
              );

      UserModel? receiverUserData;

      if (!isGroupChat) {
        var userDataMap =
            await firestore.collection('users').doc(receiverUserId).get();
        receiverUserData = UserModel.fromMap(userDataMap.data()!);
      }

      String contactMessage;
      switch (messageType) {
        case MessageEnum.image:
          contactMessage = '📷 Photo';
          break;
        case MessageEnum.video:
          contactMessage = '📸 Video';
          break;
        case MessageEnum.audio:
          contactMessage = '🎵 Audio';
          break;
        case MessageEnum.gif:
          contactMessage = 'GIF';
          break;
        default:
          contactMessage = 'GIF';
          break;
      }

      _saveDataToContactsSubCollection(
        senderUser,
        receiverUserData,
        contactMessage,
        timeSent,
        receiverUserId,
        isGroupChat,
      );

      _saveMessageToMessageSubCollection(
        receiverUserId: receiverUserId,
        text: fileUrl,
        timeSent: timeSent,
        messageId: messageId,
        senderUserName: senderUser.name,
        senderProfilePic: senderUser.profilePic,
        receiverUserName: receiverUserData?.name,
        messageType: messageType,
        messageReply: messageReply,
        repliedMessageType:
            messageReply == null ? MessageEnum.text : messageReply.messageType,
        isGroupChat: isGroupChat,
      );
    } catch (e) {
      showSnackbar(context: context, content: e.toString());
    }
  }

  void sendGifMessage(
    BuildContext context, {
    required String gifUrl,
    required String receiverUserId,
    required UserModel senderUser,
    MessageReply? messageReply,
    required bool isGroupChat,
  }) async {
    // users -> sender id -> receiver id -> messages -> message id -> message
    try {
      var timeSent = DateTime.now();

      UserModel? receiverUserData;
      if (!isGroupChat) {
        var userDataMap =
            await firestore.collection('users').doc(receiverUserId).get();
        receiverUserData = UserModel.fromMap(userDataMap.data()!);
      }

      var messageId = const Uuid().v1();

      _saveDataToContactsSubCollection(
        senderUser,
        receiverUserData,
        'GIF',
        timeSent,
        receiverUserId,
        isGroupChat,
      );

      _saveMessageToMessageSubCollection(
        receiverUserId: receiverUserId,
        text: gifUrl,
        timeSent: timeSent,
        messageId: messageId,
        senderUserName: senderUser.name,
        senderProfilePic: senderUser.profilePic,
        receiverUserName: receiverUserData?.name,
        messageType: MessageEnum.gif,
        messageReply: messageReply,
        repliedMessageType:
            messageReply == null ? MessageEnum.text : messageReply.messageType,
        isGroupChat: isGroupChat,
      );
    } catch (e) {
      showSnackbar(context: context, content: e.toString());
    }
  }

  void setChatMessageSeen(
    BuildContext context, {
    required String receiverUserId,
    required String messageId,
  }) async {
    try {
      await firestore
          .collection('users')
          .doc(firebaseAuth.currentUser!.uid)
          .collection('chats')
          .doc(receiverUserId)
          .collection('messages')
          .doc(messageId)
          .update({'isSeen': true});

      await firestore
          .collection('users')
          .doc(receiverUserId)
          .collection('chats')
          .doc(firebaseAuth.currentUser!.uid)
          .collection('messages')
          .doc(messageId)
          .update({'isSeen': true});
    } catch (e) {
      showSnackbar(context: context, content: e.toString());
    }
  }
}
