import 'package:flutter/material.dart';

class DownloadPage extends StatelessWidget {
  final List<Map<String, dynamic>> userData;

  DownloadPage({required this.userData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Download PDF'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Table(
          border: TableBorder.all(),
          columnWidths: const {
            0: FlexColumnWidth(1),
            1: FlexColumnWidth(1),
          },
          children: [
            TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('User Name',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('Total Hours',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            ...userData.map((data) {
              return TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(data['name']),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('${data['totalHours']} hours'),
                  ),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
