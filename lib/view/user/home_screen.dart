import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quickrun5/auth/auth_service.dart';
import 'package:quickrun5/common_widget/round_button.dart';
import 'package:quickrun5/view/on_boarding/startup_view.dart';
import 'package:quickrun5/view/user/calculation.dart';
import 'package:quickrun5/view/user/qr.dart';
import 'package:quickrun5/widgets/button.dart' as DeleveryButton;

// IMPORT PACKAGES
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart'; // <--- ADDED IMPORT

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  // Request Location Permissions on screen load
  Future<void> _requestPermissions() async {
    await Permission.location.request();
    await Permission.locationAlways.request(); // Important for background
    await Permission.notification.request();
  }

  // HELPER: Control Background Service
  void _manageBackgroundService(String availability) async {
    final service = FlutterBackgroundService();
    bool isRunning = await service.isRunning();

    if (availability == 'start' || availability == 'break') {
      if (!isRunning) {
        // --- SAVE UID BEFORE STARTING ---
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_uid', user.uid);
          print("User UID saved for background service: ${user.uid}");
        }
        // -------------------------------

        service.startService();
        print("Background Location Service Started");
      }
    } else if (availability == 'end') {
      if (isRunning) {
        service.invoke("stopService");
        print("Background Location Service Stopped");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AuthService auth = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        automaticallyImplyLeading: false,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/img/splash_bg.png"),
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

                      // Handle case where document doesn't exist yet
                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return Text("No status available");
                      }

                      final availability = snapshot.data!['available'];
                      Color notificationColor = Colors.grey;

                      // --- TRIGGER SERVICE BASED ON STATE ---
                      Future.delayed(Duration.zero, () {
                        _manageBackgroundService(availability);
                      });
                      // --------------------------------------

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
                  }
                },
              ),
              SizedBox(height: 10),
              RoundButton(
                title: "End",
                onPressed: () async {
                  final availability = await getCurrentAvailability();
                  if (availability != null && availability == 'end') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Your availability is already "end".'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  } else {
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
                  final service = FlutterBackgroundService();
                  service.invoke("stopService");

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
        }
      }
    } catch (e) {
      print('Error: $e');
    }
    return null;
  }

  Future<void> checkAvailabilityAndPerformAction(
    String action,
    BuildContext context,
  ) async {
    await _updateAvailability(action);
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
        } else {
          await userRef.set({'available': availability, 'email': userEmail});
        }
      }
    } catch (e) {
      print('Error updating availability: $e');
    }
  }
}
