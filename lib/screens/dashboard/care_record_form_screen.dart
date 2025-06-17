// lib/screens/dashboard/care_record_form_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/care_record.dart';
import '../../services/care_record_service.dart';
import '../../services/auth_service.dart';

class CareRecordFormScreen extends StatefulWidget {
  final String petId;
  final DateTime selectedDate;
  final CareRecord? record; // For editing existing record

  const CareRecordFormScreen({
    super.key,
    required this.petId,
    required this.selectedDate,
    this.record,
  });

  @override
  State<CareRecordFormScreen> createState() => _CareRecordFormScreenState();
}

class _CareRecordFormScreenState extends State<CareRecordFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _foodTypeController = TextEditingController();
  final _otherNoteController = TextEditingController();
  final _tagsController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  FoodStatus? _foodStatus;
  bool _excretion = false;
  bool _shedding = false;
  bool _vomiting = false;
  bool _bathing = false;
  bool _cleaning = false;
  MatingStatus? _matingStatus;
  bool _layingEggs = false;
  List<String> _tags = [];
  bool _isLoading = false;
  List<CareRecord> _existingRecords = [];

  bool get _isEditing => widget.record != null;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate;

    if (_isEditing) {
      _initializeFromRecord();
    }

    _loadExistingRecords();
  }

  void _initializeFromRecord() {
    final record = widget.record!;
    _selectedDate = record.date;
    _selectedTime = record.time;
    _foodStatus = record.foodStatus;
    _foodTypeController.text = record.foodType ?? '';
    _excretion = record.excretion;
    _shedding = record.shedding;
    _vomiting = record.vomiting;
    _bathing = record.bathing;
    _cleaning = record.cleaning;
    _matingStatus = record.matingStatus;
    _layingEggs = record.layingEggs;
    _otherNoteController.text = record.otherNote ?? '';
    _tags = List.from(record.tags);
    _tagsController.text = _tags.join(', ');
  }

  Future<void> _loadExistingRecords() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.currentUser == null) return;

    final careService = CareRecordService(
      userId: authService.currentUser!.uid,
      petId: widget.petId,
    );

    try {
      final records = await careService.getCareRecordsForDate(_selectedDate!);
      setState(() {
        _existingRecords = records;
      });
    } catch (e) {
      debugPrint('Error loading existing records: $e');
    }
  }

  @override
  void dispose() {
    _foodTypeController.dispose();
    _otherNoteController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'お世話記録の編集' : 'お世話記録の追加'),
        backgroundColor: Colors.green,
        actions: [
          if (_isEditing)
            IconButton(icon: Icon(Icons.delete), onPressed: _showDeleteDialog),
        ],
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date and time selection
                      _buildDateTimeSection(),
                      SizedBox(height: 24),

                      // Existing records for this date
                      if (_existingRecords.isNotEmpty && !_isEditing)
                        _buildExistingRecordsSection(),

                      // Food section
                      _buildFoodSection(),
                      SizedBox(height: 24),

                      // Care items section
                      _buildCareItemsSection(),
                      SizedBox(height: 24),

                      // Other section
                      _buildOtherSection(),
                      SizedBox(height: 32),

                      // Save button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saveRecord,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            _isEditing ? '更新する' : '記録する',
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

  Widget _buildDateTimeSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '日時',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(Icons.calendar_today),
                    label: Text(
                      DateFormat('yyyy年MM月dd日').format(_selectedDate!),
                    ),
                    onPressed: () => _selectDate(context),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(Icons.access_time),
                    label: Text(
                      _selectedTime != null
                          ? _selectedTime!.format(context)
                          : '時間を選択',
                    ),
                    onPressed: () => _selectTime(context),
                  ),
                ),
              ],
            ),
            if (_selectedTime != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedTime = null;
                      });
                    },
                    child: Text('時間をクリア'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExistingRecordsSection() {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'この日の既存記録',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            ..._existingRecords.map((record) {
              return Container(
                margin: EdgeInsets.only(bottom: 8),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Text(
                      record.time?.format(context) ?? '時間未設定',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Wrap(
                        spacing: 4,
                        children:
                            record.careIcons.map((iconPath) {
                              return SizedBox(
                                width: 20,
                                height: 20,
                                child: Image.asset(
                                  iconPath,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.circle,
                                      size: 12,
                                      color: Colors.orange,
                                    );
                                  },
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.edit, size: 20),
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder:
                                (context) => CareRecordFormScreen(
                                  petId: widget.petId,
                                  selectedDate: widget.selectedDate,
                                  record: record,
                                ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.asset(
                  'assets/icons/feeding.png',
                  width: 24,
                  height: 24,
                  errorBuilder:
                      (context, error, stackTrace) => Icon(Icons.restaurant),
                ),
                SizedBox(width: 8),
                Text(
                  'ごはん',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 16),

            Text('食事ステータス'),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<FoodStatus>(
                    title: Text('完食'),
                    value: FoodStatus.completed,
                    groupValue: _foodStatus,
                    onChanged: (value) => setState(() => _foodStatus = value),
                  ),
                ),
                Expanded(
                  child: RadioListTile<FoodStatus>(
                    title: Text('食べ残し'),
                    value: FoodStatus.leftover,
                    groupValue: _foodStatus,
                    onChanged: (value) => setState(() => _foodStatus = value),
                  ),
                ),
                Expanded(
                  child: RadioListTile<FoodStatus>(
                    title: Text('拒食'),
                    value: FoodStatus.refused,
                    groupValue: _foodStatus,
                    onChanged: (value) => setState(() => _foodStatus = value),
                  ),
                ),
              ],
            ),

            if (_foodStatus != null) ...[
              SizedBox(height: 16),
              TextFormField(
                controller: _foodTypeController,
                decoration: InputDecoration(
                  labelText: 'エサの種類',
                  border: OutlineInputBorder(),
                  hintText: 'コオロギ、マウスなど',
                ),
              ),
            ],

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_foodStatus != null)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _foodStatus = null;
                        _foodTypeController.clear();
                      });
                    },
                    child: Text('クリア'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCareItemsSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'お世話項目',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),

            // Basic care items
            _buildCareCheckbox(
              'assets/icons/excretion.png',
              Icons.wc,
              '排泄',
              _excretion,
              (value) => setState(() => _excretion = value!),
            ),
            _buildCareCheckbox(
              'assets/icons/shedding.png',
              Icons.layers,
              '脱皮',
              _shedding,
              (value) => setState(() => _shedding = value!),
            ),
            _buildCareCheckbox(
              'assets/icons/regurgitation.png',
              Icons.sick,
              '吐き戻し',
              _vomiting,
              (value) => setState(() => _vomiting = value!),
            ),
            _buildCareCheckbox(
              'assets/icons/bathing.png',
              Icons.bathtub,
              '温浴',
              _bathing,
              (value) => setState(() => _bathing = value!),
            ),
            _buildCareCheckbox(
              'assets/icons/habitat_cleaning.png',
              Icons.cleaning_services,
              'ケージ清掃',
              _cleaning,
              (value) => setState(() => _cleaning = value!),
            ),
            _buildCareCheckbox(
              'assets/icons/egg_laying.png',
              Icons.egg,
              '産卵',
              _layingEggs,
              (value) => setState(() => _layingEggs = value!),
            ),

            SizedBox(height: 16),

            // Mating section
            Text('交配'),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<MatingStatus>(
                    title: Text('成功'),
                    value: MatingStatus.success,
                    groupValue: _matingStatus,
                    onChanged: (value) => setState(() => _matingStatus = value),
                  ),
                ),
                Expanded(
                  child: RadioListTile<MatingStatus>(
                    title: Text('拒絶'),
                    value: MatingStatus.rejected,
                    groupValue: _matingStatus,
                    onChanged: (value) => setState(() => _matingStatus = value),
                  ),
                ),
              ],
            ),

            if (_matingStatus != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => setState(() => _matingStatus = null),
                    child: Text('クリア'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCareCheckbox(
    String iconPath,
    IconData fallbackIcon,
    String title,
    bool value,
    ValueChanged<bool?> onChanged,
  ) {
    return CheckboxListTile(
      title: Row(
        children: [
          Image.asset(
            iconPath,
            width: 20,
            height: 20,
            errorBuilder:
                (context, error, stackTrace) => Icon(fallbackIcon, size: 20),
          ),
          SizedBox(width: 8),
          Text(title),
        ],
      ),
      value: value,
      onChanged: onChanged,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  Widget _buildOtherSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.asset(
                  'assets/icons/note.png',
                  width: 24,
                  height: 24,
                  errorBuilder:
                      (context, error, stackTrace) => Icon(Icons.note),
                ),
                SizedBox(width: 8),
                Text(
                  'その他・メモ',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 16),

            TextFormField(
              controller: _otherNoteController,
              decoration: InputDecoration(
                labelText: 'メモ',
                border: OutlineInputBorder(),
                hintText: '体調や気になることを記録',
              ),
              maxLines: 3,
            ),
            SizedBox(height: 16),

            TextFormField(
              controller: _tagsController,
              decoration: InputDecoration(
                labelText: 'タグ (カンマ区切り)',
                border: OutlineInputBorder(),
                hintText: '病院, 薬, 元気など',
              ),
              onChanged: (value) {
                _tags =
                    value
                        .split(',')
                        .map((tag) => tag.trim())
                        .where((tag) => tag.isNotEmpty)
                        .toList();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate!,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadExistingRecords();
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _saveRecord() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      if (authService.currentUser == null) return;

      final careService = CareRecordService(
        userId: authService.currentUser!.uid,
        petId: widget.petId,
      );

      final record = CareRecord(
        id: _isEditing ? widget.record!.id : null,
        date: _selectedDate!,
        time: _selectedTime,
        foodStatus: _foodStatus,
        foodType:
            _foodTypeController.text.trim().isEmpty
                ? null
                : _foodTypeController.text.trim(),
        excretion: _excretion,
        shedding: _shedding,
        vomiting: _vomiting,
        bathing: _bathing,
        cleaning: _cleaning,
        matingStatus: _matingStatus,
        layingEggs: _layingEggs,
        otherNote:
            _otherNoteController.text.trim().isEmpty
                ? null
                : _otherNoteController.text.trim(),
        tags: _tags,
        createdAt: _isEditing ? widget.record!.createdAt : DateTime.now(),
      );

      bool success;
      if (_isEditing) {
        success = await careService.updateCareRecord(record);
      } else {
        final recordId = await careService.addCareRecord(record);
        success = recordId != null;
      }

      if (mounted) {
        if (success) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isEditing ? 'お世話記録を更新しました' : 'お世話記録を追加しました'),
            ),
          );
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('エラーが発生しました。もう一度お試しください。')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('エラー: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text('記録の削除'),
            content: Text('この記録を削除してもよろしいですか？'),
            actions: [
              TextButton(
                child: Text('キャンセル'),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
              TextButton(
                child: Text('削除する', style: TextStyle(color: Colors.red)),
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  await _deleteRecord();
                },
              ),
            ],
          ),
    );
  }

  Future<void> _deleteRecord() async {
    if (!_isEditing || widget.record?.id == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      if (authService.currentUser == null) return;

      final careService = CareRecordService(
        userId: authService.currentUser!.uid,
        petId: widget.petId,
      );

      final success = await careService.deleteCareRecord(widget.record!.id!);

      if (mounted) {
        if (success) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('お世話記録を削除しました')));
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('削除中にエラーが発生しました')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('エラー: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
