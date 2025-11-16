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
          child: Text('User not logged in'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Working Time Data'),
        automaticallyImplyLeading: false, // Remove the back button
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('workingtime')
            .where('userId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            // Sort the data by date
            var sortedDocs = snapshot.data!.docs
                .map((doc) => doc.data() as Map<String, dynamic>)
                .toList();

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
                        DataColumn(label: Text('Date and Time')),
                        DataColumn(label: Text('Start Time')),
                        DataColumn(label: Text('End Time')),
                        DataColumn(label: Text('Working Hours')),
                      ],
                      rows: sortedDocs.map((data) {
                        // Parse the date, startTime, and endTime, with null checks
                        var date = (data['date'] as Timestamp?)?.toDate();
                        var formattedDate = date != null
                            ? DateFormat('yyyy-MM-dd HH:mm:ss').format(date)
                            : 'N/A';

                        var startTime =
                            (data['startTime'] as Timestamp?)?.toDate();
                        var formattedStartTime = startTime != null
                            ? DateFormat('HH:mm:ss').format(startTime)
                            : 'N/A';

                        var endTime = (data['endTime'] as Timestamp?)?.toDate();
                        var formattedEndTime = endTime != null
                            ? DateFormat('HH:mm:ss').format(endTime)
                            : 'N/A';

                        var workingHours = data
                                    .containsKey('differenceInHours') &&
                                data.containsKey('differenceInMinutes')
                            ? '${data['differenceInHours']} hours ${data['differenceInMinutes']} minutes'
                            : 'N/A';

                        return DataRow(cells: [
                          DataCell(Text(formattedDate)),
                          DataCell(Text(formattedStartTime)),
                          DataCell(Text(formattedEndTime)),
                          DataCell(Text(workingHours)),
                        ]);
                      }).toList(),
                    ),
                  ),
                ],
              ),
            );
          } else {
            return Center(
                child: Text('No data available for the current user'));
          }
        },
      ),
    );
  }
}
