import 'dart:io';

import 'package:chat_demo/features/auth/controller/auth_controller.dart';
import 'package:chat_demo/models/status_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chat_demo/features/status/repositories/status_repository.dart';

final statusControllerProvider = Provider<StatusController>((ref) {
  return StatusController(
    statusRepository: ref.watch(statusRepositoryProvider),
    ref: ref,
  );
});

class StatusController {
  final StatusRepository statusRepository;
  final ProviderRef ref;

  StatusController({
    required this.statusRepository,
    required this.ref,
  });

  void addStatus(
    BuildContext context, {
    required File file,
  }) {
    ref.watch(userDataProvider).whenData((value) {
      statusRepository.uploadStatus(
        context,
        userName: value!.name,
        profilePic: value.profilePic,
        phoneNumber: value.phoneNumber,
        statusImage: file,
      );
    });
  }

  Future<List<StatusModel>> getStatus(BuildContext context) async {
    List<StatusModel> statuses = await statusRepository.getStatus(context);
    return statuses;
  }
}
