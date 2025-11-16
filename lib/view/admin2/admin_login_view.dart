import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quickrun5/common/color_extension.dart';
import 'package:quickrun5/common_widget/round_button.dart';
import 'package:quickrun5/common_widget/round_textfield.dart';
import 'package:quickrun5/view/admin/adminhome_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminLoginView extends StatefulWidget {
  const AdminLoginView({super.key});

  @override
  State<AdminLoginView> createState() => _AdminLoginViewState();
}

class _AdminLoginViewState extends State<AdminLoginView> {
  TextEditingController txtEmail = TextEditingController();
  TextEditingController txtPassword = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCredentials();
  }

  Future<void> _loadCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      txtEmail.text = prefs.getString('admin_email') ?? '';
      txtPassword.text = prefs.getString('admin_password') ?? '';
    });
  }

  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('admin_email', txtEmail.text.trim());
    await prefs.setString('admin_password', txtPassword.text.trim());
  }

  Future<void> _Adminlogin() async {
    try {
      CollectionReference users = FirebaseFirestore.instance.collection(
        'admin',
      );
      QuerySnapshot querySnapshot = await users
          .where('email', isEqualTo: txtEmail.text.trim())
          .where('password', isEqualTo: txtPassword.text.trim())
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Save credentials locally
        await _saveCredentials();

        // Navigate to Admin home page
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AdminhomeomeScreen()),
        );
      } else {
        // User not found, show error
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Incorrect email or password')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('An error occurred')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 64),
              Text(
                "Admin Login",
                style: TextStyle(
                  color: TColor.primaryText,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                "Add Admin details to login",
                style: TextStyle(
                  color: TColor.secondaryText,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 25),
              RoundTextfield(
                hintText: "Admin Email",
                controller: txtEmail,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 25),
              RoundTextfield(
                hintText: "Admin Password",
                controller: txtPassword,
                obscureText: true,
              ),
              const SizedBox(height: 25),
              RoundButton(title: "Admin Login", onPressed: _Adminlogin),
            ],
          ),
        ),
      ),
    );
  }
}
