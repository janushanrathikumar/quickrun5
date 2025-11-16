import 'package:flutter/material.dart';

import 'package:quickrun5/auth/login_view.dart';
import 'package:quickrun5/auth/signup_screen.dart';
import 'package:quickrun5/common/color_extension.dart';
import 'package:quickrun5/common_widget/round_button.dart';

import 'package:quickrun5/view/admin2/admin_login_view.dart';

class WelcomeView extends StatefulWidget {
  const WelcomeView({super.key});

  @override
  State<WelcomeView> createState() => _WelcomeViewState();
}

class _WelcomeViewState extends State<WelcomeView> {
  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        height: media.height, // Ensure the container takes full screen height
        width: media.width, // Ensure the container takes full screen width
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
              "assets/img/splash_bg.png",
            ), // Your background image
            fit: BoxFit.cover,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: media.width * 0.5), // Adjust spacing
              Text(
                "Quick Run",
                style: TextStyle(
                  fontSize: media.width * 0.1, // Adjust font size as needed
                  color: Color.fromARGB(255, 15, 15, 15),
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(
                height: media.width * 0.5,
                child: Image.asset(
                  "assets/pic/logo.png", // Replace with your logo image path
                  fit: BoxFit.contain, // Adjust the fit as needed
                ),
              ),
              SizedBox(height: media.width * 0.05), // Adjust spacing
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: RoundButton(
                  title: "Login",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginView(),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: media.width * 0.1), // Adjust spacing
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: RoundButton(
                  title: "Sign up",
                  type: RoundButtonType.textPrimary,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SignupScreen(),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 40),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminLoginView(),
                    ),
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Admin Login ",
                      style: TextStyle(
                        color: TColor.secondaryText,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      "Admin Login",
                      style: TextStyle(
                        color: TColor.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
