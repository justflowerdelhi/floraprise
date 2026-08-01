import 'package:flutter/material.dart';
import '../models/smart_alert.dart';
import '../services/smart_alert_engine.dart';

class AlertSettingsScreen extends StatefulWidget {
  const AlertSettingsScreen({super.key});

  @override
  State<AlertSettingsScreen> createState() => _AlertSettingsScreenState();
}

class _AlertSettingsScreenState extends State<AlertSettingsScreen> {
  final SmartAlertEngine _alertEngine = SmartAlertEngine.instance;
  
  late QuietHoursConfig _quietHours;
  late AlertCustomizationSettings _customization;

  @override
  void initState() {
    super.initState();
    _quietHours = _alertEngine.quietHoursConfig;
    _customization = _alertEngine.customizationSettings;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alert Settings'),
        elevation: 0,
      ),
      body: ListView(
        children: [
          _buildSectionHeader('Quiet Hours'),
          _buildQuietHoursSettings(),
          const Divider(height: 32),
          _buildSectionHeader('Sound & Vibration'),
          _buildSoundSettings(),
          const Divider(height: 32),
          _buildSectionHeader('Advanced'),
          _buildAdvancedSettings(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
      ),
    );
  }

  Widget _buildQuietHoursSettings() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Enable Quiet Hours'),
            subtitle: const Text('Only critical alarms during quiet hours'),
            value: _quietHours.enabled,
            onChanged: (value) {
              setState(() {
                _quietHours = _quietHours.copyWith(enabled: value);
              });
              _saveSettings();
            },
          ),
          if (_quietHours.enabled) ...[
            const Divider(),
            ListTile(
              title: const Text('Start Time'),
              trailing: Text(
                '${_quietHours.startTime.hour.toString().padLeft(2, '0')}:${_quietHours.startTime.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: _selectStartTime,
            ),
            const Divider(),
            ListTile(
              title: const Text('End Time'),
              trailing: Text(
                '${_quietHours.endTime.hour.toString().padLeft(2, '0')}:${_quietHours.endTime.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: _selectEndTime,
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Bypass Critical Alarms'),
              subtitle: const Text('Critical alarms will still sound'),
              value: _quietHours.bypassCritical,
              onChanged: (value) {
                setState(() {
                  _quietHours = _quietHours.copyWith(bypassCritical: value);
                });
                _saveSettings();
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSoundSettings() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          ListTile(
            title: const Text('Notification Sound'),
            subtitle: Text(_customization.notificationSound),
            trailing: const Icon(Icons.chevron_right),
            onTap: _selectNotificationSound,
          ),
          const Divider(),
          ListTile(
            title: const Text('Alarm Sound'),
            subtitle: Text(_customization.alarmSound),
            trailing: const Icon(Icons.chevron_right),
            onTap: _selectAlarmSound,
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Vibration'),
            subtitle: const Text('Enable vibration for alerts'),
            value: _customization.vibrationEnabled,
            onChanged: (value) {
              setState(() {
                _customization = _customization.copyWith(vibrationEnabled: value);
              });
              _saveSettings();
            },
          ),
          if (_customization.vibrationEnabled) ...[
            const Divider(),
            ListTile(
              title: const Text('Alarm Volume'),
              subtitle: Text('${(_customization.alarmVolume * 100).toInt()}%'),
              trailing: Slider(
                value: _customization.alarmVolume,
                min: 0.0,
                max: 1.0,
                divisions: 10,
                onChanged: (value) {
                  setState(() {
                    _customization = _customization.copyWith(alarmVolume: value);
                  });
                  _saveSettings();
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAdvancedSettings() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          ListTile(
            title: const Text('Escalation Delay'),
            subtitle: Text('${_customization.escalationDelay.inSeconds} seconds before alarm'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _selectEscalationDelay,
          ),
          const Divider(),
          ListTile(
            title: const Text('Repeat Interval'),
            subtitle: Text('Every ${_customization.repeatInterval.inMinutes} minutes'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _selectRepeatInterval,
          ),
          const Divider(),
          ListTile(
            title: const Text('Test Critical Alarm'),
            subtitle: const Text('Trigger a test alarm'),
            trailing: const Icon(Icons.play_arrow),
            onTap: _testAlarm,
          ),
        ],
      ),
    );
  }

  Future<void> _selectStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: _quietHours.startTime.hour,
        minute: _quietHours.startTime.minute,
      ),
    );
    if (picked != null) {
      setState(() {
        _quietHours = _quietHours.copyWith(
          startTime: TimeOfDay(hour: picked.hour, minute: picked.minute),
        );
      });
      _saveSettings();
    }
  }

  Future<void> _selectEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: _quietHours.endTime.hour,
        minute: _quietHours.endTime.minute,
      ),
    );
    if (picked != null) {
      setState(() {
        _quietHours = _quietHours.copyWith(
          endTime: TimeOfDay(hour: picked.hour, minute: picked.minute),
        );
      });
      _saveSettings();
    }
  }

  Future<void> _selectNotificationSound() async {
    final sounds = ['default', 'chime', 'bell', 'gentle'];
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => ListView.builder(
        itemCount: sounds.length,
        itemBuilder: (context, index) {
          final sound = sounds[index];
          return ListTile(
            title: Text(sound[0].toUpperCase() + sound.substring(1)),
            trailing: _customization.notificationSound == sound
                ? const Icon(Icons.check, color: Colors.green)
                : null,
            onTap: () => Navigator.pop(context, sound),
          );
        },
      ),
    );
    if (selected != null) {
      setState(() {
        _customization = _customization.copyWith(notificationSound: selected);
      });
      _saveSettings();
    }
  }

  Future<void> _selectAlarmSound() async {
    final sounds = ['alarm', 'emergency', 'siren', 'alert'];
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => ListView.builder(
        itemCount: sounds.length,
        itemBuilder: (context, index) {
          final sound = sounds[index];
          return ListTile(
            title: Text(sound[0].toUpperCase() + sound.substring(1)),
            trailing: _customization.alarmSound == sound
                ? const Icon(Icons.check, color: Colors.green)
                : null,
            onTap: () => Navigator.pop(context, sound),
          );
        },
      ),
    );
    if (selected != null) {
      setState(() {
        _customization = _customization.copyWith(alarmSound: selected);
      });
      _saveSettings();
    }
  }

  Future<void> _selectEscalationDelay() async {
    final delays = [15, 30, 45, 60];
    final selected = await showModalBottomSheet<int>(
      context: context,
      builder: (context) => ListView.builder(
        itemCount: delays.length,
        itemBuilder: (context, index) {
          final delay = delays[index];
          return ListTile(
            title: Text('$delay seconds'),
            trailing: _customization.escalationDelay.inSeconds == delay
                ? const Icon(Icons.check, color: Colors.green)
                : null,
            onTap: () => Navigator.pop(context, delay),
          );
        },
      ),
    );
    if (selected != null) {
      setState(() {
        _customization = _customization.copyWith(
          escalationDelay: Duration(seconds: selected),
        );
      });
      _saveSettings();
    }
  }

  Future<void> _selectRepeatInterval() async {
    final intervals = [3, 5, 10, 15];
    final selected = await showModalBottomSheet<int>(
      context: context,
      builder: (context) => ListView.builder(
        itemCount: intervals.length,
        itemBuilder: (context, index) {
          final interval = intervals[index];
          return ListTile(
            title: Text('$interval minutes'),
            trailing: _customization.repeatInterval.inMinutes == interval
                ? const Icon(Icons.check, color: Colors.green)
                : null,
            onTap: () => Navigator.pop(context, interval),
          );
        },
      ),
    );
    if (selected != null) {
      setState(() {
        _customization = _customization.copyWith(
          repeatInterval: Duration(minutes: selected),
        );
      });
      _saveSettings();
    }
  }

  Future<void> _testAlarm() async {
    // TODO: Implement test alarm
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Test alarm triggered')),
    );
  }

  Future<void> _saveSettings() async {
    await _alertEngine.saveSettings(
      quietHours: _quietHours,
      customization: _customization,
    );
  }
}
