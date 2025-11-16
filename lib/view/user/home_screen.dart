import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quickrun5/auth/auth_service.dart';

import 'package:quickrun5/common_widget/round_button.dart';
import 'package:quickrun5/view/on_boarding/startup_view.dart';
import 'package:quickrun5/view/user/calculation.dart';
import 'package:quickrun5/view/user/qr.dart';

import 'package:quickrun5/widgets/button.dart' as DeleveryButton;

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final AuthService auth = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        automaticallyImplyLeading: false, // Remove the back button
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
              "assets/img/splash_bg.png",
            ), // Path to your background image
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('available')
                    .doc(FirebaseAuth.instance.currentUser!.uid)
                    .snapshots(),
                builder:
                    (
                      BuildContext context,
                      AsyncSnapshot<DocumentSnapshot> snapshot,
                    ) {
                      if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }

                      final availability = snapshot.data!['available'];
                      Color notificationColor = Colors.grey; // Default color

                      if (availability == 'end') {
                        notificationColor = Colors.red;
                      } else if (availability == 'start') {
                        notificationColor = Colors.green;
                      } else if (availability == 'break') {
                        notificationColor = Colors.orange;
                      }

                      return Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: notificationColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome,',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              '${FirebaseAuth.instance.currentUser?.email ?? 'User'}',
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Your availability status is:',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              '$availability',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
              ),
              SizedBox(height: 20),
              RoundButton(
                title: "Start",
                onPressed: () async {
                  // Check current availability
                  final availability = await getCurrentAvailability();
                  if (availability != null && availability == 'start') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Your availability is already "start".'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => qrCode()),
                    );
                    // If availability is not "start", proceed with action
                  }
                },
              ),
              SizedBox(height: 10),
              RoundButton(
                title: "End",
                onPressed: () async {
                  // Check current availability
                  final availability = await getCurrentAvailability();
                  if (availability != null && availability == 'end') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Your availability is already "end".'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  } else {
                    // If availability is not "end", proceed with action
                    await checkAvailabilityAndPerformAction('end', context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FirestoreExample(),
                      ),
                    );
                  }
                },
              ),
              SizedBox(height: 20),
              RoundButton(
                title: "Sign Out",
                onPressed: () async {
                  await auth.signout();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => StartupView()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> getCurrentAvailability() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userId = user.uid;
        final userRef = FirebaseFirestore.instance
            .collection('available')
            .doc(userId);
        final userDoc = await userRef.get();
        if (userDoc.exists) {
          return userDoc.data()?['available'];
        } else {
          print('User document not found.');
        }
      } else {
        print('User not logged in!');
      }
    } catch (e) {
      print('Error checking current availability: $e');
    }
    return null;
  }

  Future<void> checkAvailabilityAndPerformAction(
    String action,
    BuildContext context,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userId = user.uid;

        final userRef = FirebaseFirestore.instance
            .collection('available')
            .doc(userId);

        final userDoc = await userRef.get();
        if (userDoc.exists) {
          final availability = userDoc.data()?['available'];

          if (availability == 'break') {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Cannot perform action. Availability is on break.',
                ),
                duration: Duration(seconds: 2),
              ),
            );
          } else {
            await _updateAvailability(action);
          }
        } else {
          print('User document not found.');
        }
      } else {
        print('User not logged in!');
      }
    } catch (e) {
      print('Error checking availability: $e');
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
