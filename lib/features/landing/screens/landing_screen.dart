import 'package:chat_demo/colors.dart';
import 'package:chat_demo/common/widgets/custom_button.dart';
import 'package:flutter/material.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: SizedBox(
          width: size.width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 50),
              const Text(
                'Welcome to Chatt',
                style: TextStyle(
                  fontSize: 33,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: size.height / 9),
              Image.asset(
                "assets/images/landing-bg.png",
                height: 340,
                width: 340,
                color: tabColor,
              ),
              SizedBox(height: size.height / 9),
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  'Read our Privacy Policy. Tap "Agree and continue" to accept the Terms of Service.',
                  style: TextStyle(color: greyColor),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: size.width * 0.75,
                child: CustomButton(
                  text: "Accept And Continue".toUpperCase(),
                  onTap: () {},
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
