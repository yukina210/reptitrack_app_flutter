// lib/widgets/pet_notification_section.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/pet.dart';
import '../models/notification_reminder.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';
import '../services/settings_service.dart';
import '../screens/notifications/notification_form_screen.dart';

class PetNotificationSection extends StatefulWidget {
  final Pet pet;

  const PetNotificationSection({super.key, required this.pet});

  @override
  State<PetNotificationSection> createState() => _PetNotificationSectionState();
}

class _PetNotificationSectionState extends State<PetNotificationSection> {
  NotificationService? _notificationService;

  @override
  void initState() {
    super.initState();
    _initializeNotificationService();
  }

  void _initializeNotificationService() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final settingsService = Provider.of<SettingsService>(
      context,
      listen: false,
    );

    if (authService.currentUser != null) {
      _notificationService = NotificationService(
        userId: authService.currentUser!.uid,
        settingsService: settingsService,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsService = Provider.of<SettingsService>(context);

    if (_notificationService == null) {
      return SizedBox.shrink();
    }

    return ChangeNotifierProvider.value(
      value: _notificationService!,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(settingsService),
          SizedBox(height: 16),
          _buildRemindersStream(settingsService),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(SettingsService settingsService) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.notifications, color: Colors.green),
            SizedBox(width: 8),
            Text(
              settingsService.getText('reminders', 'Reminders'),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        TextButton.icon(
          icon: Icon(Icons.add, size: 18),
          label: Text(settingsService.getText('add', 'Add')),
          onPressed: () => _showAddReminderScreen(settingsService),
        ),
      ],
    );
  }

  Widget _buildRemindersStream(SettingsService settingsService) {
    return StreamBuilder<List<NotificationReminder>>(
      stream: _notificationService!.getRemindersForPet(widget.pet.id!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Card(
            color: Colors.red[50],
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '${settingsService.getText('error', 'Error')}: ${snapshot.error}',
                style: TextStyle(color: Colors.red[700]),
              ),
            ),
          );
        }

        final reminders = snapshot.data ?? [];

        if (reminders.isEmpty) {
          return Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(Icons.notifications_none, size: 48, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    settingsService.getText(
                      'no_reminders_set',
                      'No reminders set for this pet',
                    ),
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: Icon(Icons.add),
                    label: Text(
                      settingsService.getText(
                        'create_reminder',
                        'Create Reminder',
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    onPressed: () => _showAddReminderScreen(settingsService),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: [
            ...reminders.map(
              (reminder) => _buildReminderCard(reminder, settingsService),
            ),
            SizedBox(height: 12),
            TextButton.icon(
              icon: Icon(Icons.add, color: Colors.green),
              label: Text(
                settingsService.getText(
                  'add_another_reminder',
                  'Add Another Reminder',
                ),
                style: TextStyle(color: Colors.green),
              ),
              onPressed: () => _showAddReminderScreen(settingsService),
            ),
          ],
        );
      },
    );
  }

  Widget _buildReminderCard(
    NotificationReminder reminder,
    SettingsService settingsService,
  ) {
    final nextScheduled = reminder.getNextScheduledTime();
    final isOverdue = nextScheduled.isBefore(DateTime.now());
    final isToday = _isSameDay(nextScheduled, DateTime.now());

    return Card(
      margin: EdgeInsets.only(bottom: 8),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: reminder.getColor().withValues(alpha: 0.2),
          child: Icon(reminder.getIcon(), color: reminder.getColor(), size: 20),
        ),
        title: Text(
          reminder.title,
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 14,
                  color:
                      isOverdue
                          ? Colors.red
                          : isToday
                          ? Colors.orange
                          : Colors.grey[600],
                ),
                SizedBox(width: 4),
                Text(
                  _formatNextScheduled(nextScheduled, settingsService),
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        isOverdue
                            ? Colors.red
                            : isToday
                            ? Colors.orange
                            : Colors.grey[600],
                    fontWeight:
                        isOverdue || isToday
                            ? FontWeight.bold
                            : FontWeight.normal,
                  ),
                ),
              ],
            ),
            if (reminder.repeatInterval != RepeatInterval.once) ...[
              SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.repeat, size: 14, color: Colors.grey[600]),
                  SizedBox(width: 4),
                  Text(
                    NotificationReminder.getIntervalText(
                      reminder.repeatInterval,
                      isJapanese:
                          settingsService.currentLanguage ==
                          AppLanguage.japanese,
                    ),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
            if (isOverdue) ...[
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.warning, size: 14, color: Colors.red),
                  SizedBox(width: 4),
                  Text(
                    settingsService.getText('overdue', 'Overdue'),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ] else if (isToday) ...[
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.today, size: 14, color: Colors.orange),
                  SizedBox(width: 4),
                  Text(
                    settingsService.getText('today', 'Today'),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton(
          icon: Icon(Icons.more_vert, size: 20),
          itemBuilder:
              (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 18),
                      SizedBox(width: 8),
                      Text(settingsService.getText('edit', 'Edit')),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text(
                        settingsService.getText('delete', 'Delete'),
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
          onSelected: (value) {
            if (value == 'edit') {
              _editReminder(reminder, settingsService);
            } else if (value == 'delete') {
              _showDeleteReminderDialog(reminder, settingsService);
            }
          },
        ),
        onTap: () => _editReminder(reminder, settingsService),
      ),
    );
  }

  String _formatNextScheduled(
    DateTime dateTime,
    SettingsService settingsService,
  ) {
    final now = DateTime.now();
    final isJapanese = settingsService.currentLanguage == AppLanguage.japanese;

    if (_isSameDay(dateTime, now)) {
      if (isJapanese) {
        return '今日 ${DateFormat('HH:mm').format(dateTime)}';
      } else {
        return 'Today ${DateFormat('HH:mm').format(dateTime)}';
      }
    } else if (_isSameDay(dateTime, now.add(Duration(days: 1)))) {
      if (isJapanese) {
        return '明日 ${DateFormat('HH:mm').format(dateTime)}';
      } else {
        return 'Tomorrow ${DateFormat('HH:mm').format(dateTime)}';
      }
    } else {
      if (isJapanese) {
        return DateFormat('MM/dd HH:mm').format(dateTime);
      } else {
        return DateFormat('MM/dd HH:mm').format(dateTime);
      }
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  void _showAddReminderScreen(SettingsService settingsService) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NotificationFormScreen(pets: [widget.pet]),
      ),
    );
  }

  void _editReminder(
    NotificationReminder reminder,
    SettingsService settingsService,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) =>
                NotificationFormScreen(pets: [widget.pet], reminder: reminder),
      ),
    );
  }

  void _showDeleteReminderDialog(
    NotificationReminder reminder,
    SettingsService settingsService,
  ) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(
              settingsService.getText('delete_reminder', 'Delete Reminder'),
            ),
            content: Text(
              settingsService.getText(
                'delete_reminder_confirmation',
                'Are you sure you want to delete this reminder?',
              ),
            ),
            actions: [
              TextButton(
                child: Text(settingsService.getText('cancel', 'Cancel')),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
              TextButton(
                child: Text(
                  settingsService.getText('delete', 'Delete'),
                  style: TextStyle(color: Colors.red),
                ),
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  final success = await _notificationService!.deleteReminder(
                    reminder.id!,
                  );
                  if (mounted && success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          settingsService.getText(
                            'reminder_deleted',
                            'Reminder deleted',
                          ),
                        ),
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
