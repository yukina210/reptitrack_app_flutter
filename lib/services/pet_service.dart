// lib/services/pet_service.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import '../models/pet.dart';

class PetService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final String userId;

  PetService({required this.userId});

  // Collection reference for pets
  CollectionReference get _petsCollection =>
      _firestore.collection('users').doc(userId).collection('pets');

  // Get all pets for current user
  Stream<List<Pet>> getPets() {
    return _petsCollection
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Pet.fromDocument(doc)).toList(),
        );
  }

  // Get a specific pet
  Future<Pet?> getPet(String petId) async {
    try {
      DocumentSnapshot doc = await _petsCollection.doc(petId).get();
      if (doc.exists) {
        return Pet.fromDocument(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting pet: $e');
      return null;
    }
  }

  // Add a new pet
  Future<String?> addPet(Pet pet, {File? imageFile}) async {
    try {
      // If there's an image file, upload it first
      String? imageUrl;
      if (imageFile != null) {
        imageUrl = await _uploadPetImage(imageFile);
      }

      // Create pet with image URL if available
      final petWithImage =
          imageUrl != null ? pet.copyWith(imageUrl: imageUrl) : pet;

      // Add to Firestore
      DocumentReference docRef = await _petsCollection.add(
        petWithImage.toMap(),
      );
      return docRef.id;
    } catch (e) {
      debugPrint('Error adding pet: $e');
      return null;
    }
  }

  // Update an existing pet
  Future<bool> updatePet(Pet pet, {File? imageFile}) async {
    try {
      if (pet.id == null) return false;

      // If there's a new image file, upload it
      String? imageUrl;
      if (imageFile != null) {
        imageUrl = await _uploadPetImage(imageFile);
      }

      // Create pet with new image URL if available
      final petWithImage =
          imageUrl != null ? pet.copyWith(imageUrl: imageUrl) : pet;

      // Update in Firestore
      await _petsCollection.doc(pet.id).update(petWithImage.toMap());
      return true;
    } catch (e) {
      debugPrint('Error updating pet: $e');
      return false;
    }
  }

  // Delete a pet
  Future<bool> deletePet(String petId) async {
    try {
      // Get the pet first to check if it has an image
      Pet? pet = await getPet(petId);

      // Delete the pet's image if it exists
      if (pet?.imageUrl != null) {
        await _deletePetImage(pet!.imageUrl!);
      }

      // Delete the pet document
      await _petsCollection.doc(petId).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting pet: $e');
      return false;
    }
  }

  // Upload pet image to Firebase Storage
  Future<String?> _uploadPetImage(File imageFile) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = _storage.ref().child('users/$userId/pets/$fileName');

      await storageRef.putFile(imageFile);
      final imageUrl = await storageRef.getDownloadURL();

      return imageUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  // Delete pet image from Firebase Storage
  Future<bool> _deletePetImage(String imageUrl) async {
    try {
      // Extract the file path from the URL
      final fileRef = _storage.refFromURL(imageUrl);
      await fileRef.delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting image: $e');
      return false;
    }
  }
}
