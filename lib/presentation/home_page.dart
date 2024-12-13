import 'package:alarmco/presentation/add_alarm_page.dart';
import 'package:alarmco/services/db_helper.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> _alarms = [];
  bool _isLoading = true;

  Future<void> _fetchAlarms() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final alarms = await DBHelper.getAlarms();
      setState(() {
        _alarms = alarms;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching alarms: $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchAlarms();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Alarm List'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _alarms.length,
              itemBuilder: (context, index) {
                final alarm = _alarms[index];
                return ListTile(
                  title: Text(alarm['time']),
                  subtitle: Text(alarm['repeat']),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: alarm['isEnabled'] == 1,
                        onChanged: (value) async {
                          try {
                            final updatedAlarm = {
                              ...alarm,
                              'isEnabled': value ? 1 : 0
                            };
                            await DBHelper.updateAlarm(
                                alarm['id'], updatedAlarm);
                            _fetchAlarms();
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Error updating alarm: $e')),
                            );
                          }
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () async {
                          final isAlarmUpdated = await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    AddAlarmPage(alarm: alarm)),
                          );
                          if (isAlarmUpdated == true) {
                            _fetchAlarms();
                          }
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () async {
                          try {
                            await DBHelper.deleteAlarm(alarm['id']);
                            _fetchAlarms();
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Error deleting alarm: $e')),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final isAlarmAdded = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddAlarmPage()),
          );
          if (isAlarmAdded == true) {
            _fetchAlarms(); // Refresh alarm list after new alarm is added
          }
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
