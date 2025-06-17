// lib/screens/notifications/notification_form_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/notification_reminder.dart';
import '../../models/pet.dart';
import '../../services/notification_service.dart';
import '../../services/auth_service.dart';
import '../../services/settings_service.dart';

class NotificationFormScreen extends StatefulWidget {
  final List<Pet> pets;
  final NotificationReminder? reminder;

  const NotificationFormScreen({super.key, required this.pets, this.reminder});

  @override
  State<NotificationFormScreen> createState() => _NotificationFormScreenState();
}

class _NotificationFormScreenState extends State<NotificationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  Pet? _selectedPet;
  NotificationType _selectedType = NotificationType.feeding;
  DateTime _selectedDateTime = DateTime.now().add(Duration(hours: 1));
  RepeatInterval _selectedInterval = RepeatInterval.once;
  bool _isLoading = false;

  bool get _isEditing => widget.reminder != null;

  @override
  void initState() {
    super.initState();

    if (widget.pets.isNotEmpty) {
      _selectedPet = widget.pets.first;
    }

    if (_isEditing) {
      _initializeFromReminder();
    } else {
      // Set default title based on type
      _updateTitleFromType();
    }
  }

  void _initializeFromReminder() {
    final reminder = widget.reminder!;
    _selectedPet = widget.pets.firstWhere(
      (pet) => pet.id == reminder.petId,
      orElse: () => widget.pets.first,
    );
    _selectedType = reminder.type;
    _titleController.text = reminder.title;
    _descriptionController.text = reminder.description ?? '';
    _selectedDateTime = reminder.scheduledDateTime;
    _selectedInterval = reminder.repeatInterval;
  }

  void _updateTitleFromType() {
    final settingsService = Provider.of<SettingsService>(
      context,
      listen: false,
    );

    if (_selectedType != NotificationType.custom) {
      final typeText = NotificationReminder.getTypeText(
        _selectedType,
        isJapanese: settingsService.currentLanguage == AppLanguage.japanese,
      );

      if (_selectedPet != null) {
        if (settingsService.currentLanguage == AppLanguage.japanese) {
          _titleController.text = '${_selectedPet!.name}の$typeText';
        } else {
          _titleController.text = '${_selectedPet!.name} $typeText';
        }
      } else {
        _titleController.text = typeText;
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsService = Provider.of<SettingsService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing
              ? settingsService.getText('edit_reminder', 'Edit Reminder')
              : settingsService.getText('add_reminder', 'Add Reminder'),
        ),
        backgroundColor: Colors.green,
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Pet Selection
                      _buildPetSelection(settingsService),
                      SizedBox(height: 24),

                      // Notification Type Selection
                      _buildTypeSelection(settingsService),
                      SizedBox(height: 24),

                      // Title Input
                      _buildTitleInput(settingsService),
                      SizedBox(height: 16),

                      // Description Input
                      _buildDescriptionInput(settingsService),
                      SizedBox(height: 24),

                      // Date and Time Selection
                      _buildDateTimeSelection(settingsService),
                      SizedBox(height: 24),

                      // Repeat Interval Selection
                      _buildRepeatSelection(settingsService),
                      SizedBox(height: 32),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saveReminder,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            _isEditing
                                ? settingsService.getText('update', 'Update')
                                : settingsService.getText('save', 'Save'),
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildPetSelection(SettingsService settingsService) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              settingsService.getText('select_pet', 'Select Pet'),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<Pet>(
              value: _selectedPet,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.pets),
              ),
              items:
                  widget.pets.map((pet) {
                    return DropdownMenuItem<Pet>(
                      value: pet,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.grey[200],
                            backgroundImage:
                                pet.imageUrl != null
                                    ? NetworkImage(pet.imageUrl!)
                                    : null,
                            child:
                                pet.imageUrl == null
                                    ? Icon(Icons.pets, size: 16)
                                    : null,
                          ),
                          SizedBox(width: 12),
                          Text(pet.name),
                        ],
                      ),
                    );
                  }).toList(),
              onChanged: (Pet? newPet) {
                setState(() {
                  _selectedPet = newPet;
                  _updateTitleFromType();
                });
              },
              validator: (value) {
                if (value == null) {
                  return settingsService.getText(
                    'please_select_pet',
                    'Please select a pet',
                  );
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelection(SettingsService settingsService) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              settingsService.getText('notification_type', 'Notification Type'),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  NotificationType.values.map((type) {
                    final isSelected = _selectedType == type;
                    return FilterChip(
                      selected: isSelected,
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            NotificationReminder.getTypeIcon(type),
                            size: 16,
                            color:
                                isSelected
                                    ? Colors.white
                                    : NotificationReminder.getTypeColor(type),
                          ),
                          SizedBox(width: 4),
                          Text(
                            NotificationReminder.getTypeText(
                              type,
                              isJapanese:
                                  settingsService.currentLanguage ==
                                  AppLanguage.japanese,
                            ),
                          ),
                        ],
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedType = type;
                            _updateTitleFromType();
                          });
                        }
                      },
                      selectedColor: NotificationReminder.getTypeColor(type),
                      backgroundColor: NotificationReminder.getTypeColor(
                        type,
                      ).withValues(alpha: 0.1),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                    );
                  }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleInput(SettingsService settingsService) {
    return TextFormField(
      controller: _titleController,
      decoration: InputDecoration(
        labelText: settingsService.getText('title', 'Title'),
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.title),
        hintText: settingsService.getText(
          'reminder_title_hint',
          'Enter reminder title',
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return settingsService.getText('title_required', 'Title is required');
        }
        return null;
      },
    );
  }

  Widget _buildDescriptionInput(SettingsService settingsService) {
    return TextFormField(
      controller: _descriptionController,
      decoration: InputDecoration(
        labelText:
            '${settingsService.getText('description', 'Description')} (${settingsService.getText('optional', 'Optional')})',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.description),
        hintText: settingsService.getText(
          'additional_notes',
          'Additional notes or instructions',
        ),
      ),
      maxLines: 3,
    );
  }

  Widget _buildDateTimeSelection(SettingsService settingsService) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              settingsService.getText('schedule', 'Schedule'),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),

            // Date Selection
            OutlinedButton.icon(
              icon: Icon(Icons.calendar_today),
              label: Text(DateFormat('yyyy年MM月dd日').format(_selectedDateTime)),
              onPressed: () => _selectDate(),
            ),
            SizedBox(height: 12),

            // Time Selection
            OutlinedButton.icon(
              icon: Icon(Icons.access_time),
              label: Text(
                TimeOfDay.fromDateTime(_selectedDateTime).format(context),
              ),
              onPressed: () => _selectTime(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRepeatSelection(SettingsService settingsService) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              settingsService.getText('repeat', 'Repeat'),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Column(
              children:
                  RepeatInterval.values.map((interval) {
                    return RadioListTile<RepeatInterval>(
                      title: Text(
                        NotificationReminder.getIntervalText(
                          interval,
                          isJapanese:
                              settingsService.currentLanguage ==
                              AppLanguage.japanese,
                        ),
                      ),
                      value: interval,
                      groupValue: _selectedInterval,
                      onChanged: (RepeatInterval? value) {
                        if (value != null) {
                          setState(() {
                            _selectedInterval = value;
                          });
                        }
                      },
                      activeColor: Colors.green,
                    );
                  }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365 * 2)),
    );

    if (picked != null) {
      setState(() {
        _selectedDateTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDateTime.hour,
          _selectedDateTime.minute,
        );
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );

    if (picked != null) {
      setState(() {
        _selectedDateTime = DateTime(
          _selectedDateTime.year,
          _selectedDateTime.month,
          _selectedDateTime.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  Future<void> _saveReminder() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPet == null) return;

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final settingsService = Provider.of<SettingsService>(
        context,
        listen: false,
      );

      if (authService.currentUser == null) return;

      final notificationService = NotificationService(
        userId: authService.currentUser!.uid,
      );

      final reminder = NotificationReminder(
        id: _isEditing ? widget.reminder!.id : null,
        petId: _selectedPet!.id!,
        type: _selectedType,
        title: _titleController.text.trim(),
        description:
            _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
        scheduledDateTime: _selectedDateTime,
        repeatInterval: _selectedInterval,
        createdAt: _isEditing ? widget.reminder!.createdAt : DateTime.now(),
      );

      bool success;
      if (_isEditing) {
        success = await notificationService.updateReminder(reminder);
      } else {
        final reminderId = await notificationService.addReminder(reminder);
        success = reminderId != null;
      }

      if (mounted) {
        if (success) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isEditing
                    ? settingsService.getText(
                      'reminder_updated',
                      'Reminder updated',
                    )
                    : settingsService.getText(
                      'reminder_created',
                      'Reminder created',
                    ),
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                settingsService.getText('error_occurred', 'An error occurred'),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final settingsService = Provider.of<SettingsService>(
          context,
          listen: false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${settingsService.getText('error', 'Error')}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
