import 'package:chat_demo/common/utils/utils.dart';
import 'package:chat_demo/models/user_model.dart';
import 'package:chat_demo/screens/mobile_chat_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final selectContactsRepositoryProvider =
    Provider<SelectContactsRepository>((ref) {
  return SelectContactsRepository(firestore: FirebaseFirestore.instance);
});

class SelectContactsRepository {
  final FirebaseFirestore firestore;

  SelectContactsRepository({required this.firestore});

  Future<List<Contact>> getContacts() async {
    List<Contact> contacts = [];
    try {
      if (await FlutterContacts.requestPermission()) {
        contacts = await FlutterContacts.getContacts(withProperties: true);
      }

      return contacts;
    } catch (e) {
      debugPrint(e.toString());
      return [];
    }
  }

  void selectContact(
    BuildContext context, {
    required Contact contact,
  }) async {
    try {
      var userCollection = await firestore.collection('users').get();
      bool isFound = false;

      for (var document in userCollection.docs) {
        var userData = UserModel.fromMap(document.data());

        String selectedPhoneNumber =
            contact.phones.first.number.replaceAll(' ', '');

        if (selectedPhoneNumber == userData.phoneNumber) {
          isFound = true;
          Future.delayed(Duration.zero).then((value) {
            Navigator.pushNamed(context, MobileChatScreen.routeName);
          });
        }

        if (!isFound) {
          showSnackbar(
            context: context,
            content: 'This number does not exist on the app.',
          );
        }
      }
    } catch (e) {
      showSnackbar(context: context, content: e.toString());
    }
  }
}
