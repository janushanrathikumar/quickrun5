import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderPage extends StatelessWidget {
  final String userName;
  final String docId;
  final String userId;
  final String userEmail;

  OrderPage({
    Key? key,
    required this.userName,
    required this.userId,
    required this.docId,
    required this.userEmail,
  }) : super(key: key);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveData(
      BuildContext context,
      String parcelId,
      String address,
      String deliveryPhone,
      String deliveryAddress,
      String userEmail,
      String docId) async {
    try {
      Map<String, dynamic> data = {
        'parcelId': parcelId,
        'address': address,
        'deliveryPhone': deliveryPhone,
        'deliveryAddress': deliveryAddress,
        'userEmail': userEmail,
        'docId': docId,
      };

      // Save data to Firestore without specifying a document ID
      await _firestore.collection('orders').add(data);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Data saved successfully')),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    TextEditingController parcelIdController = TextEditingController();
    TextEditingController addressController = TextEditingController();
    TextEditingController deliveryPhoneController = TextEditingController();
    TextEditingController deliveryAddressController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: Text('User Input'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: parcelIdController,
              decoration: InputDecoration(labelText: 'Parcel ID'),
            ),
            TextField(
              controller: addressController,
              decoration: InputDecoration(labelText: 'Address'),
            ),
            TextField(
              controller: deliveryPhoneController,
              decoration: InputDecoration(labelText: 'Delivery Phone No.'),
            ),
            TextField(
              controller: deliveryAddressController,
              decoration: InputDecoration(labelText: 'Delivery Address'),
            ),
            SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: () {
                saveData(
                  context,
                  parcelIdController.text.trim(),
                  addressController.text.trim(),
                  deliveryPhoneController.text.trim(),
                  deliveryAddressController.text.trim(),
                  userEmail,
                  docId,
                );
              },
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
