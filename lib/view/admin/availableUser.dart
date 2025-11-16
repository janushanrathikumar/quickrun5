import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quickrun5/view/admin/oderpage.dart';
import 'package:quickrun5/view/admin/brakeUser.dart';
import 'package:quickrun5/view/admin/cal2.dart';

class adminHomeScreen extends StatelessWidget {
  const adminHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Available Users')),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('available').snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
              return Center(child: CircularProgressIndicator());
            default:
              return _buildBody(context, snapshot.data!.docs);
          }
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, List<DocumentSnapshot> documents) {
    final currentUser = FirebaseAuth.instance.currentUser;

    List<Widget> availableUsers = [];
    List<Widget> unavailableUsers = [];
    List<Widget> brakeUsers = [];

    for (var doc in documents) {
      final String status = doc['available'] ?? 'end';
      final String userName = doc.id; // Assuming username is the document ID
      final String userEmail =
          doc['email']; // Retrieve user's email from Firestore

      Widget userCard = Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        elevation: 4.0,
        color: status == 'start'
            ? Colors.green.withOpacity(0.8)
            : status == 'end'
            ? Colors.red.withOpacity(0.8)
            : Colors.orange.withOpacity(
                0.8,
              ), // Assuming brake user color as orange
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          title: Text(
            userName,
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 8.0),
              Text(
                'Email: $userEmail', // Display user's email
                style: TextStyle(fontSize: 14.0, color: Colors.white),
              ),
              SizedBox(height: 4.0),
              Text(
                'Status: ${status == 'start'
                    ? 'Available'
                    : status == 'end'
                    ? 'Unavailable'
                    : 'Brake'}',
                style: TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          trailing: currentUser != null && currentUser.email == userEmail
              ? Icon(Icons.person, color: Colors.white)
              : null,
          onTap: () {
            if (status == 'start') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserOptionsPage(
                    userName: userName,
                    userId: doc.id,
                    userEmail: userEmail,
                    docId: doc.id,
                  ),
                ),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BrakePage(
                    userName: userName,
                    userId: doc.id,
                    userEmail: userEmail,
                  ),
                ),
              );
            }
          },
        ),
      );

      if (status == 'start') {
        availableUsers.add(userCard);
      } else if (status == 'end') {
        unavailableUsers.add(userCard);
      } else {
        brakeUsers.add(userCard);
      }
    }

    return ListView(
      children: [
        ...availableUsers,
        if (unavailableUsers.isNotEmpty || brakeUsers.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 16.0),
              if (unavailableUsers.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Unavailable Users',
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ),
              SizedBox(height: 8.0),
              ...unavailableUsers,
              if (brakeUsers.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Brake Users',
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ),
              SizedBox(height: 8.0),
              ...brakeUsers,
            ],
          ),
      ],
    );
  }
}

class UserOptionsPage extends StatelessWidget {
  final String userName;
  final String userId;
  final String userEmail; // Added userEmail parameter
  final String docId; // Added docId parameter

  const UserOptionsPage({
    Key? key,
    required this.userName,
    required this.userId,
    required this.userEmail, // Required userEmail parameter
    required this.docId, // Required docId parameter
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(userName)),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/img/splash_bg.png"'),
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OrderPage(
                        userName: userName,
                        userId: userId,
                        userEmail: userEmail,
                        docId: docId, // Pass docId here
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(padding: EdgeInsets.all(16.0)),
                child: Text('Add Order', style: TextStyle(fontSize: 16.0)),
              ),
              ElevatedButton(
                onPressed: () async {
                  await _updateAvailability(userId, 'break', userEmail);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Calculation(
                        userName: userName,
                        userId: userId,
                        userEmail: userEmail,
                        docId: docId, // Pass docId here
                      ),
                    ),
                  );
                  // Pass userEmail parameter
                },
                style: ElevatedButton.styleFrom(padding: EdgeInsets.all(16.0)),
                child: Text('Break', style: TextStyle(fontSize: 16.0)),
              ),
              SizedBox(height: 12.0),
              ElevatedButton(
                onPressed: () async {
                  await _updateAvailability(userId, 'end', userEmail);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Calculation(
                        userName: userName,
                        userId: userId,
                        userEmail: userEmail,
                        docId: docId, // Pass docId here
                      ),
                    ),
                  );

                  // Pass userEmail parameter
                },
                style: ElevatedButton.styleFrom(padding: EdgeInsets.all(16.0)),
                child: Text('End', style: TextStyle(fontSize: 16.0)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Inside _updateAvailability method signature and implementation
  Future<void> _updateAvailability(
    String userId,
    String availability,
    String userEmail,
  ) async {
    // Added userEmail parameter
    try {
      final userRef = FirebaseFirestore.instance
          .collection('available')
          .doc(userId);

      // Check if the document exists before updating
      final userDoc = await userRef.get();
      if (userDoc.exists) {
        await userRef.update({
          'available': availability,
          'email': userEmail, // Include clicked user's email when updating
        });
        print('Availability updated successfully!');
      } else {
        // Handle the case where the document does not exist
        print('User document not found. Creating new document...');
        await userRef.set({
          'available': availability,
          'email': userEmail, // Include clicked user's email when creating
        });
        print('User document created with availability: $availability');
      }

      // Example email sending code (you need to implement your own email sending logic)
      // Send email based on the availability status
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
}
