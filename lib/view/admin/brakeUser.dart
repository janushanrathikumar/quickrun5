import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BrakePage extends StatelessWidget {
  final String userName;
  final String userId;
  final String userEmail;

  const BrakePage({
    Key? key,
    required this.userName,
    required this.userId,
    required this.userEmail,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(userName),
      ),
      body: Container(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 12.0),
              ElevatedButton(
                onPressed: () async {
                  await _updateAvailability(userId, 'start', userEmail);
                  await _StartTime(userId, userEmail);
                  Navigator.pushReplacementNamed(context, '/adminhome');
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.all(16.0),
                ),
                child: Text(
                  'Start',
                  style: TextStyle(fontSize: 16.0),
                ),
              ),
              SizedBox(height: 12.0),
              ElevatedButton(
                onPressed: () async {
                  await _updateAvailability(userId, 'break', userEmail);
                  Navigator.pushReplacementNamed(context, '/adminhome');
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.all(16.0),
                ),
                child: Text(
                  'Break',
                  style: TextStyle(fontSize: 16.0),
                ),
              ),
              SizedBox(height: 12.0),
              ElevatedButton(
                onPressed: () async {
                  await _updateAvailability(userId, 'end', userEmail);
                  Navigator.pushReplacementNamed(context, '/adminhome');
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.all(16.0),
                ),
                child: Text(
                  'End',
                  style: TextStyle(fontSize: 16.0),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateAvailability(
      String userId, String availability, String userEmail) async {
    try {
      final userRef =
          FirebaseFirestore.instance.collection('available').doc(userId);

      final userDoc = await userRef.get();
      if (userDoc.exists) {
        await userRef.update({
          'available': availability,
          'email': userEmail,
        });
        print('Availability updated successfully!');
      } else {
        await userRef.set({
          'available': availability,
          'email': userEmail,
        });
        print('User document created with availability: $availability');
      }

      switch (availability) {
        case 'start':
          print('Send email for availability started to $userEmail');
          break;
        case 'end':
          print('Send email for availability ended to $userEmail');
          break;
        case 'break':
          print('Send email for break to $userEmail');
          break;
        default:
          print('Unknown availability status');
      }
    } catch (e) {
      print('Error updating availability: $e');
    }
  }

  Future<void> _StartTime(String userId, String userEmail) async {
    try {
      final startTimeRef =
          FirebaseFirestore.instance.collection('StartTime').doc(userId);

      final startTimeDoc = await startTimeRef.get();
      if (startTimeDoc.exists) {
        await startTimeRef.update({
          'startTime': Timestamp.now(),
          'email': userEmail,
        });
        print('Start time updated successfully!');
      } else {
        await startTimeRef.set({
          'startTime': Timestamp.now(),
          'email': userEmail,
        });
        print('Start time document created and saved successfully!');
      }
    } catch (e) {
      print('Error updating start time: $e');
    }
  }

  Future<void> _cal(String userId) async {
    try {
      // Retrieve the start time from Firestore
      DocumentSnapshot startTimeSnapshot = await FirebaseFirestore.instance
          .collection('StartTime')
          .doc(userId)
          .get();

      if (!startTimeSnapshot.exists) {
        print('Start Time Not Available');
        return;
      }

      // Extract and format the start time
      Timestamp startTimeTimestamp = startTimeSnapshot['startTime'];
      DateTime formattedStartTime = DateTime.fromMillisecondsSinceEpoch(
          startTimeTimestamp.seconds * 1000);

      // Capture the current time as the end time
      DateTime currentTime = DateTime.now();
      Duration difference = currentTime.difference(formattedStartTime);

      // Save the start time, end time, and calculated working time to Firestore
      await FirebaseFirestore.instance.collection('workingtime').add({
        'userId': userId,
        'date': currentTime, // Record the date/time of the entry
        'startTime': formattedStartTime,
        'endTime': currentTime,
        'differenceInHours': difference.inHours,
        'differenceInMinutes': difference.inMinutes.remainder(60),
      });

      // Log the times and duration for debugging
      print('Start Time: $formattedStartTime');
      print('End Time: $currentTime');
      print(
          'Working Time: ${difference.inHours} hours and ${difference.inMinutes.remainder(60)} minutes');
    } catch (error) {
      print('Error: $error');
    }
  }
}
