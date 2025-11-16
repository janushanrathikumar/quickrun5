import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:pdf/pdf.dart'; // For PDF generation
import 'package:pdf/widgets.dart' as pw; // For PDF widgets
import 'package:printing/printing.dart'; // For printing and PDF export

class WorkingTimeScreen extends StatefulWidget {
  final String userId;

  WorkingTimeScreen({required this.userId});

  @override
  _WorkingTimeScreenState createState() => _WorkingTimeScreenState();
}

class _WorkingTimeScreenState extends State<WorkingTimeScreen> {
  int? selectedMonth;
  Future<List<Map<String, dynamic>>>? workingTimeFuture;
  Map<String, dynamic>? userDetails;

  // New variables for editing start and end times
  DateTime? editedStartTime;
  DateTime? editedEndTime;
  String? documentIdToEdit; // Store the ID of the document being edited

  @override
  void initState() {
    super.initState();
    _getUserDetails(widget.userId);
  }

  Future<void> _getUserDetails(String userId) async {
    DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
        .collection('usersdetails')
        .doc(userId)
        .get();

    setState(() {
      userDetails = userSnapshot.data() as Map<String, dynamic>?;
    });
  }

  Future<List<Map<String, dynamic>>> _getWorkingTimeDetails(
      String userId, int month) async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('workingtime')
        .where('userId', isEqualTo: userId)
        .get();

