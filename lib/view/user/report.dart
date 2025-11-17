import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class WorkingTimeView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // If user is not logged in, handle this case
      return Scaffold(
        body: Center(
          child: Text('User not logged in. Please log in to view data.'),
        ),
      );
    }

    // --- Get Start and End of Today ---
    DateTime now = DateTime.now();
    // Start of today is 00:00:00
    DateTime startOfToday = DateTime(now.year, now.month, now.day, 0, 0, 0);
    // End of today is 23:59:59
    DateTime endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);
    // ---

    return Scaffold(
      appBar: AppBar(
        // Updated AppBar title to show today's date
        title: Text("Today's Work (${DateFormat('yyyy-MM-dd').format(now)})"),
        automaticallyImplyLeading: false, // Remove the back button
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('workingtime')
            .where('userId', isEqualTo: user.uid)
            // --- REMOVED DATE FILTERS ---
            // We will filter in-memory to avoid the index requirement.
            // WARNING: This is less efficient and can cost more reads
            // if the user has a lot of historical data.
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            // --- ADDED IN-MEMORY FILTERING ---
            var allDocs = snapshot.data!.docs;

            var todayDocs = allDocs.where((doc) {
              var data = doc.data() as Map<String, dynamic>;
              // Ensure 'date' exists and is a Timestamp
              if (data['date'] == null || data['date'] is! Timestamp) {
                return false;
              }
              var date = (data['date'] as Timestamp).toDate();
              // Check if the date is within today's range
              return date.isAfter(startOfToday) && date.isBefore(endOfToday);
            }).toList(); // Convert the iterable to a list

            // If, after filtering, there are no docs for today
            if (todayDocs.isEmpty) {
              return Center(child: Text('No working time recorded for today.'));
            }
            // ---

            // Sort the data by date (which includes time)
            // We now sort 'todayDocs' instead of all docs
            var sortedDocs = todayDocs
                .map((doc) => doc.data() as Map<String, dynamic>)
                .toList();

            // This sort is still useful if you have multiple entries today
            sortedDocs.sort((a, b) {
              var dateA = (a['date'] as Timestamp?)?.toDate() ?? DateTime(0);
              var dateB = (b['date'] as Timestamp?)?.toDate() ?? DateTime(0);
              return dateA.compareTo(dateB);
            });

            return SingleChildScrollView(
              child: Column(
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: [
                        // Removed 'Date and Time' column as it's redundant
                        DataColumn(label: Text('Start Time')),
                        DataColumn(label: Text('End Time')),
                        DataColumn(label: Text('Working Hours')),
                      ],
                      rows: sortedDocs.map((data) {
                        // 'date' field is no longer needed here

                        var startTime = (data['startTime'] as Timestamp?)
                            ?.toDate();
                        var formattedStartTime = startTime != null
                            ? DateFormat('HH:mm:ss').format(startTime)
                            : 'N/A';

                        var endTime = (data['endTime'] as Timestamp?)?.toDate();
                        var formattedEndTime = endTime != null
                            ? DateFormat('HH:mm:ss').format(endTime)
                            : 'N/A';

                        var workingHours =
                            data.containsKey('differenceInHours') &&
                                data.containsKey('differenceInMinutes')
                            ? '${data['differenceInHours']} hours ${data['differenceInMinutes']} minutes'
                            : 'N/A';

                        return DataRow(
                          cells: [
                            // Removed DateCell
                            DataCell(Text(formattedStartTime)),
                            DataCell(Text(formattedEndTime)),
                            DataCell(Text(workingHours)),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            );
          } else {
            return Center(
              // Updated "no data" message
              child: Text('No working time recorded for today.'),
            );
          }
        },
      ),
    );
  }
}
