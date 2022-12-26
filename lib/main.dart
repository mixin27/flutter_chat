import 'package:chat_demo/colors.dart';
import 'package:chat_demo/common/widgets/error_screen.dart';
import 'package:chat_demo/common/widgets/loader.dart';
import 'package:chat_demo/features/auth/controller/auth_controller.dart';
import 'package:chat_demo/features/landing/screens/landing_screen.dart';
import 'package:chat_demo/firebase_options.dart';
import 'package:chat_demo/router.dart';
import 'package:chat_demo/screens/mobile_layout_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Whatsapp UI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: backgroundColor,
        appBarTheme: const AppBarTheme(
          color: appBarColor,
        ),
      ),
      onGenerateRoute: (settings) => generateRoute(settings),
      home: ref.watch(userDataProvider).when(
            data: (user) => user == null
                ? const LandingScreen()
                : const MobileLayoutScreen(),
            error: (error, stackTrace) => ErrorScreen(error: error.toString()),
            loading: () => const Loader(),
          ),
    );
  }
}