    return querySnapshot.docs
        .map((doc) => {
              'id': doc.id, // Include document ID for editing
              ...doc.data() as Map<String, dynamic>
            })
        .where((data) {
      Timestamp timestamp = data['startTime'];
      DateTime date = timestamp.toDate();
      return date.month == month;
    }).toList()
      ..sort((a, b) {
        // Sort by date
        return (a['startTime'] as Timestamp)
            .toDate()
            .compareTo((b['startTime'] as Timestamp).toDate());
      });
  }

  Future<void> _generatePdf(List<Map<String, dynamic>> data, int month) async {
    final pdf = pw.Document();
    double totalHours = 0;
    const int rowsPerPage = 12;

    // Debug: Print the data to check if it's being retrieved correctly
    print('Data for PDF generation: $data');

    // Calculate total hours
    data.forEach((record) {
      totalHours += record['differenceInHours'].toDouble();
      totalHours += record['differenceInMinutes'] / 60.0;
    });

    // Split data into chunks of 9 rows
    for (int i = 0; i < data.length; i += rowsPerPage) {
      final pageData = data.sublist(
          i, (i + rowsPerPage) < data.length ? (i + rowsPerPage) : data.length);

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Working Time Details for ${DateFormat.MMMM().format(DateTime(0, month))}',
                  style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 16),
                pw.Text('Name: ${userDetails?['name'] ?? ''}',
                    style: pw.TextStyle(fontSize: 18)),
                pw.Text('Email: ${userDetails?['email'] ?? ''}',
                    style: pw.TextStyle(fontSize: 18)),
                pw.Text('User ID: ${widget.userId}',
                    style: pw.TextStyle(fontSize: 18)),
                pw.SizedBox(height: 16),
                pw.Table.fromTextArray(
                  headers: [
                    'Date & Time',
                    'Start Time',
                    'End Time',
                    'Hours',
                    'Minutes',
                    'UserID'
                  ],
                  data: pageData.map((record) {
                    Timestamp timestamp = record['date'];
                    DateTime date = timestamp.toDate();
                    Timestamp? startTime = record['startTime'];
                    Timestamp? endTime = record['endTime'];

                    return [
                      DateFormat('MMMM d, yyyy h:mm:ss a').format(date),
                      startTime != null
                          ? DateFormat('MMMM d, yyyy h:mm:ss a')
                              .format(startTime.toDate())
                          : 'N/A',
                      endTime != null
                          ? DateFormat('MMMM d, yyyy h:mm:ss a')
                              .format(endTime.toDate())
                          : 'N/A',
                      record['differenceInHours'].toString(),
                      record['differenceInMinutes'].toString(),
                      record['userId'].toString(),
                    ];
                  }).toList(),
                ),
                pw.SizedBox(height: 16),
                pw.Text('Total Hours: ${totalHours.toStringAsFixed(2)}',
                    style: pw.TextStyle(
                        fontSize: 18, fontWeight: pw.FontWeight.bold)),
              ],
            );
          },
        ),
      );
    }

    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save());
  }

  // Function to update Firestore document with new start and end times
  Future<void> _updateWorkingTime(String docId) async {
    if (documentIdToEdit != null &&
        editedStartTime != null &&
        editedEndTime != null) {
      // Calculate difference in hours and minutes
      Duration difference = editedEndTime!.difference(editedStartTime!);
      double differenceInHours = difference.inHours.toDouble();
      int differenceInMinutes = difference.inMinutes.remainder(60);

      await FirebaseFirestore.instance
          .collection('workingtime')
          .doc(docId)
          .update({
        'startTime': Timestamp.fromDate(editedStartTime!),
        'endTime': Timestamp.fromDate(editedEndTime!),
        'differenceInHours': differenceInHours,
        'differenceInMinutes': differenceInMinutes,
      });
      setState(() {
        editedStartTime = null;
        editedEndTime = null;
        documentIdToEdit = null; // Clear the editing document ID
      });
    }
  }

  // Function to delete a Firestore document
  Future<void> _deleteWorkingTime(String docId) async {
    if (docId != null) {
      await FirebaseFirestore.instance
          .collection('workingtime')
          .doc(docId)
          .delete();
      setState(() {
        editedStartTime = null;
        editedEndTime = null;
        documentIdToEdit = null; // Clear the editing document ID
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Working Time Details"),
      ),
      body: Column(
        children: [
          if (userDetails != null) ...[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Name: ${userDetails!['name']}",
                      style: TextStyle(fontSize: 18)),
                  Text("Email: ${userDetails!['email']}",
                      style: TextStyle(fontSize: 18)),
                  Text("User ID: ${widget.userId}",
                      style: TextStyle(fontSize: 18)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: DropdownButton<int>(
                hint: Text("Select Month"),
                value: selectedMonth,
                items: List.generate(
                    12,
                    (index) => DropdownMenuItem(
                          child: Text(
                              DateFormat.MMMM().format(DateTime(0, index + 1))),
                          value: index + 1,
                        )),
                onChanged: (value) {
                  setState(() {
                    selectedMonth = value;
                    if (value != null) {
                      workingTimeFuture =
                          _getWorkingTimeDetails(widget.userId, value);
                    }
                  });
                },
              ),
            ),
          ],
          if (selectedMonth != null)
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: workingTimeFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                        child: Text(
                            "No working time records found for the selected month"));
                  } else {
                    final workingTimeData = snapshot.data!;
                    int totalMinutes = 0;

                    workingTimeData.forEach((record) {
                      int hours = (record['differenceInHours'] is double
                              ? (record['differenceInHours'] as double).toInt()
                              : record['differenceInHours'] as int) *
                          60;
                      int minutes = (record['differenceInMinutes'] is double
                          ? (record['differenceInMinutes'] as double).toInt()
                          : record['differenceInMinutes'] as int);

                      totalMinutes += hours + minutes;
                    });

                    int hours = totalMinutes ~/ 60;
                    int minutes = totalMinutes % 60;

                    return Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SingleChildScrollView(
                              child: DataTable(
                                columns: [
                                  DataColumn(label: Text("Date & Time")),
                                  DataColumn(label: Text("Start Time")),
                                  DataColumn(label: Text("End Time")),
                                  DataColumn(label: Text("Hours")),
                                  DataColumn(label: Text("Minutes")),
                                  DataColumn(label: Text("UserID")),
                                  DataColumn(label: Text("Edit")),
                                ],
                                rows: workingTimeData.map((record) {
                                  Timestamp timestamp = record['date'];
                                  DateTime date = timestamp.toDate();
                                  Timestamp? startTime = record['startTime'];
                                  Timestamp? endTime = record['endTime'];

                                  return DataRow(
                                    cells: [
                                      DataCell(Text(
                                          DateFormat('MMMM d, yyyy h:mm:ss a')
                                              .format(date))),
                                      DataCell(Text(startTime != null
                                          ? DateFormat('MMMM d, yyyy h:mm:ss a')
                                              .format(startTime.toDate())
                                          : 'N/A')),
                                      DataCell(Text(endTime != null
                                          ? DateFormat('MMMM d, yyyy h:mm:ss a')
                                              .format(endTime.toDate())
                                          : 'N/A')),
                                      DataCell(Text(record['differenceInHours']
                                          .toString())),
                                      DataCell(Text(
                                          record['differenceInMinutes']
                                              .toString())),
                                      DataCell(
                                          Text(record['userId'].toString())),
                                      DataCell(
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: Icon(Icons.edit),
                                              onPressed: () {
                                                // Start editing
                                                setState(() {
                                                  documentIdToEdit =
                                                      record['id'];
                                                  editedStartTime =
                                                      startTime?.toDate();
                                                  editedEndTime =
                                                      endTime?.toDate();
                                                });
                                              },
                                            ),
                                            IconButton(
                                              icon: Icon(Icons.delete),
                                              onPressed: () {
                                                // Start deleting
                                                if (record['id'] != null) {
                                                  _deleteWorkingTime(
                                                      record['id']);
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            "Total Hours: $hours hours $minutes minutes",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            _generatePdf(workingTimeData, selectedMonth!);
                          },
                          child: Text('Download as PDF'),
                        ),
                        if (documentIdToEdit != null) ...[
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Text("Edit Start Time:"),
                                TextField(
                                  readOnly: true, // Prevent manual input
                                  onTap: () async {
                                    DateTime? newStartTime =
                                        await showDateTimePicker(
                                            context, editedStartTime);
                                    if (newStartTime != null) {
                                      setState(() {
                                        editedStartTime = newStartTime;
                                      });
                                    }
                                  },
                                  decoration: InputDecoration(
                                    labelText:
                                        DateFormat('MMMM d, yyyy h:mm:ss a')
                                            .format(editedStartTime!),
                                  ),
                                ),
                                Text("Edit End Time:"),
                                TextField(
                                  readOnly: true, // Prevent manual input
                                  onTap: () async {
                                    DateTime? newEndTime =
                                        await showDateTimePicker(
                                            context, editedEndTime);
                                    if (newEndTime != null) {
                                      setState(() {
                                        editedEndTime = newEndTime;
                                      });
                                    }
                                  },
                                  decoration: InputDecoration(
                                    labelText:
                                        DateFormat('MMMM d, yyyy h:mm:ss a')
                                            .format(editedEndTime!),
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () {
                                        if (documentIdToEdit != null) {
                                          _updateWorkingTime(documentIdToEdit!);
                                        }
                                      },
                                      child: Text('Update Times'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        if (documentIdToEdit != null) {
                                          _deleteWorkingTime(documentIdToEdit!);
                                        }
                                      },
                                      child: Text('Delete'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    );
                  }
                },
              ),
            ),
        ],
      ),
    );
  }

  Future<DateTime?> showDateTimePicker(
      BuildContext context, DateTime? initialDate) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate ?? DateTime.now()),
      );

      if (pickedTime != null) {
        return DateTime(pickedDate.year, pickedDate.month, pickedDate.day,
            pickedTime.hour, pickedTime.minute);
      }
    }
    return null;
  }
}
