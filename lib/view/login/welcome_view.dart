import 'package:flutter/material.dart';
import 'package:quickrun5/auth/login_view.dart';
import 'package:quickrun5/auth/signup_screen.dart';
import 'package:quickrun5/common/color_extension.dart';
import 'package:quickrun5/common_widget/round_button.dart';
import 'package:quickrun5/view/admin2/admin_login_view.dart';
import 'package:quickrun5/translation.dart'; // NEW: Import localization file
import 'package:provider/provider.dart'; // REQUIRED for LocaleNotifier state
import 'package:quickrun5/view/user/user_location_view.dart'; // NEW: Import Map Screen

class WelcomeView extends StatefulWidget {
  const WelcomeView({super.key});

  @override
  State<WelcomeView> createState() => _WelcomeViewState();
}

class _WelcomeViewState extends State<WelcomeView> {
  final Color primaryRed = const Color(0xFFCD1C1C);

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;

    // Access the localization and state management
    // Ensure the AppLocalizations.of(context) returns a non-null value by
    // configuring localization delegates in MaterialApp.
    final loc = AppLocalizations.of(context)!;
    final localeNotifier = context.watch<LocaleNotifier>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          // --- Language Dropdown Menu (Top Right) ---
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: DropdownButton<Locale>(
              value: localeNotifier.locale,
              icon: const Icon(Icons.language, color: Colors.black54),
              underline: const SizedBox(),
              onChanged: (Locale? newLocale) {
                if (newLocale != null) {
                  // Update the locale via the notifier
                  localeNotifier.setLocale(newLocale);
                }
              },
              items: AppLocalizations.supportedLocales
                  .map<DropdownMenuItem<Locale>>((Locale locale) {
                    // Display the native language name in the menu
                    String languageName = locale.languageCode == 'de'
                        ? 'Deutsch'
                        : 'English';

                    return DropdownMenuItem<Locale>(
                      value: locale,
                      child: Text(
                        languageName,
                        style: const TextStyle(fontSize: 14),
                      ),
                    );
                  })
                  .toList(),
            ),
          ),
          // ------------------------------------------
        ],
      ),
      body: SizedBox(
        height: media.height,
        width: media.width,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: media.height * 0.05),

              // Logo Image
              SizedBox(
                height: media.width * 0.6,
                width: media.width * 0.8,
                child: Image.asset("assets/pic/logo.png", fit: BoxFit.contain),
              ),

              SizedBox(height: media.height * 0.08),

              // Login Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: RoundButton(
                  title: loc.translate('login'), // Translated title
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

              // Sign Up Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: RoundButton(
                  title: loc.translate('signup'), // Translated title
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
                      loc.translate('goTo'), // Translated "Go to "
                      style: TextStyle(
                        color: TColor.secondaryText,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      loc.translate('adminLogin'), // Translated "Admin Login"
                      style: TextStyle(
                        color: primaryRed,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // --- NEW: Active Drivers Button ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: RoundButton(
                  title: loc.translate('activeDrivers'), // Translated title
                  type: RoundButtonType.textPrimary,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ActiveDriversMapScreen(),
                      ),
                    );
                  },
                ),
              ),

              // ----------------------------------
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
