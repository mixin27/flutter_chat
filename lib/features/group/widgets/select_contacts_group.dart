import 'package:chat_demo/common/widgets/error_screen.dart';
import 'package:chat_demo/common/widgets/loader.dart';
import 'package:chat_demo/features/contact/controller/select_contacts_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/contact.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final selectedGroupContactsProvider = StateProvider<List<Contact>>((ref) {
  return [];
});

class SelectContactsGroup extends ConsumerStatefulWidget {
  const SelectContactsGroup({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _SelectContactsGroupState();
}

class _SelectContactsGroupState extends ConsumerState<SelectContactsGroup> {
  List<int> selectedContactIndices = [];

  void selectContact(int index, Contact contact) {
    if (selectedContactIndices.contains(index)) {
      selectedContactIndices.removeAt(index);
    } else {
      selectedContactIndices.add(index);
    }

    setState(() {});

    ref
        .read(selectedGroupContactsProvider.notifier)
        .update((state) => [...state, contact]);
  }

  @override
  Widget build(BuildContext context) {
    return ref.watch(getContactsProvider).when(
          data: (contacts) => Expanded(
            child: ListView.builder(
              itemCount: contacts.length,
              itemBuilder: (context, index) {
                final contact = contacts.elementAt(index);
                return InkWell(
                  onTap: () => selectContact(index, contact),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(
                        contact.displayName,
                        style: const TextStyle(
                          fontSize: 18,
                        ),
                      ),
                      leading: selectedContactIndices.contains(index)
                          ? IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.done),
                            )
                          : null,
                    ),
                  ),
                );
              },
            ),
          ),
          error: (err, trace) => Expanded(
            child: ErrorScreen(error: err.toString()),
          ),
          loading: () => const Expanded(child: Loader()),
        );
  }
}
