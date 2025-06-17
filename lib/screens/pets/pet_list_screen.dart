// lib/screens/pets/pet_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/pet.dart';
import '../../services/pet_service.dart';
import '../../services/auth_service.dart';
import '../../services/settings_service.dart';
import '../navigation/main_navigation_screen.dart';
import 'pet_form_screen.dart';
import 'pet_detail_screen.dart';

class PetListScreen extends StatelessWidget {
  final bool showAppBar;

  const PetListScreen({super.key, this.showAppBar = true});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final settingsService = Provider.of<SettingsService>(context);

    // Ensure user is logged in
    if (authService.currentUser == null) {
      return Scaffold(
        appBar:
            showAppBar
                ? AppBar(
                  title: Text(
                    settingsService.getText('please_login', 'Please login'),
                  ),
                  backgroundColor: Colors.green,
                )
                : null,
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

    final petService = PetService(userId: authService.currentUser!.uid);

    return Scaffold(
      appBar:
          showAppBar
              ? AppBar(
                title: Text(settingsService.getText('my_pets', 'My Pets')),
                backgroundColor: Colors.green,
                actions: [
                  IconButton(
                    icon: Icon(Icons.exit_to_app),
                    onPressed: () async {
                      await authService.signOut();
                      if (context.mounted) {
                        Navigator.of(context).pushReplacementNamed('/auth');
                      }
                    },
                    tooltip: settingsService.getText('sign_out', 'Sign Out'),
                  ),
                ],
              )
              : AppBar(
                title: Text(settingsService.getText('my_pets', 'My Pets')),
                backgroundColor: Colors.green,
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: Icon(Icons.exit_to_app),
                    onPressed: () async {
                      await authService.signOut();
                      if (context.mounted) {
                        Navigator.of(context).pushReplacementNamed('/auth');
                      }
                    },
                    tooltip: settingsService.getText('sign_out', 'Sign Out'),
                  ),
                ],
              ),
      body: StreamBuilder<List<Pet>>(
        stream: petService.getPets(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                '${settingsService.getText('error_occurred', 'An error occurred')}: ${snapshot.error}',
              ),
            );
          }

          final pets = snapshot.data ?? [];

          if (pets.isEmpty) {
            return Center(
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
                  ElevatedButton.icon(
                    icon: Icon(Icons.add),
                    label: Text(
                      settingsService.getText('register_pet', 'Register a pet'),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () => _navigateToPetForm(context),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: pets.length,
            itemBuilder: (context, index) {
              final pet = pets[index];
              return _buildPetCard(context, pet, petService, settingsService);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        tooltip: settingsService.getText('add_pet', 'Add pet'),
        onPressed: () => _navigateToPetForm(context),
        child: Icon(Icons.add),
      ),
    );
  }

  // Pet card UI
  Widget _buildPetCard(
    BuildContext context,
    Pet pet,
    PetService petService,
    SettingsService settingsService,
  ) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToPetDetail(context, pet),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pet image
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              child:
                  pet.imageUrl != null
                      ? Image.network(
                        pet.imageUrl!,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 180,
                            color: Colors.grey[200],
                            child: Icon(
                              Icons.pets,
                              size: 64,
                              color: Colors.grey,
                            ),
                          );
                        },
                      )
                      : Container(
                        height: 180,
                        color: Colors.grey[200],
                        child: Icon(Icons.pets, size: 64, color: Colors.grey),
                      ),
            ),

            // Pet info
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          pet.name,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getGenderColor(pet.gender).withAlpha(51),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          Pet.getGenderText(
                            pet.gender,
                            isJapanese:
                                settingsService.currentLanguage ==
                                AppLanguage.japanese,
                          ),
                          style: TextStyle(
                            color: _getGenderColor(pet.gender),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${Pet.getCategoryText(pet.category, isJapanese: settingsService.currentLanguage == AppLanguage.japanese)} (${pet.breed})',
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                  if (pet.birthday != null) ...[
                    SizedBox(height: 4),
                    Text(
                      '${settingsService.getText('birthday', 'Birthday')}: ${DateFormat('yyyy年MM月dd日').format(pet.birthday!)}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${settingsService.getText('age', 'Age')}: ${_calculateAge(pet.birthday!)}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Dashboard button
                      TextButton.icon(
                        icon: Icon(
                          Icons.dashboard,
                          size: 18,
                          color: Colors.blue,
                        ),
                        label: Text(
                          settingsService.getText('dashboard', 'Dashboard'),
                          style: TextStyle(color: Colors.blue),
                        ),
                        onPressed: () => _navigateToDashboard(context, pet),
                      ),
                      Row(
                        children: [
                          // Edit button
                          TextButton.icon(
                            icon: Icon(Icons.edit, size: 18),
                            label: Text(
                              settingsService.getText('edit', 'Edit'),
                            ),
                            onPressed:
                                () => _navigateToPetForm(context, pet: pet),
                          ),
                          // Delete button
                          TextButton.icon(
                            icon: Icon(
                              Icons.delete,
                              size: 18,
                              color: Colors.red,
                            ),
                            label: Text(
                              settingsService.getText('delete', 'Delete'),
                              style: TextStyle(color: Colors.red),
                            ),
                            onPressed:
                                () => _confirmDeletePet(
                                  context,
                                  pet,
                                  petService,
                                  settingsService,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
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

  // Navigate to pet form
  void _navigateToPetForm(BuildContext context, {Pet? pet}) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => PetFormScreen(pet: pet)));
  }

  // Navigate to pet detail
  void _navigateToPetDetail(BuildContext context, Pet pet) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => PetDetailScreen(pet: pet)));
  }

  // Navigate to dashboard
  void _navigateToDashboard(BuildContext context, Pet pet) {
    // Try to find the MainNavigationScreen ancestor
    final mainNavState =
        context.findAncestorStateOfType<MainNavigationScreenState>();
    if (mainNavState != null) {
      // If we're already in the main navigation, switch to dashboard tab
      mainNavState.changeTab(1); // Switch to dashboard tab
    } else {
      // Fallback: Navigate to main navigation with dashboard tab and selected pet
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder:
              (context) =>
                  MainNavigationScreen(initialIndex: 1, initialPet: pet),
        ),
      );
    }
  }

  // Confirm pet deletion
  void _confirmDeletePet(
    BuildContext context,
    Pet pet,
    PetService petService,
    SettingsService settingsService,
  ) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(settingsService.getText('delete_pet', 'Delete Pet')),
            content: Text(
              settingsService
                  .getText(
                    'delete_pet_confirmation',
                    'Are you sure you want to delete ${pet.name}? This action cannot be undone.',
                  )
                  .replaceAll('\${pet.name}', pet.name),
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
                  final dialogContext = ctx;
                  Navigator.of(dialogContext).pop();

                  // Show loading indicator
                  if (context.mounted) {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder:
                          (loadingContext) =>
                              Center(child: CircularProgressIndicator()),
                    );
                  }

                  try {
                    final success = await petService.deletePet(pet.id!);

                    if (!context.mounted) return;

                    // Close loading dialog
                    Navigator.of(context).pop();

                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            settingsService
                                .getText(
                                  'pet_deleted_successfully',
                                  '${pet.name} has been deleted',
                                )
                                .replaceAll('\${pet.name}', pet.name),
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            settingsService.getText(
                              'delete_error',
                              'An error occurred while deleting',
                            ),
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    if (!context.mounted) return;

                    // Close loading dialog
                    Navigator.of(context).pop();

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${settingsService.getText('error', 'Error')}: $e',
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
