import 'dart:io';

import 'package:chat_demo/common/repositories/firebase_storage_repository.dart';
import 'package:chat_demo/common/utils/utils.dart';
import 'package:chat_demo/features/auth/screens/opt_screen.dart';
import 'package:chat_demo/features/auth/screens/user_information_screen.dart';
import 'package:chat_demo/models/user_model.dart';
import 'package:chat_demo/screens/mobile_layout_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    firebaseAuth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
  );
});

class AuthRepository {
  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firestore;

  AuthRepository({required this.firebaseAuth, required this.firestore});

  Future<UserModel?> getCurrentUserData() async {
    var userData = await firestore
        .collection('users')
        .doc(firebaseAuth.currentUser?.uid)
        .get();

    if (userData.data() != null) {
      UserModel user = UserModel.fromMap(userData.data()!);
      return user;
    }

    return null;
  }

  void signInWithPhone(
    BuildContext context, {
    required String phoneNumber,
  }) async {
    try {
      await firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (credential) async {
          await firebaseAuth.signInWithCredential(credential);
        },
        verificationFailed: (e) {
          throw Exception(e);
        },
        codeSent: ((String verificationId, int? resendToken) async {
          Navigator.pushNamed(
            context,
            OtpScreen.routeName,
            arguments: verificationId,
          );
        }),
        codeAutoRetrievalTimeout: (verificationId) {},
      );
    } on FirebaseAuthException catch (e) {
      showSnackbar(
        context: context,
        content: e.message ?? "Unknown firebase error!",
      );
    }
  }

  void verifyOtp(
    BuildContext context, {
    required String verificationId,
    required String otpCode,
  }) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otpCode,
      );
      await firebaseAuth.signInWithCredential(credential);

      Future.delayed(Duration.zero).then((value) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          UserInformationScreen.routeName,
          (route) => false,
        );
      });
    } on FirebaseAuthException catch (e) {
      showSnackbar(
        context: context,
        content: e.message ?? 'Unknown firebase exception!',
      );
    }
  }

  void saveUserDataToFirebase(
    BuildContext context, {
    required String name,
    File? profilePic,
    required ProviderRef ref,
  }) async {
    try {
      String uid = firebaseAuth.currentUser!.uid;
      String photoUrl =
          'https://uploads.dailydot.com/2018/10/olli-the-polite-cat.jpg?auto=compress%2Cformat&ixlib=php-3.3.0';

      if (profilePic != null) {
        photoUrl = await ref
            .read(firebaseStorageRepositoryProvider)
            .storeFileToFirebase(ref: 'profilePic/$uid', file: profilePic);
      }

      var user = UserModel(
        name: name,
        uid: uid,
        profilePic: photoUrl,
        isOnline: true,
        phoneNumber: firebaseAuth.currentUser!.phoneNumber!,
        groups: [],
      );

      await firestore.collection('users').doc(uid).set(user.toMap());

      Future.delayed(Duration.zero).then((value) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MobileLayoutScreen()),
          (route) => false,
        );
      });
    } on FirebaseException catch (e) {
      showSnackbar(
        context: context,
        content: e.message ?? 'Unknown firebase exception!',
      );
    } catch (e) {
      showSnackbar(context: context, content: e.toString());
    }
  }

  Stream<UserModel> userData(String userId) {
    return firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((event) => UserModel.fromMap(event.data()!));
  }

  void setUserState(bool isOnline) async {
    await firestore
        .collection('users')
        .doc(firebaseAuth.currentUser!.uid)
        .update({
      'isOnline': isOnline,
    });
  }
}
