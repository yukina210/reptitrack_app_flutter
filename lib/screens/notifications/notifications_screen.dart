// lib/screens/notifications/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/notification_reminder.dart';
import '../../models/pet.dart';
import '../../services/notification_service.dart';
import '../../services/pet_service.dart';
import '../../services/auth_service.dart';
import '../../services/settings_service.dart';
import 'notification_form_screen.dart';

class NotificationsScreen extends StatefulWidget {
  final bool showAppBar;

  const NotificationsScreen({super.key, this.showAppBar = true});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, Pet> _pets = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPets();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPets() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.currentUser == null) return;

    final petService = PetService(userId: authService.currentUser!.uid);

    await for (final pets in petService.getPets().take(1)) {
      setState(() {
        _pets = {for (var pet in pets) pet.id!: pet};
      });
      break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsService = Provider.of<SettingsService>(context);
    final authService = Provider.of<AuthService>(context);

    if (authService.currentUser == null) {
      return _buildLoginPrompt(settingsService);
    }

    return Scaffold(
      appBar:
          widget.showAppBar
              ? AppBar(
                title: Text(
                  settingsService.getText('notifications', 'Notifications'),
                ),
                backgroundColor: Colors.green,
                bottom: TabBar(
                  controller: _tabController,
                  tabs: [
                    Tab(
                      icon: Icon(Icons.notifications_active),
                      text: settingsService.getText('active', 'Active'),
                    ),
                    Tab(
                      icon: Icon(Icons.schedule),
                      text: settingsService.getText('scheduled', 'Scheduled'),
                    ),
                  ],
                  labelColor: Colors.green[700],
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.green,
                ),
              )
              : AppBar(
                title: Text(
                  settingsService.getText('notifications', 'Notifications'),
                ),
                backgroundColor: Colors.green,
                automaticallyImplyLeading: false,
                bottom: TabBar(
                  controller: _tabController,
                  tabs: [
                    Tab(
                      icon: Icon(Icons.notifications_active),
                      text: settingsService.getText('active', 'Active'),
                    ),
                    Tab(
                      icon: Icon(Icons.schedule),
                      text: settingsService.getText('scheduled', 'Scheduled'),
                    ),
                  ],
                  labelColor: Colors.green[700],
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.green,
                ),
              ),
      body: ChangeNotifierProvider(
        create:
            (context) => NotificationService(
              userId: authService.currentUser!.uid,
              settingsService: settingsService,
            ),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildActiveNotificationsTab(settingsService),
            _buildScheduledRemindersTab(settingsService),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: () => _showAddReminderDialog(settingsService),
        tooltip: settingsService.getText('add_reminder', 'Add Reminder'),
        child: Icon(Icons.add_alert),
      ),
    );
  }

  Widget _buildLoginPrompt(SettingsService settingsService) {
    return Scaffold(
      appBar:
          widget.showAppBar
              ? AppBar(
                title: Text(
                  settingsService.getText('notifications', 'Notifications'),
                ),
                backgroundColor: Colors.green,
              )
              : AppBar(
                title: Text(
                  settingsService.getText('notifications', 'Notifications'),
                ),
                backgroundColor: Colors.green,
                automaticallyImplyLeading: false,
              ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.login, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              settingsService.getText('please_login', 'Please login'),
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushReplacementNamed('/auth');
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: Text(settingsService.getText('login', 'Login')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveNotificationsTab(SettingsService settingsService) {
    return Consumer<NotificationService>(
      builder: (context, notificationService, child) {
        final activeNotifications = notificationService.activeNotifications;

        if (activeNotifications.isEmpty) {
          return _buildEmptyState(
            Icons.notifications_none,
            settingsService.getText(
              'no_active_notifications',
              'No active notifications',
            ),
            settingsService.getText(
              'notifications_will_appear_here',
              'Notifications will appear here when they are triggered',
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await notificationService.checkDueNotifications();
          },
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: activeNotifications.length + 1,
            itemBuilder: (context, index) {
              if (index == activeNotifications.length) {
                // Clear completed button at the bottom
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: TextButton.icon(
                    icon: Icon(Icons.clear_all),
                    label: Text(
                      settingsService.getText(
                        'clear_completed',
                        'Clear Completed',
                      ),
                    ),
                    onPressed: () {
                      notificationService.clearCompletedNotifications();
                    },
                  ),
                );
              }

              final notification = activeNotifications[index];
              final pet = _pets[notification.petId];

              return _buildNotificationCard(
                notification,
                pet,
                settingsService,
                notificationService,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildScheduledRemindersTab(SettingsService settingsService) {
    return Consumer<NotificationService>(
      builder: (context, notificationService, child) {
        final reminders = notificationService.reminders;

        if (reminders.isEmpty) {
          return _buildEmptyState(
            Icons.schedule,
            settingsService.getText(
              'no_scheduled_reminders',
              'No scheduled reminders',
            ),
            settingsService.getText(
              'tap_add_to_create_reminder',
              'Tap the + button to create your first reminder',
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: reminders.length,
          itemBuilder: (context, index) {
            final reminder = reminders[index];
            final pet = _pets[reminder.petId];

            return _buildReminderCard(
              reminder,
              pet,
              settingsService,
              notificationService,
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(IconData icon, String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(title, style: TextStyle(fontSize: 18, color: Colors.grey[600])),
          SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(
    NotificationHistory notification,
    Pet? pet,
    SettingsService settingsService,
    NotificationService notificationService,
  ) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: notification.isCompleted ? 1 : 3,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: NotificationReminder.getTypeColor(
            notification.type,
          ).withValues(alpha: 0.2),
          child: Icon(
            NotificationReminder.getTypeIcon(notification.type),
            color: NotificationReminder.getTypeColor(notification.type),
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration:
                notification.isCompleted ? TextDecoration.lineThrough : null,
            color: notification.isCompleted ? Colors.grey : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (pet != null)
              Text(
                pet.name,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            if (notification.description?.isNotEmpty == true) ...[
              SizedBox(height: 4),
              Text(notification.description!),
            ],
            SizedBox(height: 4),
            Text(
              DateFormat('yyyy/MM/dd HH:mm').format(notification.triggeredAt),
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
        trailing:
            notification.isCompleted
                ? Icon(Icons.check_circle, color: Colors.green)
                : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: Size(60, 32),
                  ),
                  onPressed: () async {
                    await notificationService.completeNotification(
                      notification.id!,
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            settingsService.getText('completed', 'Completed!'),
                          ),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                  child: Text(
                    settingsService.getText('complete', 'Complete'),
                    style: TextStyle(fontSize: 12),
                  ),
                ),
        onTap:
            notification.isCompleted
                ? null
                : () {
                  _showNotificationDetailDialog(
                    notification,
                    pet,
                    settingsService,
                  );
                },
      ),
    );
  }

  Widget _buildReminderCard(
    NotificationReminder reminder,
    Pet? pet,
    SettingsService settingsService,
    NotificationService notificationService,
  ) {
    final nextScheduled = reminder.getNextScheduledTime();
    final isOverdue = nextScheduled.isBefore(DateTime.now());

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: NotificationReminder.getTypeColor(
            reminder.type,
          ).withValues(alpha: 0.2),
          child: Icon(
            NotificationReminder.getTypeIcon(reminder.type),
            color: NotificationReminder.getTypeColor(reminder.type),
          ),
        ),
        title: Text(
          reminder.title,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (pet != null)
              Text(
                pet.name,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 14,
                  color: isOverdue ? Colors.red : Colors.grey[600],
                ),
                SizedBox(width: 4),
                Text(
                  DateFormat('yyyy/MM/dd HH:mm').format(nextScheduled),
                  style: TextStyle(
                    fontSize: 12,
                    color: isOverdue ? Colors.red : Colors.grey[600],
                    fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.repeat, size: 14, color: Colors.grey[600]),
                SizedBox(width: 4),
                Text(
                  NotificationReminder.getIntervalText(
                    reminder.repeatInterval,
                    isJapanese:
                        settingsService.currentLanguage == AppLanguage.japanese,
                  ),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton(
          icon: Icon(Icons.more_vert),
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
              _showDeleteReminderDialog(
                reminder,
                settingsService,
                notificationService,
              );
            }
          },
        ),
        onTap: () {
          _editReminder(reminder, settingsService);
        },
      ),
    );
  }

  void _showNotificationDetailDialog(
    NotificationHistory notification,
    Pet? pet,
    SettingsService settingsService,
  ) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  NotificationReminder.getTypeIcon(notification.type),
                  color: NotificationReminder.getTypeColor(notification.type),
                ),
                SizedBox(width: 8),
                Expanded(child: Text(notification.title)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (pet != null) ...[
                  Text(
                    settingsService.getText('pet', 'Pet'),
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(pet.name),
                  SizedBox(height: 16),
                ],
                Text(
                  settingsService.getText('triggered_at', 'Triggered At'),
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  DateFormat(
                    'yyyy/MM/dd HH:mm',
                  ).format(notification.triggeredAt),
                ),
                if (notification.description?.isNotEmpty == true) ...[
                  SizedBox(height: 16),
                  Text(
                    settingsService.getText('description', 'Description'),
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(notification.description!),
                ],
              ],
            ),
            actions: [
              TextButton(
                child: Text(settingsService.getText('close', 'Close')),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
    );
  }

  void _showAddReminderDialog(SettingsService settingsService) {
    if (_pets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            settingsService.getText(
              'no_pets_for_reminder',
              'Please register a pet first to create reminders',
            ),
          ),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => NotificationFormScreen(pets: _pets.values.toList()),
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
            (context) => NotificationFormScreen(
              pets: _pets.values.toList(),
              reminder: reminder,
            ),
      ),
    );
  }

  void _showDeleteReminderDialog(
    NotificationReminder reminder,
    SettingsService settingsService,
    NotificationService notificationService,
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
                  final success = await notificationService.deleteReminder(
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
