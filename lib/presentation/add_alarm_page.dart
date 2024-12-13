import 'package:alarmco/services/db_helper.dart';
import 'package:alarmco/services/notification_helper.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AddAlarmPage extends StatefulWidget {
  final Map<String, dynamic>? alarm; // Optional parameter for editing

  AddAlarmPage({this.alarm});

  @override
  State<AddAlarmPage> createState() => _AddAlarmPageState();
}

class _AddAlarmPageState extends State<AddAlarmPage> {
  TimeOfDay? _selectedTime;
  String _repeatOption = 'No Repeat';
  final List<String> _repeatOptions = ['No Repeat', 'Daily', 'Custom'];

  @override
  void initState() {
    super.initState();
    if (widget.alarm != null) {
      final parsedTime = DateFormat('hh:mm a').parse(widget.alarm!['time']);
      _selectedTime = TimeOfDay.fromDateTime(parsedTime);
      _repeatOption = widget.alarm!['repeat'];
    }
  }

  void _saveAlarm() async {
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a time.')),
      );
      return;
    }

    final alarm = {
      'time': _selectedTime!.format(context),
      'repeat': _repeatOption,
      'isEnabled': 1,
    };

    if (widget.alarm == null) {
      // Insert new alarm
      final int alarmId = await DBHelper.insertAlarm(alarm);

      // Schedule notification logic
      final now = DateTime.now();
      final scheduledTime = DateTime(
        now.year,
        now.month,
        now.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      await NotificationHelper.scheduleNotification(
        id: alarmId,
        title: 'Alarm',
        body: 'Your alarm is ringing!',
        scheduledTime: scheduledTime.isBefore(now)
            ? scheduledTime.add(Duration(days: 1))
            : scheduledTime,
      );
    } else {
      // Update existing alarm
      await DBHelper.updateAlarm(widget.alarm!['id'], alarm);

      // Cancel the old notification and reschedule with the new time
      await NotificationHelper.cancelNotification(widget.alarm!['id']);

      final now = DateTime.now();
      final scheduledTime = DateTime(
        now.year,
        now.month,
        now.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      await NotificationHelper.scheduleNotification(
        id: widget.alarm!['id'],
        title: 'Alarm',
        body: 'Your alarm is ringing!',
        scheduledTime: scheduledTime.isBefore(now)
            ? scheduledTime.add(Duration(days: 1))
            : scheduledTime,
      );
    }

    Navigator.pop(
        context, true); // Indicate the alarm has been added or updated
  }

  void _selectCustomDays() {
    // Implement UI for selecting specific days for "Custom" repeat
    showDialog(
      context: context,
      builder: (context) {
        final List<String> days = [
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday',
          'Saturday',
          'Sunday'
        ];
        final Set<String> selectedDays = {};

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Select Days'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: days.map((day) {
                  return CheckboxListTile(
                    title: Text(day),
                    value: selectedDays.contains(day),
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          selectedDays.add(day);
                        } else {
                          selectedDays.remove(day);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _repeatOption = selectedDays.isNotEmpty
                          ? selectedDays.join(', ')
                          : 'Custom';
                    });
                    Navigator.pop(context);
                  },
                  child: Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.alarm == null ? 'Add Alarm' : 'Edit Alarm'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Time Picker
            ListTile(
              title: Text(
                  'Time: ${_selectedTime?.format(context) ?? 'Not selected'}'),
              trailing: Icon(Icons.access_time),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (time != null) {
                  setState(() {
                    _selectedTime = time;
                  });
                }
              },
            ),

            // Repeat Options
            ListTile(
              title: Text('Repeat: $_repeatOption'),
              trailing: Icon(Icons.repeat),
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) {
                    return ListView(
                      children: _repeatOptions.map((option) {
                        return ListTile(
                          title: Text(option),
                          onTap: () {
                            setState(() {
                              _repeatOption = option;
                            });
                            Navigator.pop(context);
                            if (option == 'Custom') {
                              _selectCustomDays();
                            }
                          },
                        );
                      }).toList(),
                    );
                  },
                );
              },
            ),

            Spacer(), // Add some space

            // Save Button
            ElevatedButton(
              onPressed: _saveAlarm,
              child: Text(widget.alarm == null ? 'Save Alarm' : 'Update Alarm'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
