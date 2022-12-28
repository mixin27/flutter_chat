import 'package:chat_demo/common/widgets/loader.dart';
import 'package:chat_demo/features/status/controller/status_controller.dart';
import 'package:chat_demo/features/status/screens/status_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StatusContactsScreen extends ConsumerWidget {
  const StatusContactsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder(
      future: ref.read(statusControllerProvider).getStatus(context),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Loader();
        }

        return ListView.builder(
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            var status = snapshot.data!.elementAt(index);
            return Column(
              children: [
                InkWell(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      StatusScreen.routeName,
                      arguments: status,
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: ListTile(
                        title: Text(
                          status.userName,
                          style: const TextStyle(fontSize: 18),
                        ),
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(
                            status.profilePic,
                          ),
                          radius: 30,
                        )),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
