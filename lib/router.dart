import 'dart:io';

import 'package:chat_demo/common/widgets/error_screen.dart';
import 'package:chat_demo/features/auth/screens/login_screen.dart';
import 'package:chat_demo/features/auth/screens/opt_screen.dart';
import 'package:chat_demo/features/auth/screens/user_information_screen.dart';
import 'package:chat_demo/features/contact/screens/select_contacts_screen.dart';
import 'package:chat_demo/features/chat/screens/mobile_chat_screen.dart';
import 'package:chat_demo/features/group/screens/create_group_screen.dart';
import 'package:chat_demo/features/status/screens/confirm_status_screen.dart';
import 'package:chat_demo/features/status/screens/status_screen.dart';
import 'package:chat_demo/models/status_model.dart';
import 'package:flutter/material.dart';

Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case LoginScreen.routeName:
      return MaterialPageRoute(builder: (context) => const LoginScreen());
    case OtpScreen.routeName:
      final verificationId = settings.arguments as String;
      return MaterialPageRoute(
        builder: (context) => OtpScreen(
          verificationId: verificationId,
        ),
      );
    case UserInformationScreen.routeName:
      return MaterialPageRoute(
        builder: (context) => const UserInformationScreen(),
      );
    case SelectContactsScreen.routeName:
      return MaterialPageRoute(
        builder: (context) => const SelectContactsScreen(),
      );
    case MobileChatScreen.routeName:
      final arguments = settings.arguments as Map<String, dynamic>;
      final name = arguments['name'] as String;
      final uid = arguments['uid'] as String;
      final isGroupChat = arguments['isGroupChat'] as bool;
      return MaterialPageRoute(
        builder: (context) => MobileChatScreen(
          name: name,
          uid: uid,
          isGroupChat: isGroupChat,
        ),
      );
    case ConfirmStatusScreen.routeName:
      final file = settings.arguments as File;
      return MaterialPageRoute(
        builder: (context) => ConfirmStatusScreen(file: file),
      );
    case StatusScreen.routeName:
      final status = settings.arguments as StatusModel;
      return MaterialPageRoute(
        builder: (context) => StatusScreen(status: status),
      );
    case CreateGroupScreen.routeName:
      return MaterialPageRoute(
        builder: (context) => const CreateGroupScreen(),
      );
    default:
      return MaterialPageRoute(
        builder: (context) => const Scaffold(
          body: ErrorScreen(error: 'This page doesn\'t exist!'),
        ),
      );
  }
}
