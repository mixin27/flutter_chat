import 'package:chat_demo/features/contact/repositories/select_contacts_repository.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_contacts/contact.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final getContactsProvider = FutureProvider<List<Contact>>((ref) async {
  final selectContactsRepository = ref.watch(selectContactsRepositoryProvider);
  return selectContactsRepository.getContacts();
});

final selectContactsControllerProvider =
    Provider<SelectContactsController>((ref) {
  return SelectContactsController(
    ref: ref,
    selectContactsRepository: ref.watch(selectContactsRepositoryProvider),
  );
});

class SelectContactsController {
  final ProviderRef ref;
  final SelectContactsRepository selectContactsRepository;

  SelectContactsController({
    required this.ref,
    required this.selectContactsRepository,
  });

  void selectContact(
    BuildContext context, {
    required Contact contact,
  }) {
    selectContactsRepository.selectContact(context, contact: contact);
  }
}
