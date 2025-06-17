// lib/screens/navigation/main_navigation_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/settings_service.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../models/pet.dart';
import '../pets/pet_list_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../notifications/notifications_screen.dart';
import '../settings/settings_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;
  final Pet? initialPet;

  const MainNavigationScreen({
    super.key,
    this.initialIndex = 0,
    this.initialPet,
  });

  @override
  State<MainNavigationScreen> createState() => MainNavigationScreenState();
}

class MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  PageController _pageController = PageController();
  NotificationService? _notificationService;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
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
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Public method to change tab from external widgets
  void changeTab(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsService = Provider.of<SettingsService>(context);

    return MultiProvider(
      providers: [
        if (_notificationService != null)
          ChangeNotifierProvider.value(value: _notificationService!),
      ],
      child: Scaffold(
        body: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          children: [
            // Pet List Screen
            PetListScreen(showAppBar: false),

            // Dashboard Screen
            widget.initialPet != null
                ? DashboardScreen(
                  initialPet: widget.initialPet,
                  showAppBar: false,
                )
                : DashboardScreen(showAppBar: false),

            // Notifications Screen
            NotificationsScreen(showAppBar: false),

            // Settings Screen
            SettingsScreen(showAppBar: false),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.3),
                spreadRadius: 1,
                blurRadius: 5,
                offset: Offset(0, -3),
              ),
            ],
          ),
          child: Consumer<NotificationService?>(
            builder: (context, notificationService, child) {
              final notificationCount =
                  notificationService?.notificationCount ?? 0;

              return BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: changeTab,
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.white,
                selectedItemColor: Colors.green,
                unselectedItemColor: Colors.grey[600],
                selectedLabelStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                unselectedLabelStyle: TextStyle(fontSize: 12),
                items: [
                  BottomNavigationBarItem(
                    icon: _buildCustomIcon(
                      'assets/icons/pet_index.png',
                      Icons.pets,
                      _currentIndex == 0,
                    ),
                    label: settingsService.getText('pets', 'Pets'),
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(
                      Icons.dashboard,
                      size: _currentIndex == 1 ? 28 : 24,
                    ),
                    label: settingsService.getText('dashboard', 'Dashboard'),
                  ),
                  BottomNavigationBarItem(
                    icon: _buildNotificationIcon(
                      notificationCount,
                      _currentIndex == 2,
                    ),
                    label: settingsService.getText(
                      'notifications',
                      'Notifications',
                    ),
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(
                      Icons.settings,
                      size: _currentIndex == 3 ? 28 : 24,
                    ),
                    label: settingsService.getText('settings', 'Settings'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCustomIcon(
    String assetPath,
    IconData fallbackIcon,
    bool isSelected,
  ) {
    return SizedBox(
      width: isSelected ? 28 : 24,
      height: isSelected ? 28 : 24,
      child: Image.asset(
        assetPath,
        width: isSelected ? 28 : 24,
        height: isSelected ? 28 : 24,
        color: isSelected ? Colors.green : Colors.grey[600],
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            fallbackIcon,
            size: isSelected ? 28 : 24,
            color: isSelected ? Colors.green : Colors.grey[600],
          );
        },
      ),
    );
  }

  Widget _buildNotificationIcon(int notificationCount, bool isSelected) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(
          Icons.notifications,
          size: isSelected ? 28 : 24,
          color: isSelected ? Colors.green : Colors.grey[600],
        ),
        if (notificationCount > 0)
          Positioned(
            right: -6,
            top: -6,
            child: Container(
              padding: EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(8),
              ),
              constraints: BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                notificationCount > 99 ? '99+' : notificationCount.toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
