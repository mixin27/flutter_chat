import 'dart:io';

import 'package:chat_demo/features/auth/repository/auth_repository.dart';
import 'package:chat_demo/models/user_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authControllerProvider = Provider<AuthController>((ref) {
  return AuthController(
      authRepository: ref.watch(authRepositoryProvider), ref: ref);
});

final userDataProvider = FutureProvider<UserModel?>((ref) async {
  final authController = ref.watch(authControllerProvider);
  return authController.getUserData();
});

class AuthController {
  final AuthRepository authRepository;
  final ProviderRef ref;

  AuthController({required this.authRepository, required this.ref});

  Future<UserModel?> getUserData() async {
    return await authRepository.getCurrentUserData();
  }

  void signInWithPhone(BuildContext context, {required String phoneNumber}) {
    authRepository.signInWithPhone(context, phoneNumber: phoneNumber);
  }

  void verifyOtp(
    BuildContext context, {
    required String verificationId,
    required String otpCode,
  }) {
    authRepository.verifyOtp(
      context,
      verificationId: verificationId,
      otpCode: otpCode,
    );
  }

  void saveUserDataToFirebase(
    BuildContext context, {
    required String name,
    File? profilePic,
  }) {
    authRepository.saveUserDataToFirebase(
      context,
      name: name,
      ref: ref,
      profilePic: profilePic,
    );
  }

  Stream<UserModel> userDataById(String userId) {
    return authRepository.userData(userId);
  }

  void setUserState(bool isOnline) => authRepository.setUserState(isOnline);
}
