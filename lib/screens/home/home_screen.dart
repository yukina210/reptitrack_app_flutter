// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import '../pets/pet_list_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Redirect to the PetListScreen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => PetListScreen()),
      );
    });

    // Show a loading screen briefly while redirecting
    return Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
