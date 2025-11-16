import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quickrun5/view/main_tabview/main_tabview.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class qrCode extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QR Code Scanner',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: QRViewExample(),
    );
  }
}

class QRViewExample extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _QRViewExampleState();
}

class _QRViewExampleState extends State<QRViewExample> {
  BarcodeCapture? result;
  MobileScannerController controller = MobileScannerController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    final Barcode? barcode = capture.barcodes.first;
    if (barcode?.rawValue != null) {
      final code = barcode!.rawValue!;
      setState(() {
        result = capture;
      });

      if (code == 'start') {
        await checkAvailabilityAndPerformAction("start", context);
        await _StartTime("start");

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainTabView()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('QR Code Scanner')),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 4,
            child: MobileScanner(controller: controller, onDetect: _onDetect),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: (result != null && result!.barcodes.isNotEmpty)
                  ? Text(
                      'Barcode Type: ${result!.barcodes.first.format}   Data: ${result!.barcodes.first.rawValue}',
                    )
                  : Text('Scan a code'),
            ),
          ),
        ],
      ),
    );
  }

  // keep the existing functions unchanged
  Future<void> checkAvailabilityAndPerformAction(
    String action,
    BuildContext context,
  ) async {
    // unchanged
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
                duration: Duration(seconds: 1),
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
    // unchanged
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

  Future<void> _StartTime(String availability) async {
    // unchanged
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userId = user.uid;
        final userEmail = user.email;

        final startTimeRef = FirebaseFirestore.instance
            .collection('StartTime')
            .doc(userId);

        final startTimeDoc = await startTimeRef.get();
        if (startTimeDoc.exists) {
          if (availability == 'start') {
            await startTimeRef.set({
              'startTime': Timestamp.now(),
              'email': userEmail,
            });
            print('Start time saved successfully!');
          } else {
            print('Start time document found but availability is not start.');
          }
        } else {
          print('Start time document not found. Creating new document...');
          if (availability == 'start') {
            await startTimeRef.set({
              'startTime': Timestamp.now(),
              'email': userEmail,
            });
            print('Start time document created.');
            print('Start time saved successfully!');
          } else {
            print(
              'Start time document not found and availability is not start.',
            );
          }
        }
      } else {
        print('User not logged in!');
      }
    } catch (e) {
      print('Error updating availability: $e');
    }
  }
}
