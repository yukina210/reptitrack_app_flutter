// lib/screens/pets/pet_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/pet.dart';
import '../../models/shared_models.dart'; // SharePermissionをインポート
import '../../services/pet_service.dart';
import '../../services/auth_service.dart';
import '../../services/settings_service.dart';
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
        appBar: showAppBar
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
              const Icon(Icons.login, size: 80, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                settingsService.getText('please_login', 'Please login'),
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
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

    // テスト環境でPetServiceがProviderとして提供されているかチェック
    PetService petService;
    try {
      petService = Provider.of<PetService>(context, listen: false);
    } catch (e) {
      // Providerに見つからない場合は新しくインスタンスを作成
      petService = PetService(userId: authService.currentUser!.uid);
    }

    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              title: Text(settingsService.getText('my_pets', 'My Pets')),
              backgroundColor: Colors.green,
              actions: [
                IconButton(
                  icon: const Icon(Icons.exit_to_app),
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
                  icon: const Icon(Icons.exit_to_app),
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
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 80, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    '${settingsService.getText('error_occurred', 'An error occurred')}: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      // 画面を再読み込み
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => PetListScreen(
                            showAppBar: showAppBar,
                          ),
                        ),
                      );
                    },
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: Text(settingsService.getText('retry', 'Retry')),
                  ),
                ],
              ),
            );
          }

          final pets = snapshot.data ?? [];

          if (pets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.pets, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    settingsService.getText(
                      'no_pets_registered',
                      'No pets registered',
                    ),
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: Text(
                      settingsService.getText('register_pet', 'Register a pet'),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
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
            padding: const EdgeInsets.all(16),
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
        child: const Icon(Icons.add),
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
      margin: const EdgeInsets.only(bottom: 16),
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
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: pet.imageUrl != null
                  ? Image.network(
                      pet.imageUrl!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildDefaultPetImage();
                      },
                    )
                  : _buildDefaultPetImage(),
            ),
            // Pet info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          pet.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _buildShareIndicator(pet),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    pet.breed,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildPetInfo(
                        icon: Icons.category,
                        text: _getCategoryText(pet.category, settingsService),
                      ),
                      const SizedBox(width: 16),
                      _buildPetInfo(
                        icon: pet.gender == Gender.male
                            ? Icons.male
                            : pet.gender == Gender.female
                                ? Icons.female
                                : Icons.help_outline,
                        text: _getGenderText(pet.gender, settingsService),
                      ),
                    ],
                  ),
                  if (pet.birthday != null) ...[
                    const SizedBox(height: 8),
                    _buildPetInfo(
                      icon: Icons.cake,
                      text: DateFormat('yyyy/MM/dd').format(pet.birthday!),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Default pet image
  Widget _buildDefaultPetImage() {
    return Container(
      height: 200,
      width: double.infinity,
      color: Colors.grey[300],
      child: const Icon(
        Icons.pets,
        size: 60,
        color: Colors.grey,
      ),
    );
  }

  // Share indicator
  Widget _buildShareIndicator(Pet pet) {
    // userPermissionがnullでない場合のみ共有インジケーターを表示
    if (pet.userPermission != null &&
        pet.userPermission != SharePermission.owner) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.blue[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.share, size: 16, color: Colors.blue[700]),
            const SizedBox(width: 4),
            Text(
              'Shared',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  // Pet info row
  Widget _buildPetInfo({required IconData icon, required String text}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  // Category text
  String _getCategoryText(Category category, SettingsService settingsService) {
    switch (category) {
      case Category.snake:
        return settingsService.getText('snake', 'Snake');
      case Category.lizard:
        return settingsService.getText('lizard', 'Lizard');
      case Category.gecko:
        return settingsService.getText('gecko', 'Gecko');
      case Category.turtle:
        return settingsService.getText('turtle', 'Turtle');
      case Category.chameleon:
        return settingsService.getText('chameleon', 'Chameleon');
      case Category.crocodile:
        return settingsService.getText('crocodile', 'Crocodile');
      case Category.other:
        return settingsService.getText('other', 'Other');
    }
  }

  // Gender text
  String _getGenderText(Gender gender, SettingsService settingsService) {
    switch (gender) {
      case Gender.male:
        return settingsService.getText('male', 'Male');
      case Gender.female:
        return settingsService.getText('female', 'Female');
      case Gender.unknown:
        return settingsService.getText('unknown', 'Unknown');
    }
  }

  // Navigate to pet detail
  void _navigateToPetDetail(BuildContext context, Pet pet) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PetDetailScreen(pet: pet),
      ),
    );
  }

  // Navigate to pet form
  void _navigateToPetForm(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PetFormScreen(),
      ),
    );
  }
}
