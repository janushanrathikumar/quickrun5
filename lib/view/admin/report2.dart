import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class Report2 extends StatefulWidget {
  @override
  _Report2State createState() => _Report2State();
}

class _Report2State extends State<Report2> {
  String? selectedMonth;
  final List<String> months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];

  final Map<String, String> _userNameCache = {}; // Cache for user names

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Working Time Report')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Select Month',
                border: OutlineInputBorder(),
              ),
              value: selectedMonth,
              onChanged: (String? newValue) {
                setState(() {
                  selectedMonth = newValue;
                });
              },
              items: months.map((String month) {
                return DropdownMenuItem<String>(
                  value: month,
                  child: Text(month),
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton.icon(
              onPressed: selectedMonth != null ? _printReport : null,
              icon: Icon(Icons.print),
              label: Text('Print Report'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
            ),
          ),
          SizedBox(height: 10),
          Expanded(
            child: selectedMonth != null
                ? StreamBuilder<QuerySnapshot>(
                    stream: _getFilteredStream(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                        final Map<String, List<Map<String, dynamic>>>
                            groupedData = {};
                        for (var doc in snapshot.data!.docs) {
                          var data = doc.data() as Map<String, dynamic>;
                          String userId = data['userId'];
                          if (groupedData[userId] == null) {
                            groupedData[userId] = [];
                          }
                          groupedData[userId]!.add(data);
                        }

                        return ListView(
                          children: groupedData.entries.map((entry) {
                            String userId = entry.key;
                            List<Map<String, dynamic>> userData = entry.value;

                            // Initialize total hours and minutes
                            int totalHours = 0;
                            int totalMinutes = 0;

                            // Manually sum the hours and minutes worked
                            for (var data in userData) {
                              // Safely cast 'differenceInHours' and 'differenceInMinutes' to double and then round to int
                              int hoursWorked =
                                  (data['differenceInHours'] as num)
                                      .toDouble()
                                      .round();
                              int minutesWorked =
                                  (data['differenceInMinutes'] as num)
                                      .toDouble()
                                      .round();

                              totalHours += hoursWorked;
                              totalMinutes += minutesWorked;
                            }

// Handle the carry-over of minutes into hours
                            if (totalMinutes >= 60) {
                              totalHours += totalMinutes ~/ 60;
                              totalMinutes = totalMinutes % 60;
                            }

                            return FutureBuilder<String?>(
                              future: _getUserName(userId),
                              builder: (context, userNameSnapshot) {
                                if (userNameSnapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return ListTile(
                                      title: Text('Loading user...'));
                                }
                                if (userNameSnapshot.hasError ||
                                    !userNameSnapshot.hasData) {
                                  return ListTile(
                                      title: Text('User ID: $userId'));
                                }

                                String userName = userNameSnapshot.data!;

                                return ExpansionTile(
                                  title: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(userName,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          )),
                                      SizedBox(height: 4),
                                      Text(
                                        'Total: $totalHours hours $totalMinutes minutes',
                                        style:
                                            TextStyle(color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                  children: userData.map((data) {
                                    DateTime startTime =
                                        (data['startTime'] as Timestamp)
                                            .toDate();
                                    DateTime endTime =
                                        (data['endTime'] as Timestamp).toDate();
                                    Duration difference =
                                        endTime.difference(startTime);
                                    int hours = difference.inHours;
                                    int minutes = difference.inMinutes % 60;

                                    String formattedDate =
                                        DateFormat('yyyy-MM-dd')
                                            .format(startTime);
                                    String formattedStartTime =
                                        DateFormat('HH:mm').format(startTime);
                                    String formattedEndTime =
                                        DateFormat('HH:mm').format(endTime);

                                    return ListTile(
                                      title: Text('Date: $formattedDate'),
                                      subtitle: Text(
                                          'Start: $formattedStartTime | End: $formattedEndTime'),
                                      trailing: Text(
                                        'Worked: $hours h $minutes m',
                                        style: TextStyle(
                                          color: Colors.green[700],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                            );
                          }).toList(),
                        );
                      } else {
                        return Center(
                            child:
                                Text('No data available for selected month.'));
                      }
                    },
                  )
                : Center(
                    child: Text(
                    'Please select a month to view the report.',
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  )),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _getFilteredStream() {
    if (selectedMonth == null) {
      return Stream.empty();
    }

    final now = DateTime.now();
    final monthIndex = months.indexOf(selectedMonth!) + 1;
    final year = now.year;
    final startOfMonth = DateTime(year, monthIndex, 1);
    final endOfMonth = monthIndex == 12
        ? DateTime(year + 1, 1, 1)
        : DateTime(year, monthIndex + 1, 1);

    return FirebaseFirestore.instance
        .collection('workingtime')
        .where('startTime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('startTime', isLessThan: Timestamp.fromDate(endOfMonth))
        .snapshots();
  }

  Future<String?> _getUserName(String userId) async {
    if (_userNameCache.containsKey(userId)) {
      return _userNameCache[userId];
    }

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('usersdetails')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        String userName = userDoc.get('name');
        _userNameCache[userId] = userName;
        return userName;
      } else {
        return 'Unknown User';
      }
    } catch (e) {
      print('Error fetching user name: $e');
      return 'Unknown User';
    }
  }

  void _printReport() async {
    if (selectedMonth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a month first.')),
      );
      return;
    }

    final snapshot = await _getFilteredStream().first;
    if (snapshot.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No data available for the selected month.')),
      );
      return;
    }

    final groupedData = <String, List<Map<String, dynamic>>>{};

    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      String userId = data['userId'];
      if (groupedData[userId] == null) {
        groupedData[userId] = [];
      }
      groupedData[userId]!.add(data);
    }

    final pdf = pw.Document();
    Duration totalOverallDuration =
        Duration(); // Total hours worked by all users
    List<List<String>> summaryData = [];

    // First page: Summary of total hours worked by each user
    for (var entry in groupedData.entries) {
      String userId = entry.key;
      List<Map<String, dynamic>> userData = entry.value;

      int totalHours = 0;
      int totalMinutes = 0;

      for (var data in userData) {
        int hoursWorked;
        int minutesWorked;

        // Ensure differenceInHours and differenceInMinutes are properly handled
        if (data['differenceInHours'] is int) {
          hoursWorked = data['differenceInHours'] as int;
        } else {
          hoursWorked = (data['differenceInHours'] as double).toInt();
        }

        if (data['differenceInMinutes'] is int) {
          minutesWorked = data['differenceInMinutes'] as int;
        } else {
          minutesWorked = (data['differenceInMinutes'] as double).toInt();
        }

        totalHours += hoursWorked;
        totalMinutes += minutesWorked;
      }

      // Handle minute overflow
      if (totalMinutes >= 60) {
        totalHours += totalMinutes ~/ 60;
        totalMinutes = totalMinutes % 60;
      }

      // Calculate total overall duration
      totalOverallDuration +=
          Duration(hours: totalHours, minutes: totalMinutes);

      final userName = await _getUserName(userId) ?? 'Unknown User';

      summaryData.add([userName, '$totalHours hours $totalMinutes minutes']);
    }

    // Adding summary page
    pdf.addPage(
      pw.MultiPage(
        build: (pw.Context context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'Working Time Report - ${selectedMonth!} ${DateTime.now().year}',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            headers: ['User', 'Total Hours Worked'],
            data: summaryData,
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'Total Hours Worked by All Users: '
            '${totalOverallDuration.inHours} hours ${totalOverallDuration.inMinutes % 60} minutes',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );

    // Second page: Detailed report for each user
    for (var entry in groupedData.entries) {
      String userId = entry.key;
      List<Map<String, dynamic>> userData = entry.value;
      final userName = await _getUserName(userId) ?? 'Unknown User';

      List<List<String>> userDetails = [];
      int totalUserHours = 0;
      int totalUserMinutes = 0;

      for (var data in userData) {
        DateTime startTime = (data['startTime'] as Timestamp).toDate();
        DateTime endTime = (data['endTime'] as Timestamp).toDate();
        Duration difference = endTime.difference(startTime);
        int hours = difference.inHours;
        int minutes = difference.inMinutes % 60;

        totalUserHours += hours;
        totalUserMinutes += minutes;

        // Format date, start and end times
        String formattedDate = DateFormat('yyyy-MM-dd').format(startTime);
        String formattedStartTime = DateFormat('HH:mm').format(startTime);
        String formattedEndTime = DateFormat('HH:mm').format(endTime);

        // Add user details to the table
        userDetails.add([
          formattedDate,
          formattedStartTime,
          formattedEndTime,
          '$hours h $minutes m',
        ]);
      }

      // Handle minute overflow for each user
      if (totalUserMinutes >= 60) {
        totalUserHours += totalUserMinutes ~/ 60;
        totalUserMinutes = totalUserMinutes % 60;
      }

      pdf.addPage(
        pw.MultiPage(
          build: (pw.Context context) => [
            pw.Header(
              level: 1,
              child: pw.Text(
                'Detailed Report for $userName',
                style:
                    pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.Table.fromTextArray(
              headers: ['Date', 'Start Time', 'End Time', 'Worked Hours'],
              data: userDetails,
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'Total Hours Worked by $userName: '
              '$totalUserHours hours $totalUserMinutes minutes',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
      );
    }

    // Generate and print PDF
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}
