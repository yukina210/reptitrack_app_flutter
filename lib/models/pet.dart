// lib/models/pet.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum Gender { male, female, unknown }

enum Category { snake, lizard, gecko, turtle, chameleon, crocodile, other }

enum WeightUnit { g, kg, lbs }

class Pet {
  final String? id;
  final String name;
  final Gender gender;
  final DateTime? birthday;
  final Category category;
  final String breed;
  final WeightUnit unit;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  Pet({
    this.id,
    required this.name,
    required this.gender,
    this.birthday,
    required this.category,
    required this.breed,
    required this.unit,
    this.imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(), // 不要な'this.'を削除
       updatedAt = updatedAt ?? DateTime.now(); // 不要な'this.'を削除

  // Convert from Pet to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'gender': gender.toString().split('.').last,
      'birthday': birthday != null ? Timestamp.fromDate(birthday!) : null,
      'category': category.toString().split('.').last,
      'breed': breed,
      'unit': unit.toString().split('.').last,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Create a Pet from a Firestore document
  factory Pet.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Pet(
      id: doc.id,
      name: data['name'] ?? '',
      gender: _genderFromString(data['gender'] ?? 'unknown'),
      birthday:
          data['birthday'] != null
              ? (data['birthday'] as Timestamp).toDate()
              : null,
      category: _categoryFromString(data['category'] ?? 'other'),
      breed: data['breed'] ?? '',
      unit: _unitFromString(data['unit'] ?? 'g'),
      imageUrl: data['imageUrl'],
      createdAt:
          data['createdAt'] != null
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.now(),
      updatedAt:
          data['updatedAt'] != null
              ? (data['updatedAt'] as Timestamp).toDate()
              : DateTime.now(),
    );
  }

  // Create a copy of Pet with modified fields
  Pet copyWith({
    String? id,
    String? name,
    Gender? gender,
    DateTime? birthday,
    bool clearBirthday = false,
    Category? category,
    String? breed,
    WeightUnit? unit,
    String? imageUrl,
    bool clearImageUrl = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Pet(
      id: id ?? this.id,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      birthday: clearBirthday ? null : (birthday ?? this.birthday),
      category: category ?? this.category,
      breed: breed ?? this.breed,
      unit: unit ?? this.unit,
      imageUrl: clearImageUrl ? null : (imageUrl ?? this.imageUrl),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // Helper methods to convert strings to enums
  static Gender _genderFromString(String value) {
    switch (value) {
      case 'male':
        return Gender.male;
      case 'female':
        return Gender.female;
      default:
        return Gender.unknown;
    }
  }

  static Category _categoryFromString(String value) {
    switch (value) {
      case 'snake':
        return Category.snake;
      case 'lizard':
        return Category.lizard;
      case 'gecko':
        return Category.gecko;
      case 'turtle':
        return Category.turtle;
      case 'chameleon':
        return Category.chameleon;
      case 'crocodile':
        return Category.crocodile;
      default:
        return Category.other;
    }
  }

  static WeightUnit _unitFromString(String value) {
    switch (value) {
      case 'kg':
        return WeightUnit.kg;
      case 'lbs':
        return WeightUnit.lbs;
      default:
        return WeightUnit.g;
    }
  }

  // Helper methods to get localized strings
  static String getGenderText(Gender gender, {bool isJapanese = true}) {
    if (isJapanese) {
      switch (gender) {
        case Gender.male:
          return 'オス';
        case Gender.female:
          return 'メス';
        case Gender.unknown:
          return '不明';
      }
    } else {
      switch (gender) {
        case Gender.male:
          return 'Male';
        case Gender.female:
          return 'Female';
        case Gender.unknown:
          return 'Unknown';
      }
    }
  }

  static String getCategoryText(Category category, {bool isJapanese = true}) {
    if (isJapanese) {
      switch (category) {
        case Category.snake:
          return 'ヘビ';
        case Category.lizard:
          return 'トカゲ';
        case Category.gecko:
          return 'ヤモリ';
        case Category.turtle:
          return 'カメ';
        case Category.chameleon:
          return 'カメレオン';
        case Category.crocodile:
          return 'ワニ';
        case Category.other:
          return 'その他';
      }
    } else {
      switch (category) {
        case Category.snake:
          return 'Snake';
        case Category.lizard:
          return 'Lizard';
        case Category.gecko:
          return 'Gecko';
        case Category.turtle:
          return 'Turtle';
        case Category.chameleon:
          return 'Chameleon';
        case Category.crocodile:
          return 'Crocodile';
        case Category.other:
          return 'Other';
      }
    }
  }

  static String getUnitText(WeightUnit unit) {
    switch (unit) {
      case WeightUnit.g:
        return 'g';
      case WeightUnit.kg:
        return 'kg';
      case WeightUnit.lbs:
        return 'lbs';
    }
  }
}
