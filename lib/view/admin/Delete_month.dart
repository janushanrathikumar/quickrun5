import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DeleteMonth extends StatefulWidget {
  @override
  _DeleteMonthState createState() => _DeleteMonthState();
}

class _DeleteMonthState extends State<DeleteMonth> {
  String? selectedMonth;
  List<String> months = [];
  List<DocumentSnapshot> monthData = [];

  @override
  void initState() {
    super.initState();
    _generateMonths();
  }

  // Function to generate list of months
  void _generateMonths() {
    final now = DateTime.now();
    final DateFormat formatter = DateFormat('MMMM yyyy');
    for (int i = 0; i < 12; i++) {
      final DateTime date = DateTime(now.year, now.month - i, now.day);
      months.add(formatter.format(date));
    }
    setState(() {});
  }

  // Function to fetch data based on the selected month
  Future<void> _fetchMonthData() async {
    if (selectedMonth == null) return;

    final QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('workingtime').get();

    // Filter data based on the selected month
    setState(() {
      monthData = snapshot.docs.where((doc) {
        final Timestamp date = doc['date'];
        final String formattedDate =
            DateFormat('MMMM yyyy').format(date.toDate());
        return formattedDate == selectedMonth;
      }).toList();
    });
  }

  // Function to delete all data for the selected month
  Future<void> _deleteAllMonthData() async {
    if (selectedMonth == null) return;

    for (var doc in monthData) {
      await FirebaseFirestore.instance
          .collection('workingtime')
          .doc(doc.id)
          .delete();
    }

    setState(() {
      monthData.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('All data for $selectedMonth deleted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Delete Month Report'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dropdown for selecting the month
            DropdownButton<String>(
              hint: Text('Select Month'),
              value: selectedMonth,
              isExpanded: true,
              items: months.map((String month) {
                return DropdownMenuItem<String>(
                  value: month,
                  child: Text(month),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  selectedMonth = newValue;
                });
                _fetchMonthData(); // Fetch the data when a month is selected
              },
            ),
            SizedBox(height: 20),

            // "Delete All Data for Month" button
            selectedMonth != null
                ? ElevatedButton(
                    onPressed: monthData.isNotEmpty
                        ? () {
                            _deleteAllMonthData();
                          }
                        : null,
                    child: Text('Delete All Data for $selectedMonth'),
                  )
                : Container(),
            SizedBox(height: 20),

            // Display the month data
            selectedMonth != null
                ? Expanded(
                    child: monthData.isNotEmpty
                        ? ListView.builder(
                            itemCount: monthData.length,
                            itemBuilder: (context, index) {
                              final doc = monthData[index];
                              final Timestamp startTime = doc['startTime'];
                              final Timestamp endTime = doc['endTime'];
                              final differenceInHours =
                                  doc['differenceInHours'];
                              final differenceInMinutes =
                                  doc['differenceInMinutes'];

                              return Card(
                                child: ListTile(
                                  title: Text(
                                    'Start Time: ${DateFormat.yMMMd().add_jm().format(startTime.toDate())}\n'
                                    'End Time: ${DateFormat.yMMMd().add_jm().format(endTime.toDate())}',
                                  ),
                                  subtitle: Text(
                                    'Duration: $differenceInHours hours, $differenceInMinutes minutes',
                                  ),
                                  trailing: IconButton(
                                    icon: Icon(Icons.delete),
                                    onPressed: () async {
                                      // Functionality to delete the specific record
                                      await FirebaseFirestore.instance
                                          .collection('workingtime')
                                          .doc(doc.id)
                                          .delete();
                                      _fetchMonthData();
                                    },
                                  ),
                                ),
                              );
                            },
                          )
                        : Center(
                            child: Text('No data available for $selectedMonth'),
                          ),
                  )
                : Center(child: Text('Please select a month to view data')),
          ],
        ),
      ),
    );
  }
}
