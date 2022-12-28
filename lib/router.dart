import 'dart:io';

import 'package:chat_demo/common/widgets/error_screen.dart';
import 'package:chat_demo/features/auth/screens/login_screen.dart';
import 'package:chat_demo/features/auth/screens/opt_screen.dart';
import 'package:chat_demo/features/auth/screens/user_information_screen.dart';
import 'package:chat_demo/features/contact/screens/select_contacts_screen.dart';
import 'package:chat_demo/features/chat/screens/mobile_chat_screen.dart';
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
      final name = arguments['name'];
      final uid = arguments['uid'];
      return MaterialPageRoute(
        builder: (context) => MobileChatScreen(name: name, uid: uid),
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
    default:
      return MaterialPageRoute(
        builder: (context) => const Scaffold(
          body: ErrorScreen(error: 'This page doesn\'t exist!'),
        ),
      );
  }
}
