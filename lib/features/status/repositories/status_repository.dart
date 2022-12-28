import 'dart:developer';
import 'dart:io';

import 'package:chat_demo/common/repositories/firebase_storage_repository.dart';
import 'package:chat_demo/common/utils/utils.dart';
import 'package:chat_demo/models/status_model.dart';
import 'package:chat_demo/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

final statusRepositoryProvider = Provider<StatusRepository>((ref) {
  return StatusRepository(
    firestore: FirebaseFirestore.instance,
    firebaseAuth: FirebaseAuth.instance,
    ref: ref,
  );
});

class StatusRepository {
  final FirebaseFirestore firestore;
  final FirebaseAuth firebaseAuth;
  final ProviderRef ref;

  StatusRepository({
    required this.firestore,
    required this.firebaseAuth,
    required this.ref,
  });

  void uploadStatus(
    BuildContext context, {
    required String userName,
    required String profilePic,
    required String phoneNumber,
    required File statusImage,
  }) async {
    try {
      var statusId = const Uuid().v1();
      String uid = firebaseAuth.currentUser!.uid;

      String imageUrl =
          await ref.read(firebaseStorageRepositoryProvider).storeFileToFirebase(
                ref: '/status/$statusId/$uid',
                file: statusImage,
              );

      List<Contact> contacts = [];
      if (await FlutterContacts.requestPermission()) {
        contacts = await FlutterContacts.getContacts(withProperties: true);
      }

      List<String> uidsWhonCanSee = [];
      for (var contact in contacts) {
        var userDataFirestore = await firestore
            .collection('users')
            .where(
              'phoneNumber',
              isEqualTo: contact.phones[0].number.replaceAll(' ', ''),
            )
            .get();

        if (userDataFirestore.docs.isNotEmpty) {
          var userData = UserModel.fromMap(userDataFirestore.docs.first.data());
          uidsWhonCanSee.add(userData.uid);
        }
      }

      List<String> statusImageUrls = [];
      var statusesSnapshot = await firestore
          .collection('status')
          .where('uid', isEqualTo: firebaseAuth.currentUser!.uid)
          .get();
      if (statusesSnapshot.docs.isNotEmpty) {
        StatusModel status = StatusModel.fromMap(
          statusesSnapshot.docs.first.data(),
        );
        statusImageUrls = status.photoUrl;
        statusImageUrls.add(imageUrl);
        await firestore
            .collection('status')
            .doc(statusesSnapshot.docs.first.id)
            .update({'photoUrl': statusImageUrls});
        return;
      } else {
        statusImageUrls = [imageUrl];
      }

      StatusModel status = StatusModel(
        uid: uid,
        userName: userName,
        phoneNumber: phoneNumber,
        photoUrl: statusImageUrls,
        createdAt: DateTime.now(),
        profilePic: profilePic,
        statusId: statusId,
        whoCanSee: uidsWhonCanSee,
      );

      await firestore.collection('status').doc(statusId).set(status.toMap());
    } catch (e) {
      log(e.toString());
      showSnackbar(context: context, content: e.toString());
    }
  }

  Future<List<StatusModel>> getStatus(BuildContext context) async {
    List<StatusModel> statusData = [];

    try {
      List<Contact> contacts = [];
      if (await FlutterContacts.requestPermission()) {
        contacts = await FlutterContacts.getContacts(withProperties: true);
      }

      final length = contacts.length;
      for (var i = 0; i < length; i++) {
        var statusesSanpshot = await firestore
            .collection('status')
            .where('phoneNumber',
                isEqualTo: contacts[i].phones.first.number.replaceAll(' ', ''))
            .where(
              'createdAt',
              isGreaterThan: DateTime.now()
                  .subtract(const Duration(hours: 24))
                  .millisecondsSinceEpoch,
            )
            .get();

        for (var temp in statusesSanpshot.docs) {
          StatusModel tempStatus = StatusModel.fromMap(temp.data());
          if (tempStatus.whoCanSee.contains(firebaseAuth.currentUser!.uid)) {
            statusData.add(tempStatus);
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      showSnackbar(context: context, content: e.toString());
    }

    return statusData;
  }
}
