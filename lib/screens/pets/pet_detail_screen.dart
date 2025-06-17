// lib/screens/pets/pet_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/pet.dart';
import 'pet_form_screen.dart';
import '../dashboard/dashboard_screen.dart';

class PetDetailScreen extends StatelessWidget {
  final Pet pet;

  const PetDetailScreen({super.key, required this.pet});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(pet.name),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => PetFormScreen(pet: pet),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pet image
            if (pet.imageUrl != null)
              Image.network(
                pet.imageUrl!,
                width: double.infinity,
                height: 250,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 250,
                    color: Colors.grey[200],
                    child: Center(
                      child: Icon(Icons.pets, size: 80, color: Colors.grey),
                    ),
                  );
                },
              )
            else
              Container(
                height: 250,
                color: Colors.grey[200],
                child: Center(
                  child: Icon(Icons.pets, size: 80, color: Colors.grey),
                ),
              ),

            // Pet details
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and gender
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          pet.name,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getGenderColor(
                            pet.gender,
                          ).withAlpha(51), // 0.2 ≈ 51/255
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          Pet.getGenderText(pet.gender),
                          style: TextStyle(
                            color: _getGenderColor(pet.gender),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),

                  // Info cards
                  _buildInfoCard(
                    icon: Icons.category,
                    title: '分類',
                    content:
                        '${Pet.getCategoryText(pet.category)} (${pet.breed})',
                  ),

                  if (pet.birthday != null)
                    _buildInfoCard(
                      icon: Icons.cake,
                      title: '誕生日',
                      content:
                          '${DateFormat('yyyy年MM月dd日').format(pet.birthday!)}\n'
                          '(年齢: ${_calculateAge(pet.birthday!)})',
                    ),

                  _buildInfoCard(
                    icon: Icons.monitor_weight,
                    title: '体重単位',
                    content: Pet.getUnitText(pet.unit),
                  ),

                  SizedBox(height: 16),

                  // Divider
                  Divider(thickness: 1),

                  // Data sections
                  _buildSectionHeader(
                    title: 'ダッシュボード',
                    icon: Icons.dashboard,
                    subtitle: 'お世話記録カレンダーと体重グラフを確認',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder:
                              (context) => DashboardScreen(initialPet: pet),
                        ),
                      );
                    },
                  ),

                  // Quick stats placeholder
                  _buildQuickStatsCard(),

                  SizedBox(height: 16),

                  Divider(thickness: 1),

                  _buildSectionHeader(
                    title: 'クイック記録',
                    icon: Icons.add_circle,
                    subtitle: 'お世話や体重をすぐに記録',
                    onPressed: () {
                      _showQuickRecordMenu(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => DashboardScreen(initialPet: pet),
            ),
          );
        },
        label: Text('ダッシュボードを開く'),
        icon: Icon(Icons.dashboard),
        backgroundColor: Colors.green,
      ),
    );
  }

  // Info card widget
  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.green, size: 24),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  SizedBox(height: 4),
                  Text(
                    content,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Section header widget
  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required VoidCallback onPressed,
    String? subtitle,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: Colors.green),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }

  // Quick stats card
  Widget _buildQuickStatsCard() {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              '最新の記録',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildQuickStatItem(
                    icon: Icons.restaurant,
                    label: '最後の食事',
                    value: '記録なし',
                    color: Colors.orange,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildQuickStatItem(
                    icon: Icons.monitor_weight,
                    label: '最新体重',
                    value: '記録なし',
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildQuickStatItem(
                    icon: Icons.calendar_today,
                    label: '最後の記録',
                    value: '記録なし',
                    color: Colors.green,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildQuickStatItem(
                    icon: Icons.timeline,
                    label: '記録日数',
                    value: '0日',
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Quick record menu
  void _showQuickRecordMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (ctx) => Container(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'クイック記録',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickRecordButton(
                        context: ctx,
                        icon: Icons.restaurant,
                        label: 'ごはん記録',
                        color: Colors.orange,
                        onTap: () {
                          Navigator.of(ctx).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder:
                                  (context) => DashboardScreen(initialPet: pet),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: _buildQuickRecordButton(
                        context: ctx,
                        icon: Icons.monitor_weight,
                        label: '体重記録',
                        color: Colors.blue,
                        onTap: () {
                          Navigator.of(ctx).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder:
                                  (context) => DashboardScreen(initialPet: pet),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: _buildQuickRecordButton(
                    context: ctx,
                    icon: Icons.dashboard,
                    label: 'ダッシュボードを開く',
                    color: Colors.green,
                    onTap: () {
                      Navigator.of(ctx).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder:
                              (context) => DashboardScreen(initialPet: pet),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildQuickRecordButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Get gender indicator color
  Color _getGenderColor(Gender gender) {
    switch (gender) {
      case Gender.male:
        return Colors.blue;
      case Gender.female:
        return Colors.pink;
      case Gender.unknown:
        return Colors.grey;
    }
  }

  // Calculate age from birthday
  String _calculateAge(DateTime birthday) {
    final now = DateTime.now();
    int years = now.year - birthday.year;
    int months = now.month - birthday.month;

    // Adjust years if birth month hasn't occurred yet this year
    if (months < 0 || (months == 0 && now.day < birthday.day)) {
      years--;
      months += 12;
    }

    // Adjust months if birth day hasn't occurred yet this month
    if (now.day < birthday.day) {
      months--;
      if (months < 0) {
        months += 12;
        years--;
      }
    }

    if (years > 0) {
      return '$years歳${months > 0 ? ' $months ヶ月' : ''}';
    } else {
      return '$months ヶ月';
    }
  }
}
