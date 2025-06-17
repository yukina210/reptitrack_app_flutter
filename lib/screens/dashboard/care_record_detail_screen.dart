// lib/screens/dashboard/care_record_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/care_record.dart';
import '../../services/care_record_service.dart';
import '../../services/auth_service.dart';
import 'care_record_form_screen.dart';

class CareRecordDetailScreen extends StatefulWidget {
  final String petId;
  final DateTime selectedDate;
  final List<CareRecord> records;

  const CareRecordDetailScreen({
    super.key,
    required this.petId,
    required this.selectedDate,
    required this.records,
  });

  @override
  State<CareRecordDetailScreen> createState() => _CareRecordDetailScreenState();
}

class _CareRecordDetailScreenState extends State<CareRecordDetailScreen> {
  List<CareRecord> _records = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _records = List.from(widget.records);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'お世話記録 - ${DateFormat('yyyy年MM月dd日').format(widget.selectedDate)}',
        ),
        backgroundColor: Colors.green,
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : _records.isEmpty
              ? _buildEmptyState()
              : _buildRecordsList(),
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'この日のお世話記録はありません',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            icon: Icon(Icons.add),
            label: Text('記録を追加'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: _addRecord,
          ),
        ],
      ),
    );
  }

  Widget _buildRecordsList() {
    // Sort records by time (records with time first, then by time, then records without time)
    final sortedRecords = List<CareRecord>.from(_records);
    sortedRecords.sort((a, b) {
      if (a.time == null && b.time == null) return 0;
      if (a.time == null) return 1;
      if (b.time == null) return -1;

      final aMinutes = a.time!.hour * 60 + a.time!.minute;
      final bMinutes = b.time!.hour * 60 + b.time!.minute;
      return aMinutes.compareTo(bMinutes);
    });

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: sortedRecords.length,
      itemBuilder: (context, index) {
        final record = sortedRecords[index];
        return _buildRecordCard(record, index);
      },
    );
  }

  Widget _buildRecordCard(CareRecord record, int index) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with time and actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.access_time, color: Colors.green, size: 20),
                    SizedBox(width: 8),
                    Text(
                      record.time?.format(context) ?? '時間未設定',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color:
                            record.time != null
                                ? Colors.black
                                : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _editRecord(record),
                      tooltip: '編集',
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteRecord(record),
                      tooltip: '削除',
                    ),
                  ],
                ),
              ],
            ),

            Divider(),
            SizedBox(height: 12),

            // Care details
            _buildCareDetails(record),
          ],
        ),
      ),
    );
  }

  Widget _buildCareDetails(CareRecord record) {
    final details = <Widget>[];

    // Food section
    if (record.foodStatus != null) {
      details.add(
        _buildDetailSection(
          'assets/icons/feeding.png',
          Icons.restaurant,
          'ごはん',
          [
            _buildDetailItem(
              '食事ステータス',
              CareRecord.getFoodStatusText(record.foodStatus!),
            ),
            if (record.foodType?.isNotEmpty == true)
              _buildDetailItem('エサの種類', record.foodType!),
          ],
        ),
      );
    }

    // Care items section
    final careItems = <String>[];
    if (record.excretion) careItems.add('排泄');
    if (record.shedding) careItems.add('脱皮');
    if (record.vomiting) careItems.add('吐き戻し');
    if (record.bathing) careItems.add('温浴');
    if (record.cleaning) careItems.add('ケージ清掃');
    if (record.layingEggs) careItems.add('産卵');

    if (careItems.isNotEmpty) {
      details.add(
        _buildDetailSection('assets/icons/care.png', Icons.pets, 'お世話項目', [
          _buildDetailItem('実施項目', careItems.join('、')),
        ]),
      );
    }

    // Mating section
    if (record.matingStatus != null) {
      details.add(
        _buildDetailSection('assets/icons/mating.png', Icons.favorite, '交配', [
          _buildDetailItem(
            'ステータス',
            CareRecord.getMatingStatusText(record.matingStatus!),
          ),
        ]),
      );
    }

    // Other notes and tags
    if (record.otherNote?.isNotEmpty == true || record.tags.isNotEmpty) {
      final noteDetails = <Widget>[];
      if (record.otherNote?.isNotEmpty == true) {
        noteDetails.add(_buildDetailItem('メモ', record.otherNote!));
      }
      if (record.tags.isNotEmpty) {
        noteDetails.add(_buildDetailItem('タグ', record.tags.join('、')));
      }

      details.add(
        _buildDetailSection(
          'assets/icons/note.png',
          Icons.note,
          'メモ・その他',
          noteDetails,
        ),
      );
    }

    if (details.isEmpty) {
      return Center(
        child: Text(
          'この記録には詳細情報がありません',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    return Column(
      children:
          details
              .map(
                (detail) => Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: detail,
                ),
              )
              .toList(),
    );
  }

  Widget _buildDetailSection(
    String iconPath,
    IconData fallbackIcon,
    String title,
    List<Widget> items,
  ) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(
                iconPath,
                width: 20,
                height: 20,
                errorBuilder:
                    (context, error, stackTrace) =>
                        Icon(fallbackIcon, size: 20, color: Colors.green),
              ),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          ...items,
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Text(value, style: TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: Icon(Icons.add, color: Colors.green),
              label: Text('記録を追加', style: TextStyle(color: Colors.green)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.green),
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: _addRecord,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              icon: Icon(Icons.delete_sweep),
              label: Text('すべて削除'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: _deleteAllRecords,
            ),
          ),
        ],
      ),
    );
  }

  void _addRecord() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => CareRecordFormScreen(
              petId: widget.petId,
              selectedDate: widget.selectedDate,
            ),
      ),
    );

    if (result == true) {
      await _refreshRecords();
    }
  }

  void _editRecord(CareRecord record) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => CareRecordFormScreen(
              petId: widget.petId,
              selectedDate: widget.selectedDate,
              record: record,
            ),
      ),
    );

    if (result == true) {
      await _refreshRecords();
    }
  }

  void _deleteRecord(CareRecord record) {
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
                  await _performDeleteRecord(record);
                },
              ),
            ],
          ),
    );
  }

  void _deleteAllRecords() {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text('すべての記録を削除'),
            content: Text(
              '${DateFormat('yyyy年MM月dd日').format(widget.selectedDate)}のすべてのお世話記録を削除してもよろしいですか？\n\nこの操作は元に戻せません。',
            ),
            actions: [
              TextButton(
                child: Text('キャンセル'),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
              TextButton(
                child: Text('すべて削除する', style: TextStyle(color: Colors.red)),
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  await _performDeleteAllRecords();
                },
              ),
            ],
          ),
    );
  }

  Future<void> _performDeleteRecord(CareRecord record) async {
    if (record.id == null) return;

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

      final success = await careService.deleteCareRecord(record.id!);

      if (mounted) {
        if (success) {
          setState(() {
            _records.removeWhere((r) => r.id == record.id);
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('記録を削除しました')));
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

  Future<void> _performDeleteAllRecords() async {
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

      bool allSuccess = true;
      for (final record in _records) {
        if (record.id != null) {
          final success = await careService.deleteCareRecord(record.id!);
          if (!success) allSuccess = false;
        }
      }

      if (mounted) {
        if (allSuccess) {
          setState(() {
            _records.clear();
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('すべての記録を削除しました')));
          Navigator.of(context).pop(true); // Return to dashboard
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('一部の記録の削除に失敗しました')));
          await _refreshRecords();
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

  Future<void> _refreshRecords() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.currentUser == null) return;

    final careService = CareRecordService(
      userId: authService.currentUser!.uid,
      petId: widget.petId,
    );

    try {
      final records = await careService.getCareRecordsForDate(
        widget.selectedDate,
      );
      setState(() {
        _records = records;
      });
    } catch (e) {
      debugPrint('Error refreshing records: $e');
    }
  }
}
