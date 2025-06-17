// lib/screens/settings/data_export_screen.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/auth_service.dart';
import '../../services/settings_service.dart';
import '../../services/pet_service.dart';
import '../../services/care_record_service.dart';
import '../../services/weight_record_service.dart';
import '../../models/pet.dart';
import '../../models/care_record.dart';
import '../../models/weight_record.dart';

class DataExportScreen extends StatefulWidget {
  const DataExportScreen({super.key});

  @override
  State<DataExportScreen> createState() => _DataExportScreenState();
}

class _DataExportScreenState extends State<DataExportScreen> {
  bool _isExporting = false;
  Map<String, dynamic>? _exportedData;

  @override
  Widget build(BuildContext context) {
    final settingsService = Provider.of<SettingsService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(settingsService.getText('export_data', 'Export Data')),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Description Card
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.download, color: Colors.green),
                        SizedBox(width: 8),
                        Text(
                          settingsService.getText('export_data', 'Export Data'),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Text(
                      settingsService.getText(
                        'export_description',
                        'You can export all your data as a JSON file.',
                      ),
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 16),
                    Text(
                      settingsService.getText(
                        'export_includes',
                        'Export includes:',
                      ),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    _buildExportItem(
                      Icons.pets,
                      settingsService.getText('export_pets', 'Pet information'),
                    ),
                    _buildExportItem(
                      Icons.calendar_today,
                      settingsService.getText('export_care', 'Care records'),
                    ),
                    _buildExportItem(
                      Icons.show_chart,
                      settingsService.getText(
                        'export_weight',
                        'Weight records',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),

            // Export Preview
            if (_exportedData != null) ...[
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.preview, color: Colors.blue),
                          SizedBox(width: 8),
                          Text(
                            settingsService.getText(
                              'export_preview',
                              'Export Preview',
                            ),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      _buildDataSummary(_exportedData!, settingsService),
                      SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.share),
                          label: Text(
                            settingsService.getText('share_data', 'Share Data'),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: _shareExportedData,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),
            ],

            // Export Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon:
                    _isExporting
                        ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : Icon(Icons.download),
                label: Text(
                  _isExporting
                      ? settingsService.getText('exporting', 'Exporting...')
                      : settingsService.getText('export_button', 'Export Data'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _isExporting ? null : _performDataExport,
              ),
            ),
            SizedBox(height: 16),

            // Info Card
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        settingsService.getText(
                          'export_info',
                          'The exported file will contain all your data in JSON format. You can use this file to backup your data or import it into other applications.',
                        ),
                        style: TextStyle(color: Colors.blue[800]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportItem(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.green),
          SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }

  Widget _buildDataSummary(
    Map<String, dynamic> data,
    SettingsService settingsService,
  ) {
    final pets = data['pets'] as List? ?? [];
    int totalCareRecords = 0;
    int totalWeightRecords = 0;

    for (final pet in pets) {
      final careRecords = pet['care_records'] as List? ?? [];
      final weightRecords = pet['weight_records'] as List? ?? [];
      totalCareRecords += careRecords.length;
      totalWeightRecords += weightRecords.length;
    }

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          _buildSummaryRow(
            settingsService.getText('total_pets', 'Total Pets'),
            pets.length.toString(),
            Icons.pets,
          ),
          Divider(),
          _buildSummaryRow(
            settingsService.getText('total_care_records', 'Total Care Records'),
            totalCareRecords.toString(),
            Icons.calendar_today,
          ),
          Divider(),
          _buildSummaryRow(
            settingsService.getText(
              'total_weight_records',
              'Total Weight Records',
            ),
            totalWeightRecords.toString(),
            Icons.show_chart,
          ),
          Divider(),
          _buildSummaryRow(
            settingsService.getText('export_date', 'Export Date'),
            DateTime.now().toString().split(' ')[0],
            Icons.access_time,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          SizedBox(width: 12),
          Expanded(
            child: Text(label, style: TextStyle(fontWeight: FontWeight.w500)),
          ),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
          ),
        ],
      ),
    );
  }

  Future<void> _performDataExport() async {
    setState(() => _isExporting = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final settingsService = Provider.of<SettingsService>(
        context,
        listen: false,
      );

      if (authService.currentUser == null) {
        throw Exception(
          settingsService.getText('user_not_logged_in', 'User not logged in'),
        );
      }

      final userId = authService.currentUser!.uid;
      final petService = PetService(userId: userId);

      // Collect all data
      final exportData = <String, dynamic>{
        'export_info': {
          'version': '1.0',
          'exported_at': DateTime.now().toIso8601String(),
          'user_id': userId,
          'app_name': 'ReptiTrack',
        },
        'pets': [],
      };

      // Get all pets
      await for (final pets in petService.getPets().take(1)) {
        for (final pet in pets) {
          if (pet.id == null) continue;

          final careService = CareRecordService(userId: userId, petId: pet.id!);
          final weightService = WeightRecordService(
            userId: userId,
            petId: pet.id!,
          );

          // Get care records
          final careRecords = <Map<String, dynamic>>[];
          await for (final records in careService.getCareRecords().take(1)) {
            for (final record in records) {
              careRecords.add(_careRecordToMap(record));
            }
            break;
          }

          // Get weight records
          final weightRecords = <Map<String, dynamic>>[];
          await for (final records in weightService.getWeightRecords().take(
            1,
          )) {
            for (final record in records) {
              weightRecords.add(_weightRecordToMap(record));
            }
            break;
          }

          // Add pet data
          final petData = _petToMap(pet);
          petData['care_records'] = careRecords;
          petData['weight_records'] = weightRecords;

          (exportData['pets'] as List).add(petData);
        }
        break;
      }

      setState(() {
        _exportedData = exportData;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              settingsService.getText(
                'export_success',
                'Data export completed successfully',
              ),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final settingsService = Provider.of<SettingsService>(
          context,
          listen: false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${settingsService.getText('export_error', 'Export failed')}: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _shareExportedData() async {
    if (_exportedData == null) return;

    try {
      final jsonString = JsonEncoder.withIndent('  ').convert(_exportedData);
      final directory = await getTemporaryDirectory();
      final file = File(
        '${directory.path}/reptitrack_export_${DateTime.now().millisecondsSinceEpoch}.json',
      );

      await file.writeAsString(jsonString);

      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'ReptiTrack Data Export');
    } catch (e) {
      if (mounted) {
        final settingsService = Provider.of<SettingsService>(
          context,
          listen: false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${settingsService.getText('share_error', 'Share failed')}: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Map<String, dynamic> _petToMap(Pet pet) {
    return {
      'id': pet.id,
      'name': pet.name,
      'gender': pet.gender.toString().split('.').last,
      'birthday': pet.birthday?.toIso8601String(),
      'category': pet.category.toString().split('.').last,
      'breed': pet.breed,
      'unit': pet.unit.toString().split('.').last,
      'image_url': pet.imageUrl,
      'created_at': pet.createdAt.toIso8601String(),
      'updated_at': pet.updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> _careRecordToMap(CareRecord record) {
    return {
      'id': record.id,
      'date': record.date.toIso8601String(),
      'time':
          record.time != null
              ? {'hour': record.time!.hour, 'minute': record.time!.minute}
              : null,
      'food_status': record.foodStatus?.toString().split('.').last,
      'food_type': record.foodType,
      'excretion': record.excretion,
      'shedding': record.shedding,
      'vomiting': record.vomiting,
      'bathing': record.bathing,
      'cleaning': record.cleaning,
      'mating_status': record.matingStatus?.toString().split('.').last,
      'laying_eggs': record.layingEggs,
      'other_note': record.otherNote,
      'tags': record.tags,
      'created_at': record.createdAt.toIso8601String(),
      'updated_at': record.updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> _weightRecordToMap(WeightRecord record) {
    return {
      'id': record.id,
      'date': record.date.toIso8601String(),
      'weight_value': record.weightValue,
      'memo': record.memo,
      'created_at': record.createdAt.toIso8601String(),
      'updated_at': record.updatedAt.toIso8601String(),
    };
  }
}
