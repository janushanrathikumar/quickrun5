// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';

// class ViewLocationHistoryScreen extends StatelessWidget {
//   const ViewLocationHistoryScreen({super.key});

//   // Define the time limit in minutes
//   static const int LOCATION_TIMEOUT_MINUTES = 5;

//   // Helper function to check if the last update was recent
//   bool isLocationRecent(Timestamp? lastUpdated) {
//     if (lastUpdated == null) {
//       return false;
//     }
//     final fiveMinutesAgo = DateTime.now().subtract(
//       const Duration(minutes: LOCATION_TIMEOUT_MINUTES),
//     );
//     return lastUpdated.toDate().isAfter(fiveMinutesAgo);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Active Driver Locations (Last 5 min)'),
//         backgroundColor:
//             Colors.teal, // Changed color to reflect 'Active' filtering
//         // Removes the back button
//         automaticallyImplyLeading: false,
//       ),
//       // Stream from 'usersdetails' to get name and UID
//       body: StreamBuilder<QuerySnapshot>(
//         stream: FirebaseFirestore.instance
//             .collection('usersdetails')
//             .snapshots(),
//         builder: (context, usersSnapshot) {
//           if (usersSnapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
//           if (usersSnapshot.hasError) {
//             return Center(child: Text('Error: ${usersSnapshot.error}'));
//           }
//           if (!usersSnapshot.hasData || usersSnapshot.data!.docs.isEmpty) {
//             return const Center(child: Text('No user details found.'));
//           }

//           final userDocs = usersSnapshot.data!.docs;

//           // --- FILTERING LOGIC ---
//           // Use a Future.wait to fetch all location data concurrently and filter the list
//           return FutureBuilder<List<Map<String, dynamic>>>(
//             future: Future.wait(
//               userDocs.map((userDoc) async {
//                 final uid = userDoc.id;
//                 final userData = userDoc.data() as Map<String, dynamic>;

//                 // Fetch location data
//                 final locationDoc = await FirebaseFirestore.instance
//                     .collection('location_history')
//                     .doc(uid)
//                     .get();

//                 Map<String, dynamic> locationData = {};
//                 if (locationDoc.exists) {
//                   locationData = locationDoc.data() as Map<String, dynamic>;
//                 }

//                 final lastUpdatedTimestamp =
//                     locationData['last_updated'] as Timestamp?;
//                 final isRecent = isLocationRecent(lastUpdatedTimestamp);

//                 return {
//                   'uid': uid,
//                   'name': userData['name'] ?? 'Unknown Driver',
//                   'locationData': locationData,
//                   'isRecent': isRecent,
//                   'lastUpdatedTimestamp': lastUpdatedTimestamp,
//                 };
//               }),
//             ),
//             builder: (context, snapshot) {
//               if (snapshot.connectionState == ConnectionState.waiting) {
//                 return const Center(child: Text('Checking driver statuses...'));
//               }
//               if (snapshot.hasError) {
//                 return Center(
//                   child: Text('Error processing statuses: ${snapshot.error}'),
//                 );
//               }

//               // Filter the list to include ONLY recent drivers
//               final activeDrivers = snapshot.data!
//                   .where((driver) => driver['isRecent'] == true)
//                   .toList();

//               if (activeDrivers.isEmpty) {
//                 return const Center(
//                   child: Padding(
//                     padding: EdgeInsets.all(20.0),
//                     child: Text(
//                       'No drivers currently active (updated within the last 5 minutes).',
//                       textAlign: TextAlign.center,
//                       style: TextStyle(fontSize: 16, color: Colors.grey),
//                     ),
//                   ),
//                 );
//               }
//               // -----------------------

//               return ListView.builder(
//                 itemCount: activeDrivers.length,
//                 itemBuilder: (context, index) {
//                   final driver = activeDrivers[index];

//                   final locationData =
//                       driver['locationData'] as Map<String, dynamic>;
//                   final lastUpdatedTimestamp =
//                       driver['lastUpdatedTimestamp'] as Timestamp?;

//                   String lastUpdatedText = 'N/A';
//                   if (lastUpdatedTimestamp != null) {
//                     lastUpdatedText = DateFormat(
//                       'yyyy-MM-dd HH:mm:ss',
//                     ).format(lastUpdatedTimestamp.toDate());
//                   }

//                   return Card(
//                     elevation: 4,
//                     margin: const EdgeInsets.symmetric(
//                       vertical: 8,
//                       horizontal: 10,
//                     ),
//                     child: Padding(
//                       padding: const EdgeInsets.all(16.0),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           // Display Name (from usersdetails)
//                           Text(
//                             'Driver: ${driver['name']}',
//                             style: const TextStyle(
//                               fontWeight: FontWeight.bold,
//                               fontSize: 18,
//                             ),
//                           ),
//                           const SizedBox(height: 8),

//                           // Display only the Active status and recent location
//                           Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               const Text(
//                                 'Current Status: ✅ Active (Last 5 min)',
//                                 style: TextStyle(
//                                   color: Colors.green,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                               Text(
//                                 '  Lat: ${locationData['latitude']?.toStringAsFixed(6) ?? 'N/A'}',
//                                 style: const TextStyle(fontSize: 14),
//                               ),
//                               Text(
//                                 '  Lon: ${locationData['longitude']?.toStringAsFixed(6) ?? 'N/A'}',
//                                 style: const TextStyle(fontSize: 14),
//                               ),
//                             ],
//                           ),

//                           const SizedBox(height: 4),
//                           Text(
//                             'Last Location Update: $lastUpdatedText',
//                             style: const TextStyle(
//                               fontStyle: FontStyle.italic,
//                               fontSize: 12,
//                               color: Colors.grey,
//                             ),
//                           ),
//                           // Display UID for debugging (Optional)
//                           Text(
//                             'UID: ${driver['uid']}',
//                             style: const TextStyle(
//                               fontSize: 10,
//                               color: Colors.black54,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   );
//                 },
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }
