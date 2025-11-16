import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AddTimePage extends StatefulWidget {
  final String userId;

  AddTimePage({required this.userId});

  @override
  _AddTimePageState createState() => _AddTimePageState();
}

class _AddTimePageState extends State<AddTimePage> {
  DateTime? _startTime;
  DateTime? _endTime;

  void _selectTime(BuildContext context, bool isStartTime) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != DateTime.now()) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (pickedTime != null) {
        setState(() {
          final selectedDateTime = DateTime(
            picked.year,
            picked.month,
            picked.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          if (isStartTime) {
            _startTime = selectedDateTime;
          } else {
            _endTime = selectedDateTime;
          }
        });
      }
    }
  }

  void _saveData() async {
    if (_startTime != null && _endTime != null) {
      final difference = _endTime!.difference(_startTime!);
      final differenceInHours = difference.inHours;
      final differenceInMinutes = difference.inMinutes % 60;

      final workingTimeRef =
          FirebaseFirestore.instance.collection('workingtime').doc();

      await workingTimeRef.set({
        'date': Timestamp.fromDate(
            _endTime!), // Set the date field to the value of endTime
        'endTime': Timestamp.fromDate(_endTime!),
        'startTime': Timestamp.fromDate(_startTime!),
        'differenceInHours': differenceInHours,
        'differenceInMinutes': differenceInMinutes,
        'userId': widget.userId,
      });

      Navigator.pop(context);
    } else {
      // Show error or message that both times need to be selected
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final localTime = dateTime.toLocal(); // Convert to local time
    return DateFormat('MMMM d, yyyy \'at\' h:mm:ss a').format(localTime) +
        ' UTC${DateTime.now().timeZoneOffset.inHours >= 0 ? '+' : '-'}' +
        DateTime.now()
            .timeZoneOffset
            .toString()
            .substring(0, 5); // Add timezone offset
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add Time"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                    "Start Time: ${_startTime != null ? _formatDateTime(_startTime!) : 'Not selected'}"),
                IconButton(
                  icon: Icon(Icons.access_time),
                  onPressed: () => _selectTime(context, true),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                    "End Time: ${_endTime != null ? _formatDateTime(_endTime!) : 'Not selected'}"),
                IconButton(
                  icon: Icon(Icons.access_time),
                  onPressed: () => _selectTime(context, false),
                ),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveData,
              child: Text("Save"),
            ),
          ],
        ),
      ),
    );
  }
}
