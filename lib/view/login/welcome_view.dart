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
  // Defining the red color from the logo locally for this view
  // You can also move this to your TColor class later
  final Color primaryRed = const Color(0xFFCD1C1C);

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white, // Set background to white to match logo
      body: SizedBox(
        height: media.height,
        width: media.width,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Spacing from top
              SizedBox(height: media.height * 0.15),

              // Logo Image
              SizedBox(
                height: media.width * 0.6, // Increased size slightly for impact
                width: media.width * 0.8,
                child: Image.asset("assets/pic/logo.png", fit: BoxFit.contain),
              ),

              // Text Title (Optional: If your logo image already has text, remove this widget)
              SizedBox(height: media.height * 0.08), // Spacing before buttons
              // Login Button (Red Background)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: RoundButton(
                  title: "Login",
                  // Assuming your RoundButton accepts a color property
                  // If not, ensure TColor.primary is set to this red in your extension
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

              const SizedBox(height: 20),

              // Sign Up Button (Red Text / Outline)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: RoundButton(
                  title: "Sign up",
                  type:
                      RoundButtonType.textPrimary, // Ensures outline/text style
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

              const SizedBox(height: 40),

              // Admin Login Link
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
                      "Go to ",
                      style: TextStyle(
                        color: TColor.secondaryText,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      "Admin Login",
                      style: TextStyle(
                        color: primaryRed, // Use the logo red
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom padding
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
