import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:quickrun5/auth/auth_service.dart';
import 'package:quickrun5/view/admin/Delete_month.dart';
import 'package:quickrun5/view/admin/addTime.dart';
import 'package:quickrun5/view/admin/deletuser.dart';

import 'package:quickrun5/view/login/welcome_view.dart';
import 'package:quickrun5/widgets/button.dart';
import 'package:quickrun5/view/admin/availableUser.dart';
import 'package:quickrun5/view/admin/report.dart';
import 'package:quickrun5/view/admin/report2.dart';

class AdminhomeomeScreen extends StatelessWidget {
  const AdminhomeomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService auth = AuthService();

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Home')),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Color.fromARGB(206, 45, 175, 219),
              ),
              child: Text(
                'Menu',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              title: Text('Available User'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => adminHomeScreen()),
                );
              },
            ),
            ListTile(
              title: Text('View Report'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AllUsersScreen()),
                );
              },
            ),
            ListTile(
              title: Text('Add Time'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddtimeUsersScreen()),
                );
              },
            ),
            ListTile(
              title: Text('Summary Report'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Report2()),
                );
              },
            ),
            ListTile(
              title: Text('Delete month report'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DeleteMonth()),
                );
              },
            ),
            ListTile(
              title: Text('Delete User'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DeleteUser()),
                );
              },
            ),
            ListTile(
              title: Text('Sign Out'),
              onTap: () async {
                await auth.signout();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => WelcomeView()),
                );
              },
            ),
          ],
        ),
      ),
      body: Container(
        child: Align(
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Welcome Admin",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
              ),
              const SizedBox(height: 20),
              CustomButton(
                label: "Sign Out",
                onPressed: () async {
                  await auth.signout();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => WelcomeView()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
