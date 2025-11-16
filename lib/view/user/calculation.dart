import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreExample extends StatefulWidget {
  @override
  _FirestoreExampleState createState() => _FirestoreExampleState();
}

class _FirestoreExampleState extends State<FirestoreExample> {
  late String userId;

  @override
  void initState() {
    super.initState();
    // Get the current user's ID
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        setState(() {
          userId = user.uid;
        });
      }
    });
  }

  // Function to save the difference along with start and end times to Firestore
  void saveDifference(
      DateTime startTime, DateTime endTime, Duration difference) {
    DateTime currentDate = DateTime.now();
    FirebaseFirestore.instance.collection('workingtime').add({
      'userId': userId,
      'date': currentDate,
      'startTime': startTime,
      'endTime': endTime,
      'differenceInHours': difference.inHours,
      'differenceInMinutes': difference.inMinutes.remainder(60),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Today Working Hours'),
      ),
      body: Center(
        child: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('StartTime')
              .doc(userId)
              .snapshots(),
          builder: (context, AsyncSnapshot<DocumentSnapshot>? snapshot) {
            if (snapshot == null || !snapshot.hasData) {
              return CircularProgressIndicator();
            }
            var data = snapshot.data!.data() as Map<String, dynamic>?;

            if (data == null || !data.containsKey('startTime')) {
              return Text('Start Time Not Available');
            }
            var startTimeTimestamp = data['startTime'];
            var formattedStartTime = DateTime.fromMillisecondsSinceEpoch(
                startTimeTimestamp.seconds * 1000);

            // Set the current time as end time
            var endTime = DateTime.now();

            // Calculate the difference in hours and minutes between current time and start time
            var difference = endTime.difference(formattedStartTime);
            var differenceInHours = difference.inHours;
            var differenceInMinutes = difference.inMinutes.remainder(60);

            // Save the start time, end time, and difference to Firestore
            saveDifference(formattedStartTime, endTime, difference);

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Start Time: $formattedStartTime'),
                Text('End Time: $endTime'),
                Text(
                  'Working Time: $differenceInHours hours and $differenceInMinutes minutes',
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
