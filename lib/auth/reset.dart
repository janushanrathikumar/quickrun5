import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PasswordResetScreen extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();

  void _resetPassword(BuildContext context) async {
    String email = emailController.text.trim();

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      // Show success message and navigate back or to login screen
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Password Reset Email Sent"),
            content: Text("Check your email to reset your password."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text("OK"),
              ),
            ],
          );
        },
      );
    } catch (error) {
      // Handle errors such as invalid email, user not found, etc.
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Password Reset Failed"),
            content: Text(error.toString()),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text("OK"),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: Text('Password Reset'),
      ),
      body: Container(
        height: media.height,
        width: media.width,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/img/splash_bg.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Enter your email to receive a password reset link:',
                style: TextStyle(
                    fontSize: 18.0,
                    color: const Color.fromARGB(255, 16, 15, 15)),
              ),
              SizedBox(height: 10.0),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(color: Color.fromARGB(255, 14, 15, 14)),
                  border: OutlineInputBorder(),
                ),
                style: TextStyle(color: const Color.fromARGB(255, 12, 12, 12)),
              ),
              SizedBox(height: 20.0),
              ElevatedButton(
                onPressed: () {
                  _resetPassword(context);
                },
                child: Text('Reset Password'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
