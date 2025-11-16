import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:quickrun5/auth/auth_service.dart';
import 'package:quickrun5/auth/login_view.dart';
import 'package:quickrun5/common_widget/round_button.dart';
import 'package:quickrun5/view/main_tabview/main_tabview.dart';
import 'package:quickrun5/widgets/button.dart';
import 'package:quickrun5/widgets/textfield.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _auth = AuthService();

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
              "assets/img/splash_bg.png",
            ), // Path to your background image
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Signup",
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 2, 2, 2),
                  ),
                ),
                const SizedBox(height: 50),
                CustomTextField(
                  hint: "Enter Name",
                  label: "Name",
                  controller: _name,
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  hint: "Enter Email",
                  label: "Email",
                  controller: _email,
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  hint: "Enter Password",
                  label: "Password",
                  isPassword: true,
                  controller: _password,
                ),
                const SizedBox(height: 30),
                RoundButton(title: "Signup", onPressed: _signup),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Already have an account? ",
                      style: TextStyle(color: Color.fromARGB(255, 4, 4, 4)),
                    ),
                    InkWell(
                      onTap: () => goToLogin(context),
                      child: const Text(
                        "Login",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  goToLogin(BuildContext context) => Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const LoginView()),
  );

  goToHome(BuildContext context) => Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const MainTabView()),
  );

  _signup() async {
    // Check if any field is empty
    if (_name.text.isEmpty || _email.text.isEmpty || _password.text.isEmpty) {
      // Show an error pop-up for empty fields
      _showErrorDialog("Please fill in all fields.");
      return;
    }

    // Perform signup
    try {
      final user = await _auth.createUserWithEmailAndPassword(
        _email.text,
        _password.text,
      );
      await _updateAvailability("end");

      if (user != null) {
        // User created successfully
        log("User Created Successfully");

        // Save additional user details to the database (e.g., name)
        await _saveUserDetails(user.uid, _name.text, _email.text);

        // Navigate to home screen
        goToHome(context);
      }
    } on FirebaseAuthException catch (e) {
      // Handle FirebaseAuth errors
      if (e.code == 'email-already-in-use') {
        // Show an error pop-up for email already in use
        _showErrorDialog(
          "This email is already in use. Please use a different email.",
        );
      } else {
        // Show a generic error pop-up for other FirebaseAuth errors
        _showErrorDialog("Signup failed. Please try again.");
      }
    } catch (e) {
      // Show a generic error pop-up for other errors
      _showErrorDialog("Signup failed. Please try again.");
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Error"),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveUserDetails(
    String userId,
    String name,
    String email,
  ) async {
    try {
      // Save user details (name and email) to Firestore
      await FirebaseFirestore.instance
          .collection('usersdetails')
          .doc(userId)
          .set({'name': name, 'email': email, 'userId': userId});

      // For demonstration, let's just log the user details
      log("Saving user details - UserID: $userId, Name: $name, Email: $email");
    } catch (e) {
      // Show a generic error pop-up if saving user details fails
      _showErrorDialog("Failed to save user details. Please try again.");
    }
  }

  Future<void> _updateAvailability(String availability) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userId = user.uid;
        final userEmail = user.email;

        final userRef = FirebaseFirestore.instance
            .collection('available')
            .doc(userId);

        final userDoc = await userRef.get();
        if (userDoc.exists) {
          await userRef.update({'available': availability, 'email': userEmail});
          print('Availability updated successfully!');
        } else {
          print('User document not found. Creating new document...');
          await userRef.set({'available': availability, 'email': userEmail});
          print('User document created with availability: $availability');
        }
      } else {
        print('User not logged in!');
      }
    } catch (e) {
      print('Error updating availability: $e');
    }
  }
}
