import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart'; // Import Pdf class
import 'package:pdf/widgets.dart' as pw; // Import widgets with alias pw
import 'package:printing/printing.dart'; // Add this import for printing functionality

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

  // Cache for user names to avoid multiple fetches
  final Map<String, String> _userNameCache = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Working Time Data'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DropdownButton<String>(
              hint: Text('Select Month'),
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
          ElevatedButton(
            onPressed: () {
              if (selectedMonth != null) {
                _printReport();
              }
            },
            child: Text('Print Report'),
          ),
          Expanded(
            child: StreamBuilder(
              stream: _getFilteredStream(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  // Group data by userId
                  final Map<String, List<Map<String, dynamic>>> groupedData =
                      {};
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

                      // Calculate total hours and minutes based on timestamps
                      Duration totalDuration = Duration();
                      for (var data in userData) {
                        DateTime startTime = data['startTime'].toDate();
                        DateTime endTime = data['endTime'].toDate();
                        totalDuration += endTime.difference(startTime);
                      }

                      int totalHours = totalDuration.inHours;
                      int totalMinutes = totalDuration.inMinutes % 60;

                      return FutureBuilder<String?>(
                        future: _getUserName(userId),
                        builder: (context, userNameSnapshot) {
                          if (userNameSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return ListTile(
                              title: Text('Loading...'),
                            );
                          }
                          if (userNameSnapshot.hasError ||
                              !userNameSnapshot.hasData) {
                            return ListTile(
                              title: Text('User ID: $userId'),
                            );
                          }

                          String userName = userNameSnapshot.data!;

                          return ExpansionTile(
                            title: Text(
                                'User Name: $userName\nTotal: $totalHours hours $totalMinutes minutes'),
                            children: userData.map((data) {
                              DateTime startTime = data['startTime'].toDate();
                              DateTime endTime = data['endTime'].toDate();
                              Duration difference =
                                  endTime.difference(startTime);
                              int hours = difference.inHours;
                              int minutes = difference.inMinutes % 60;

                              return ListTile(
                                title: Text('Date: ${startTime.toLocal()}'),
                                trailing: Text(
                                    'Worked: $hours hours $minutes minutes'),
                              );
                            }).toList(),
                          );
                        },
                      );
                    }).toList(),
                  );
                } else {
                  return Center(child: Text('No data available'));
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _getFilteredStream() {
    if (selectedMonth == null) {
      return FirebaseFirestore.instance
          .collection('workingtime')
          .where('startTime', isNull: true)
          .snapshots();
    }

    final now = DateTime.now();
    final monthIndex = months.indexOf(selectedMonth!) + 1;
    final startOfMonth = DateTime(now.year, monthIndex, 1);
    final endOfMonth =
        DateTime(now.year, monthIndex + 1, 1).subtract(Duration(days: 1));

    return FirebaseFirestore.instance
        .collection('workingtime')
        .where('startTime', isGreaterThanOrEqualTo: startOfMonth)
        .where('startTime', isLessThanOrEqualTo: endOfMonth)
        .snapshots();
  }

  Future<String?> _getUserName(String userId) async {
    // Check if the name is already in the cache
    if (_userNameCache.containsKey(userId)) {
      return _userNameCache[userId];
    }

    // Fetch the user's name from the usersdetails collection
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('usersdetails')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        String userName = userDoc.get('name');
        _userNameCache[userId] = userName; // Cache the result
        return userName;
      } else {
        return 'Unknown User';
      }
    } catch (e) {
      print('Error fetching user name: $e');
      return null;
    }
  }

  void _printReport() async {
    final snapshot = await _getFilteredStream().first;
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
    Duration totalOverallDuration = Duration();

    // First Page: Summary Table with UserName and Total Hours
    List<List<String>> summaryData = [];
    for (var entry in groupedData.entries) {
      String userId = entry.key;
      List<Map<String, dynamic>> userData = entry.value;

      Duration totalDuration = Duration();
      for (var data in userData) {
        DateTime startTime = data['startTime'].toDate();
        DateTime endTime = data['endTime'].toDate();
        totalDuration += endTime.difference(startTime);
      }

      totalOverallDuration += totalDuration;

      int totalHours = totalDuration.inHours;
      int totalMinutes = totalDuration.inMinutes % 60;

      final userName = await _getUserName(userId) ?? 'Unknown User';

      summaryData.add([userName, '$totalHours hours $totalMinutes minutes']);
    }

    int overallHours = totalOverallDuration.inHours;
    int overallMinutes = totalOverallDuration.inMinutes % 60;

    // Add first page with summary table
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Summary of Working Hours',
                style: pw.TextStyle(fontSize: 18)),
            pw.SizedBox(height: 10),
            pw.Table.fromTextArray(
              headers: ['User Name', 'Total'],
              data: summaryData,
            ),
            pw.SizedBox(height: 20),
            pw.Text(
                'Overall Total: $overallHours hours $overallMinutes minutes',
                style: pw.TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );

    // Second Page: Detailed data for each user
    for (var entry in groupedData.entries) {
      String userId = entry.key;
      List<Map<String, dynamic>> userData = entry.value;

      Duration totalDuration = Duration();
      for (var data in userData) {
        DateTime startTime = data['startTime'].toDate();
        DateTime endTime = data['endTime'].toDate();
        totalDuration += endTime.difference(startTime);
      }

      int totalHours = totalDuration.inHours;
      int totalMinutes = totalDuration.inMinutes % 60;

      final userName = await _getUserName(userId) ?? 'Unknown User';

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('User Name: $userName'),
              pw.Text('Total: $totalHours hours $totalMinutes minutes'),
              pw.Table.fromTextArray(
                headers: ['Start Time', 'End Time', 'Worked Time'],
                data: userData.map((data) {
                  DateTime startTime = data['startTime'].toDate();
                  DateTime endTime = data['endTime'].toDate();
                  Duration difference = endTime.difference(startTime);
                  return [
                    startTime.toLocal().toString(),
                    endTime.toLocal().toString(),
                    '${difference.inHours} hours ${difference.inMinutes % 60} minutes',
                  ];
                }).toList(),
              ),
            ],
          ),
        ),
      );
    }

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}
