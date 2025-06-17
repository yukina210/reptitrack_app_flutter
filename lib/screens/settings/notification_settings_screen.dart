// lib/screens/settings/notification_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/notification_customization_service.dart';
import '../../services/settings_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  late NotificationCustomizationService _customizationService;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    _customizationService = NotificationCustomizationService();
    await _customizationService.initialize();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsService = Provider.of<SettingsService>(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            settingsService.getText(
              'notification_settings',
              'Notification Settings',
            ),
          ),
          backgroundColor: Colors.green,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          settingsService.getText(
            'notification_settings',
            'Notification Settings',
          ),
        ),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => _resetToDefaults(settingsService),
            tooltip: settingsService.getText(
              'reset_defaults',
              'Reset to Defaults',
            ),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Sound Settings
          _buildSoundSettings(settingsService),
          SizedBox(height: 24),

          // Priority Settings
          _buildPrioritySettings(settingsService),
          SizedBox(height: 24),

          // Style Settings
          _buildStyleSettings(settingsService),
          SizedBox(height: 24),

          // Quiet Hours Settings
          _buildQuietHoursSettings(settingsService),
          SizedBox(height: 24),

          // Vibration & LED Settings
          _buildVibrLedSettings(settingsService),
          SizedBox(height: 24),

          // Snooze Settings
          _buildSnoozeSettings(settingsService),
          SizedBox(height: 24),

          // Test Notification
          _buildTestNotification(settingsService),
        ],
      ),
    );
  }

  Widget _buildSoundSettings(SettingsService settingsService) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.volume_up, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  settingsService.getText(
                    'notification_sound',
                    'Notification Sound',
                  ),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 16),
            ...NotificationSound.values.map((sound) {
              return RadioListTile<NotificationSound>(
                title: Text(
                  NotificationCustomizationService.getSoundText(
                    sound,
                    isJapanese:
                        settingsService.currentLanguage == AppLanguage.japanese,
                  ),
                ),
                value: sound,
                groupValue: _customizationService.notificationSound,
                onChanged: (NotificationSound? value) async {
                  if (value != null) {
                    await _customizationService.setNotificationSound(value);
                    if (mounted) {
                      setState(() {});
                    }
                  }
                },
                activeColor: Colors.green,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPrioritySettings(SettingsService settingsService) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.priority_high, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  settingsService.getText(
                    'notification_priority',
                    'Notification Priority',
                  ),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              settingsService.getText(
                'priority_description',
                'Higher priority notifications appear more prominently',
              ),
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            SizedBox(height: 16),
            ...NotificationPriority.values.map((priority) {
              return RadioListTile<NotificationPriority>(
                title: Text(
                  NotificationCustomizationService.getPriorityText(
                    priority,
                    isJapanese:
                        settingsService.currentLanguage == AppLanguage.japanese,
                  ),
                ),
                value: priority,
                groupValue: _customizationService.notificationPriority,
                onChanged: (NotificationPriority? value) async {
                  if (value != null) {
                    await _customizationService.setNotificationPriority(value);
                    if (mounted) {
                      setState(() {});
                    }
                  }
                },
                activeColor: Colors.green,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildStyleSettings(SettingsService settingsService) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.style, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  settingsService.getText(
                    'notification_style',
                    'Notification Style',
                  ),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              settingsService.getText(
                'style_description',
                'Choose how much information to show in notifications',
              ),
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            SizedBox(height: 16),
            ...NotificationStyle.values.map((style) {
              return RadioListTile<NotificationStyle>(
                title: Text(
                  NotificationCustomizationService.getStyleText(
                    style,
                    isJapanese:
                        settingsService.currentLanguage == AppLanguage.japanese,
                  ),
                ),
                subtitle: Text(_getStyleDescription(style, settingsService)),
                value: style,
                groupValue: _customizationService.notificationStyle,
                onChanged: (NotificationStyle? value) async {
                  if (value != null) {
                    await _customizationService.setNotificationStyle(value);
                    if (mounted) {
                      setState(() {});
                    }
                  }
                },
                activeColor: Colors.green,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildQuietHoursSettings(SettingsService settingsService) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.nightlight_round, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  settingsService.getText('quiet_hours', 'Quiet Hours'),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              settingsService.getText(
                'quiet_hours_description',
                'Disable notifications during specific hours',
              ),
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            SizedBox(height: 16),
            SwitchListTile(
              title: Text(
                settingsService.getText(
                  'enable_quiet_hours',
                  'Enable Quiet Hours',
                ),
              ),
              value: _customizationService.isQuietHoursEnabled,
              onChanged: (bool value) async {
                await _customizationService.setQuietHoursEnabled(value);
                if (mounted) {
                  setState(() {});
                }
              },
              activeColor: Colors.green,
            ),
            if (_customizationService.isQuietHoursEnabled) ...[
              ListTile(
                title: Text(
                  settingsService.getText('start_time', 'Start Time'),
                ),
                subtitle: Text(
                  _customizationService.quietHoursStart.format(context),
                ),
                trailing: Icon(Icons.access_time),
                onTap: () => _selectQuietHoursTime(true, settingsService),
              ),
              ListTile(
                title: Text(settingsService.getText('end_time', 'End Time')),
                subtitle: Text(
                  _customizationService.quietHoursEnd.format(context),
                ),
                trailing: Icon(Icons.access_time),
                onTap: () => _selectQuietHoursTime(false, settingsService),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVibrLedSettings(SettingsService settingsService) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.vibration, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  settingsService.getText('physical_alerts', 'Physical Alerts'),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 16),
            SwitchListTile(
              title: Text(
                settingsService.getText('enable_vibration', 'Enable Vibration'),
              ),
              subtitle: Text(
                settingsService.getText(
                  'vibration_description',
                  'Vibrate when notifications arrive',
                ),
              ),
              value: _customizationService.isVibrationEnabled,
              onChanged: (bool value) async {
                await _customizationService.setVibrationEnabled(value);
                if (mounted) {
                  setState(() {});
                }
              },
              activeColor: Colors.green,
            ),
            SwitchListTile(
              title: Text(
                settingsService.getText('enable_led', 'Enable LED Light'),
              ),
              subtitle: Text(
                settingsService.getText(
                  'led_description',
                  'Flash LED light for notifications (Android only)',
                ),
              ),
              value: _customizationService.isLedEnabled,
              onChanged: (bool value) async {
                await _customizationService.setLedEnabled(value);
                if (mounted) {
                  setState(() {});
                }
              },
              activeColor: Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSnoozeSettings(SettingsService settingsService) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.snooze, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  settingsService.getText('snooze_settings', 'Snooze Settings'),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 16),
            ListTile(
              title: Text(
                settingsService.getText('snooze_interval', 'Snooze Interval'),
              ),
              subtitle: Text(
                '${_customizationService.snoozeInterval} ${settingsService.getText('minutes', 'minutes')}',
              ),
              trailing: Icon(Icons.edit),
              onTap: () => _selectSnoozeInterval(settingsService),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestNotification(SettingsService settingsService) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // 修正: Icons.test_rounded を Icons.science に変更
                Icon(Icons.science, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  settingsService.getText(
                    'test_notification',
                    'Test Notification',
                  ),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              settingsService.getText(
                'test_description',
                'Send a test notification to preview your settings',
              ),
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: Icon(Icons.send),
                label: Text(
                  settingsService.getText(
                    'send_test',
                    'Send Test Notification',
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => _sendTestNotification(settingsService),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStyleDescription(
    NotificationStyle style,
    SettingsService settingsService,
  ) {
    final isJapanese = settingsService.currentLanguage == AppLanguage.japanese;

    if (isJapanese) {
      switch (style) {
        case NotificationStyle.simple:
          return 'タイトルと基本メッセージのみ';
        case NotificationStyle.detailed:
          return 'ペット名や種類などの詳細情報を含む';
        case NotificationStyle.minimal:
          return '最小限の情報のみ表示';
        case NotificationStyle.rich:
          return '絵文字とリッチフォーマット付き';
      }
    } else {
      switch (style) {
        case NotificationStyle.simple:
          return 'Title and basic message only';
        case NotificationStyle.detailed:
          return 'Includes pet name and reminder details';
        case NotificationStyle.minimal:
          return 'Minimal information only';
        case NotificationStyle.rich:
          return 'With emojis and rich formatting';
      }
    }
  }

  Future<void> _selectQuietHoursTime(
    bool isStartTime,
    SettingsService settingsService,
  ) async {
    final currentTime =
        isStartTime
            ? _customizationService.quietHoursStart
            : _customizationService.quietHoursEnd;

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: currentTime,
    );

    if (picked != null && mounted) {
      if (isStartTime) {
        await _customizationService.setQuietHoursStart(picked);
      } else {
        await _customizationService.setQuietHoursEnd(picked);
      }
      setState(() {});
    }
  }

  Future<void> _selectSnoozeInterval(SettingsService settingsService) async {
    final intervals = [5, 10, 15, 30, 60];
    final currentInterval = _customizationService.snoozeInterval;

    if (!mounted) return;

    final result = await showDialog<int>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(
              settingsService.getText(
                'select_snooze_interval',
                'Select Snooze Interval',
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  intervals.map((interval) {
                    return RadioListTile<int>(
                      title: Text(
                        '$interval ${settingsService.getText('minutes', 'minutes')}',
                      ),
                      value: interval,
                      groupValue: currentInterval,
                      onChanged: (int? value) {
                        if (value != null) {
                          Navigator.of(ctx).pop(value);
                        }
                      },
                      activeColor: Colors.green,
                    );
                  }).toList(),
            ),
            actions: [
              TextButton(
                child: Text(settingsService.getText('cancel', 'Cancel')),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
    );

    if (result != null && mounted) {
      await _customizationService.setSnoozeInterval(result);
      setState(() {});
    }
  }

  Future<void> _sendTestNotification(SettingsService settingsService) async {
    try {
      await _customizationService.sendTestNotification();
      if (mounted) {
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              settingsService.getText('test_sent', 'Test notification sent'),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _resetToDefaults(SettingsService settingsService) async {
    if (!mounted) return;

    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(
              settingsService.getText('reset_to_defaults', 'Reset to Defaults'),
            ),
            content: Text(
              settingsService.getText(
                'reset_confirmation',
                'Are you sure you want to reset all notification settings to defaults?',
              ),
            ),
            actions: [
              TextButton(
                child: Text(settingsService.getText('cancel', 'Cancel')),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
              TextButton(
                child: Text(
                  settingsService.getText('reset', 'Reset'),
                  style: TextStyle(color: Colors.red),
                ),
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  await _customizationService.resetToDefaults();
                  if (mounted) {
                    setState(() {});
                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          settingsService.getText(
                            'settings_reset',
                            'Settings reset to defaults',
                          ),
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
    );
  }
}
