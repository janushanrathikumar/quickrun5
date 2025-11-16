import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DeleteUser extends StatefulWidget {
  @override
  _DeleteUserState createState() => _DeleteUserState();
}

class _DeleteUserState extends State<DeleteUser> {
  List<DocumentSnapshot> usersList = [];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  // Function to fetch user details from Firestore
  Future<void> _fetchUsers() async {
    final QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('usersdetails').get();

    setState(() {
      usersList = snapshot.docs;
    });
  }

  // Function to delete a user from Firestore
  Future<void> _deleteUser(String userId) async {
    await FirebaseFirestore.instance
        .collection('usersdetails')
        .doc(userId)
        .delete();
    _fetchUsers(); // Refresh user list after deletion
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('User deleted successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Delete User'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: usersList.isNotEmpty
            ? ListView.builder(
                itemCount: usersList.length,
                itemBuilder: (context, index) {
                  final user = usersList[index];
                  final String email = user['email'];
                  final String name = user['name'];
                  final String userId = user['userId'];

                  return Card(
                    child: ListTile(
                      title: Text(name),
                      subtitle: Text('Email: $email\nUser ID: $userId'),
                      trailing: IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          // Confirmation dialog before deleting
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('Delete User'),
                              content: Text(
                                  'Are you sure you want to delete $name?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _deleteUser(userId);
                                  },
                                  child: Text('Delete'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              )
            : Center(child: Text('No users available')),
      ),
    );
  }
}
