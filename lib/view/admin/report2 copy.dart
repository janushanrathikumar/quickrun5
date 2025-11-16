import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'download.dart'; // Import the download.dart page

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

  final Map<String, String> _userNameCache = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Working Time Data'),
        actions: [
          IconButton(
            icon: Icon(Icons.picture_as_pdf),
            onPressed: () async {
              List<Map<String, dynamic>> userData = await _fetchUserData();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DownloadPage(userData: userData),
                ),
              );
            },
          ),
        ],
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

                      int totalHours = 0;
                      int totalMinutes = 0;

                      for (var data in userData) {
                        totalHours +=
                            (data['differenceInHours'] as num).toInt();
                        totalMinutes +=
                            (data['differenceInMinutes'] as num).toInt();
                      }

                      totalHours += totalMinutes ~/ 60;
                      totalMinutes = totalMinutes % 60;

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
                              return ListTile(
                                title: Text(
                                    'Date: ${data['date'].toDate().toString()}'),
                                trailing: Text(
                                    'Total hours: ${data['differenceInHours']} hours ${data['differenceInMinutes']} minutes'),
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
          .where('date', isNull: true)
          .snapshots();
    }

    final now = DateTime.now();
    final monthIndex = months.indexOf(selectedMonth!) + 1;
    final startOfMonth = DateTime(now.year, monthIndex, 1);
    final endOfMonth =
        DateTime(now.year, monthIndex + 1, 1).subtract(Duration(days: 1));

    return FirebaseFirestore.instance
        .collection('workingtime')
        .where('date', isGreaterThanOrEqualTo: startOfMonth)
        .where('date', isLessThanOrEqualTo: endOfMonth)
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
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> _fetchUserData() async {
    List<Map<String, dynamic>> userDataList = [];

    QuerySnapshot snapshot = await _getFilteredStream().first;
    final Map<String, List<Map<String, dynamic>>> groupedData = {};

    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      String userId = data['userId'];
      if (groupedData[userId] == null) {
        groupedData[userId] = [];
      }
      groupedData[userId]!.add(data);
    }

    for (var entry in groupedData.entries) {
      String userId = entry.key;
      List<Map<String, dynamic>> userData = entry.value;

      int totalHours = 0;
      int totalMinutes = 0;

      for (var data in userData) {
        totalHours += (data['differenceInHours'] as num).toInt();
        totalMinutes += (data['differenceInMinutes'] as num).toInt();
      }

      totalHours += totalMinutes ~/ 60;
      totalMinutes = totalMinutes % 60;

      String? userName = await _getUserName(userId);

      userDataList.add({
        'name': userName ?? 'Unknown User',
        'totalHours': totalHours,
        'totalMinutes': totalMinutes,
      });
    }

    return userDataList;
  }
}
