// lib/screens/dashboard/weight_record_form_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/pet.dart';
import '../../models/weight_record.dart';
import '../../services/weight_record_service.dart';
import '../../services/auth_service.dart';

class WeightRecordFormScreen extends StatefulWidget {
  final String petId;
  final WeightUnit unit;
  final WeightRecord? record; // For editing existing record

  const WeightRecordFormScreen({
    super.key,
    required this.petId,
    required this.unit,
    this.record,
  });

  @override
  State<WeightRecordFormScreen> createState() => _WeightRecordFormScreenState();
}

class _WeightRecordFormScreenState extends State<WeightRecordFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _memoController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  bool get _isEditing => widget.record != null;

  @override
  void initState() {
    super.initState();

    if (_isEditing) {
      _initializeFromRecord();
    }
  }

  void _initializeFromRecord() {
    final record = widget.record!;
    _selectedDate = record.date;
    _weightController.text = record.weightValue.toStringAsFixed(1);
    _memoController.text = record.memo ?? '';
  }

  @override
  void dispose() {
    _weightController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '体重記録の編集' : '体重記録の追加'),
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
                      // Date selection
                      _buildDateSection(),
                      SizedBox(height: 24),

                      // Weight input
                      _buildWeightSection(),
                      SizedBox(height: 24),

                      // Memo section
                      _buildMemoSection(),
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

  Widget _buildDateSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '測定日',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),

            OutlinedButton.icon(
              icon: Icon(Icons.calendar_today),
              label: Text(DateFormat('yyyy年MM月dd日').format(_selectedDate)),
              onPressed: () => _selectDate(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.monitor_weight, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  '体重',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _weightController,
                    decoration: InputDecoration(
                      labelText: '体重',
                      border: OutlineInputBorder(),
                      suffixText: Pet.getUnitText(widget.unit),
                      hintText: _getWeightHint(),
                    ),
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '体重を入力してください';
                      }
                      final weight = double.tryParse(value);
                      if (weight == null || weight <= 0) {
                        return '正しい体重を入力してください';
                      }
                      if (weight > _getMaxWeight()) {
                        return '体重が大きすぎます (最大: ${_getMaxWeight()}${Pet.getUnitText(widget.unit)})';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),

            Text(
              '小数点第1位まで入力できます',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemoSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.note, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'メモ (任意)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 16),

            TextFormField(
              controller: _memoController,
              decoration: InputDecoration(
                labelText: 'メモ',
                border: OutlineInputBorder(),
                hintText: '体調や状況を記録（任意）',
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  String _getWeightHint() {
    switch (widget.unit) {
      case WeightUnit.g:
        return '例: 125.5';
      case WeightUnit.kg:
        return '例: 1.2';
      case WeightUnit.lbs:
        return '例: 0.3';
    }
  }

  double _getMaxWeight() {
    switch (widget.unit) {
      case WeightUnit.g:
        return 50000; // 50kg in grams
      case WeightUnit.kg:
        return 50;
      case WeightUnit.lbs:
        return 110; // ~50kg in pounds
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveRecord() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      if (authService.currentUser == null) return;

      final weightService = WeightRecordService(
        userId: authService.currentUser!.uid,
        petId: widget.petId,
      );

      final weightValue = double.parse(_weightController.text);
      final memo =
          _memoController.text.trim().isEmpty
              ? null
              : _memoController.text.trim();

      final record = WeightRecord(
        id: _isEditing ? widget.record!.id : null,
        date: _selectedDate,
        weightValue: weightValue,
        memo: memo,
        createdAt: _isEditing ? widget.record!.createdAt : DateTime.now(),
      );

      bool success;
      if (_isEditing) {
        success = await weightService.updateWeightRecord(record);
      } else {
        final recordId = await weightService.addWeightRecord(record);
        success = recordId != null;
      }

      if (mounted) {
        if (success) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_isEditing ? '体重記録を更新しました' : '体重記録を追加しました')),
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
            content: Text('この体重記録を削除してもよろしいですか？'),
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

      final weightService = WeightRecordService(
        userId: authService.currentUser!.uid,
        petId: widget.petId,
      );

      final success = await weightService.deleteWeightRecord(
        widget.record!.id!,
      );

      if (mounted) {
        if (success) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('体重記録を削除しました')));
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
