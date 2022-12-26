import 'package:chat_demo/colors.dart';
import 'package:chat_demo/features/auth/controller/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OtpScreen extends ConsumerWidget {
  static const String routeName = '/otp-page';
  const OtpScreen({super.key, required this.verificationId});

  final String verificationId;

  void verifyOtp(BuildContext context, String otpCode, WidgetRef ref) {
    ref
        .read(authControllerProvider)
        .verifyOtp(context, verificationId: verificationId, otpCode: otpCode);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify your number'),
        elevation: 0,
        backgroundColor: backgroundColor,
      ),
      body: Center(
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text('We have sent a SMS with a code'),
            SizedBox(
              width: size.width * 0.5,
              child: TextField(
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  hintText: '- - - - - - ',
                  hintStyle: TextStyle(fontSize: 30),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  if (value.length == 6) {
                    verifyOtp(context, value.trim(), ref);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
