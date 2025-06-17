// lib/screens/dashboard/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../models/pet.dart';
import '../../models/care_record.dart';
import '../../models/weight_record.dart';
import '../../services/pet_service.dart';
import '../../services/care_record_service.dart';
import '../../services/weight_record_service.dart';
import '../../services/auth_service.dart';
import '../../services/settings_service.dart';
import '../navigation/main_navigation_screen.dart';
import 'care_record_form_screen.dart';
import 'care_record_detail_screen.dart';
import 'weight_record_form_screen.dart';

class DashboardScreen extends StatefulWidget {
  final Pet? initialPet;
  final bool showAppBar;

  const DashboardScreen({super.key, this.initialPet, this.showAppBar = true});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Pet? _selectedPet;
  List<Pet> _pets = [];
  Map<DateTime, List<CareRecord>> _careRecords = {};
  List<WeightRecord> _weightRecords = [];
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedPet = widget.initialPet;
    _loadPets();
  }

  Future<void> _loadPets() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.currentUser == null) return;

    final petService = PetService(userId: authService.currentUser!.uid);

    try {
      // Load pets list
      await for (final pets in petService.getPets().take(1)) {
        setState(() {
          _pets = pets;
          if (_selectedPet == null && pets.isNotEmpty) {
            _selectedPet = pets.first;
          }
          _isLoading = false;
        });

        if (_selectedPet != null) {
          await _loadPetData();
        }
        break;
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        final settingsService = Provider.of<SettingsService>(
          context,
          listen: false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${settingsService.getText('data_load_failed', 'Failed to load data')}: $e',
            ),
          ),
        );
      }
    }
  }

  Future<void> _loadPetData() async {
    if (_selectedPet?.id == null) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.currentUser == null) return;

    final careService = CareRecordService(
      userId: authService.currentUser!.uid,
      petId: _selectedPet!.id!,
    );
    final weightService = WeightRecordService(
      userId: authService.currentUser!.uid,
      petId: _selectedPet!.id!,
    );

    try {
      // Load care records for current month
      final startOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
      final endOfMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);

      final careRecords = await careService.getCareRecordsForRange(
        startOfMonth,
        endOfMonth,
      );

      // Load weight records (last 3 months for chart)
      final threeMonthsAgo = DateTime.now().subtract(Duration(days: 90));
      final weightRecords = await weightService.getWeightRecordsForRange(
        threeMonthsAgo,
        DateTime.now(),
      );

      setState(() {
        _careRecords = careRecords;
        _weightRecords = weightRecords;
      });
    } catch (e) {
      debugPrint('Error loading pet data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsService = Provider.of<SettingsService>(context);

    if (_isLoading) {
      return Scaffold(
        appBar:
            widget.showAppBar
                ? AppBar(
                  title: Text(
                    settingsService.getText('dashboard', 'Dashboard'),
                  ),
                  backgroundColor: Colors.green,
                )
                : AppBar(
                  title: Text(
                    settingsService.getText('dashboard', 'Dashboard'),
                  ),
                  backgroundColor: Colors.green,
                  automaticallyImplyLeading: false,
                ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_pets.isEmpty) {
      return Scaffold(
        appBar:
            widget.showAppBar
                ? AppBar(
                  title: Text(
                    settingsService.getText('dashboard', 'Dashboard'),
                  ),
                  backgroundColor: Colors.green,
                )
                : AppBar(
                  title: Text(
                    settingsService.getText('dashboard', 'Dashboard'),
                  ),
                  backgroundColor: Colors.green,
                  automaticallyImplyLeading: false,
                ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.pets, size: 80, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                settingsService.getText(
                  'no_pets_registered',
                  'No pets registered',
                ),
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  _navigateToPetsTab();
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: Text(
                  settingsService.getText('register_pet', 'Register a pet'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar:
          widget.showAppBar
              ? AppBar(
                title: Text(settingsService.getText('dashboard', 'Dashboard')),
                backgroundColor: Colors.green,
              )
              : AppBar(
                title: Text(settingsService.getText('dashboard', 'Dashboard')),
                backgroundColor: Colors.green,
                automaticallyImplyLeading: false,
              ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pet selector
            _buildPetSelector(settingsService),
            SizedBox(height: 24),

            // Care calendar
            _buildCareCalendar(settingsService),
            SizedBox(height: 32),

            // Weight chart
            _buildWeightChart(settingsService),
          ],
        ),
      ),
    );
  }

  Widget _buildPetSelector(SettingsService settingsService) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            // Pet image
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.grey[200],
              backgroundImage:
                  _selectedPet?.imageUrl != null
                      ? NetworkImage(_selectedPet!.imageUrl!)
                      : null,
              child:
                  _selectedPet?.imageUrl == null
                      ? Icon(Icons.pets, size: 30, color: Colors.grey)
                      : null,
            ),
            SizedBox(width: 16),

            // Pet info and dropdown
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    settingsService.getText('current_pet', 'Current Pet'),
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 4),
                  DropdownButton<Pet>(
                    value: _selectedPet,
                    isExpanded: true,
                    underline: SizedBox.shrink(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    items:
                        _pets.map((pet) {
                          return DropdownMenuItem<Pet>(
                            value: pet,
                            child: Text(pet.name),
                          );
                        }).toList(),
                    onChanged: (Pet? newPet) {
                      if (newPet != null && newPet != _selectedPet) {
                        setState(() {
                          _selectedPet = newPet;
                        });
                        _loadPetData();
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCareCalendar(SettingsService settingsService) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  settingsService.getText('care_calendar', 'Care Calendar'),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              settingsService.getText(
                'calendar_subtitle',
                'Tap days with records for details, tap empty days to add new records',
              ),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            SizedBox(height: 16),

            TableCalendar<CareRecord>(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              eventLoader: (day) {
                final dateKey = DateTime(day.year, day.month, day.day);
                return _careRecords[dateKey] ?? [];
              },
              startingDayOfWeek: StartingDayOfWeek.sunday,
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                weekendTextStyle: TextStyle(color: Colors.red),
                holidayTextStyle: TextStyle(color: Colors.red),
                selectedDecoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                markerDecoration: BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                leftChevronIcon: Icon(Icons.chevron_left, color: Colors.green),
                rightChevronIcon: Icon(
                  Icons.chevron_right,
                  color: Colors.green,
                ),
              ),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
                _handleDayTap(selectedDay);
              },
              onPageChanged: (focusedDay) {
                setState(() {
                  _focusedDay = focusedDay;
                });
                _loadPetData(); // Reload data for new month
              },
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, day, events) {
                  if (events.isNotEmpty) {
                    return _buildCareMarkers(events.cast<CareRecord>());
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCareMarkers(List<CareRecord> records) {
    final icons = <String>[];
    for (final record in records) {
      icons.addAll(record.careIcons);
    }

    // Show max 4 icons
    final displayIcons = icons.take(4).toList();

    return Positioned(
      bottom: 1,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children:
            displayIcons.map((iconPath) {
              return Container(
                margin: EdgeInsets.symmetric(horizontal: 1),
                width: 12,
                height: 12,
                child: Image.asset(
                  iconPath,
                  errorBuilder: (context, error, stackTrace) {
                    return SizedBox(
                      width: 8,
                      height: 8,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  },
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildWeightChart(SettingsService settingsService) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.show_chart, color: Colors.green),
                    SizedBox(width: 8),
                    Text(
                      settingsService.getText('weight_chart', 'Weight Chart'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.add, color: Colors.green),
                  onPressed: _openWeightRecordForm,
                ),
              ],
            ),
            SizedBox(height: 16),

            if (_weightRecords.isEmpty)
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.show_chart, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        settingsService.getText(
                          'add_weight_to_show_chart',
                          'Add weight records to display chart',
                        ),
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              )
            else
              SizedBox(
                height: 200,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(show: true),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 60,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              '${value.toStringAsFixed(1)}${Pet.getUnitText(_selectedPet?.unit ?? WeightUnit.g)}',
                              style: TextStyle(fontSize: 12),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() < _weightRecords.length) {
                              final record = _weightRecords[value.toInt()];
                              return Text(
                                DateFormat('M/d').format(record.date),
                                style: TextStyle(fontSize: 10),
                              );
                            }
                            return Text('');
                          },
                        ),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: true),
                    lineBarsData: [
                      LineChartBarData(
                        spots:
                            _weightRecords.asMap().entries.map((entry) {
                              return FlSpot(
                                entry.key.toDouble(),
                                entry.value.weightValue,
                              );
                            }).toList(),
                        isCurved: true,
                        color: Colors.green,
                        barWidth: 3,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 4,
                              color: Colors.green,
                              strokeWidth: 2,
                              strokeColor: Colors.white,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.green.withValues(alpha: 0.1),
                        ),
                      ),
                    ],
                    lineTouchData: LineTouchData(
                      enabled: true,
                      touchCallback: (
                        FlTouchEvent event,
                        LineTouchResponse? touchResponse,
                      ) {
                        if (event is FlTapUpEvent &&
                            touchResponse?.lineBarSpots != null) {
                          final spot = touchResponse!.lineBarSpots!.first;
                          final index = spot.spotIndex;
                          if (index < _weightRecords.length) {
                            _openWeightRecordForm(
                              record: _weightRecords[index],
                            );
                          }
                        }
                      },
                      touchTooltipData: LineTouchTooltipData(
                        tooltipBgColor: Colors.green.withValues(alpha: 0.8),
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) {
                            final index = spot.spotIndex;
                            if (index < _weightRecords.length) {
                              final record = _weightRecords[index];
                              return LineTooltipItem(
                                '${DateFormat('M/d').format(record.date)}\n${record.weightValue.toStringAsFixed(1)}${Pet.getUnitText(_selectedPet?.unit ?? WeightUnit.g)}',
                                TextStyle(color: Colors.white),
                              );
                            }
                            return null;
                          }).toList();
                        },
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Navigate to pets tab in main navigation
  void _navigateToPetsTab() {
    // Try to find the MainNavigationScreen ancestor
    final mainNavState =
        context.findAncestorStateOfType<MainNavigationScreenState>();
    if (mainNavState != null) {
      mainNavState.changeTab(0); // Switch to pets tab
    } else {
      // Fallback: use Navigator to push a new MainNavigationScreen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => MainNavigationScreen(initialIndex: 0),
        ),
      );
    }
  }

  // Handle day tap - show detail if records exist, else show form
  void _handleDayTap(DateTime selectedDay) async {
    if (_selectedPet?.id == null) return;

    final dateKey = DateTime(
      selectedDay.year,
      selectedDay.month,
      selectedDay.day,
    );
    final existingRecords = _careRecords[dateKey] ?? [];

    if (existingRecords.isNotEmpty) {
      // Show detail screen for existing records
      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder:
              (context) => CareRecordDetailScreen(
                petId: _selectedPet!.id!,
                selectedDate: selectedDay,
                records: existingRecords,
              ),
        ),
      );

      if (result == true) {
        _loadPetData(); // Reload data after changes
      }
    } else {
      // Show form to add new record
      _openCareRecordForm(selectedDay);
    }
  }

  void _openCareRecordForm(DateTime selectedDate) async {
    if (_selectedPet?.id == null) return;

    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => CareRecordFormScreen(
              petId: _selectedPet!.id!,
              selectedDate: selectedDate,
            ),
      ),
    );

    if (result == true) {
      _loadPetData(); // Reload data after changes
    }
  }

  void _openWeightRecordForm({WeightRecord? record}) async {
    if (_selectedPet?.id == null) return;

    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => WeightRecordFormScreen(
              petId: _selectedPet!.id!,
              unit: _selectedPet!.unit,
              record: record,
            ),
      ),
    );

    if (result == true) {
      _loadPetData(); // Reload data after changes
    }
  }
}
