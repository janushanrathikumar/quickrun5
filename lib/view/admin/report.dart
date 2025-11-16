import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quickrun5/view/admin/WorkingTimeScreen.dart';

class AllUsersScreen extends StatelessWidget {
  Future<List<Map<String, dynamic>>> _getAllUserDetails() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('usersdetails')
        .get();

    return querySnapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("All User Details")),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getAllUserDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("No users found"));
          } else {
            final usersData = snapshot.data!;
            return ListView.builder(
              itemCount: usersData.length,
              itemBuilder: (context, index) {
                final user = usersData[index];
                return ListTile(
                  title: Text("Name: ${user['name']}"),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Email: ${user['email']}"),
                      Text("UserID: ${user['userId']}"),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            WorkingTimeScreen(userId: user['userId']),
                      ),
                    );
                  },
                );
              },
            );
          }
        },
      ),
    );
  }
}
