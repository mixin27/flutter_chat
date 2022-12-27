import 'package:chat_demo/common/enums/message_enum.dart';
import 'package:chat_demo/common/utils/utils.dart';
import 'package:chat_demo/models/chat_contact.dart';
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

  void _saveDataToContactsSubCollection(
    UserModel sender,
    UserModel receiver,
    String text,
    DateTime timeSent,
    String receiverUserId,
  ) async {
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
      name: receiver.name,
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

  void _saveMessageToMessageSubCollection({
    required String receiverUserId,
    required String text,
    required DateTime timeSent,
    required String messageId,
    required String senderUserName,
    required String receiverUserName,
    required MessageEnum messageType,
  }) async {
    final message = Message(
      senderId: firebaseAuth.currentUser!.uid,
      receiverId: receiverUserId,
      text: text,
      type: messageType,
      timeSent: timeSent,
      messageId: messageId,
      isSeen: false,
    );

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

  void sendTextMessage(
    BuildContext context, {
    required String text,
    required String receiverUserId,
    required UserModel senderUser,
  }) async {
    // users -> sender id -> receiver id -> messages -> message id -> message
    try {
      var timeSent = DateTime.now();
      var userDataMap =
          await firestore.collection('users').doc(receiverUserId).get();
      UserModel receiverUserData = UserModel.fromMap(userDataMap.data()!);

      var messageId = const Uuid().v1();

      _saveDataToContactsSubCollection(
        senderUser,
        receiverUserData,
        text,
        timeSent,
        receiverUserId,
      );

      _saveMessageToMessageSubCollection(
        receiverUserId: receiverUserId,
        text: text,
        timeSent: timeSent,
        messageId: messageId,
        senderUserName: senderUser.name,
        receiverUserName: receiverUserData.name,
        messageType: MessageEnum.text,
      );
    } catch (e) {
      showSnackbar(context: context, content: e.toString());
    }
  }
}
