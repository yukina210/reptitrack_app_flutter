// lib/models/pet.dart (互換性修正版)
import 'package:cloud_firestore/cloud_firestore.dart';
import 'shared_models.dart';

// 性別の列挙型
enum Gender { male, female, unknown }

// ペットカテゴリの列挙型
enum Category { snake, lizard, gecko, turtle, chameleon, crocodile, other }

// 体重単位の列挙型
enum WeightUnit { g, kg, lbs }

class Pet {
  final String? id; // 新規作成時はnullを許可
  final String name;
  final Gender gender;
  final DateTime? birthday;
  final Category category;
  final String breed;
  final WeightUnit unit; // 体重単位 (g/kg/lbs)
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  // 共有機能関連のフィールド（オプショナル）
  final String? ownerId; // ペットの所有者ID（新規作成時は後で設定）
  final bool isShared; // 共有されているかどうか
  final SharePermission? userPermission; // 現在のユーザーの権限

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
    this.ownerId,
    this.isShared = false,
    this.userPermission,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // 旧バージョンとの互換性のためのファクトリーコンストラクタ
  factory Pet.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Pet.fromMap(data, doc.id);
  }

  factory Pet.fromMap(
    Map<String, dynamic> map,
    String? documentId, {
    String? ownerId,
    SharePermission? userPermission,
  }) {
    return Pet(
      id: documentId,
      name: map['name'] ?? '',
      gender: _genderFromString(map['gender'] ?? 'unknown'),
      birthday:
          map['birthday'] != null
              ? (map['birthday'] as Timestamp).toDate()
              : null,
      category: _categoryFromString(map['category'] ?? 'other'),
      breed: map['breed'] ?? '',
      unit: _unitFromString(map['unit'] ?? 'g'),
      imageUrl: map['image_url'] ?? map['imageUrl'], // 両方のキーに対応
      createdAt:
          map['created_at'] != null
              ? (map['created_at'] as Timestamp).toDate()
              : map['createdAt'] != null
              ? (map['createdAt'] as Timestamp).toDate()
              : DateTime.now(),
      updatedAt:
          map['updated_at'] != null
              ? (map['updated_at'] as Timestamp).toDate()
              : map['updatedAt'] != null
              ? (map['updatedAt'] as Timestamp).toDate()
              : DateTime.now(),
      ownerId: ownerId ?? map['owner_id'],
      isShared: ownerId != null,
      userPermission: userPermission ?? SharePermission.owner, // デフォルトは所有者権限
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'gender': gender.toString().split('.').last,
      'birthday': birthday != null ? Timestamp.fromDate(birthday!) : null,
      'category': category.toString().split('.').last,
      'breed': breed,
      'unit': unit.toString().split('.').last,
      'image_url': imageUrl,
      'imageUrl': imageUrl, // 互換性のため両方保存
      'created_at': Timestamp.fromDate(createdAt),
      'createdAt': Timestamp.fromDate(createdAt), // 互換性のため両方保存
      'updated_at': Timestamp.fromDate(updatedAt),
      'updatedAt': Timestamp.fromDate(updatedAt), // 互換性のため両方保存
      'owner_id': ownerId,
    };
  }

  // 年齢を計算
  int? get ageInDays {
    if (birthday == null) return null;
    return DateTime.now().difference(birthday!).inDays;
  }

  // 年齢を年・月・日で表示
  String get ageString {
    if (birthday == null) return '不明';

    final now = DateTime.now();
    final age = now.difference(birthday!);

    if (age.inDays < 30) {
      return '${age.inDays}日';
    } else if (age.inDays < 365) {
      final months = (age.inDays / 30).floor();
      final days = age.inDays % 30;
      return days > 0 ? '$monthsヶ月$days日' : '$monthsヶ月';
    } else {
      final years = (age.inDays / 365).floor();
      final remainingDays = age.inDays % 365;
      final months = (remainingDays / 30).floor();

      if (months > 0) {
        return '$years歳$monthsヶ月';
      } else {
        return '$years歳';
      }
    }
  }

  // 性別の表示テキスト
  String get genderText {
    return getGenderText(gender);
  }

  // カテゴリの表示テキスト
  String get categoryText {
    return getCategoryText(category);
  }

  // 体重単位の表示テキスト
  String get unitText {
    return getUnitText(unit);
  }

  // 権限チェック用のヘルパーメソッド（安全なデフォルト）
  bool get canEdit {
    if (userPermission == null) return true; // 権限情報がない場合は編集可能（後方互換性）
    return userPermission == SharePermission.owner ||
        userPermission == SharePermission.editor;
  }

  bool get canDelete {
    if (userPermission == null) return true; // 権限情報がない場合は削除可能（後方互換性）
    return userPermission == SharePermission.owner;
  }

  bool get canManageSharing {
    if (userPermission == null) return true; // 権限情報がない場合は管理可能（後方互換性）
    return userPermission == SharePermission.owner;
  }

  bool get canView {
    return true; // 基本的に表示は常に可能
  }

  // 体重値を指定した単位に変換
  double convertWeight(double weight, WeightUnit targetUnit) {
    if (unit == targetUnit) return weight;

    // まずグラムに変換
    double weightInGrams;
    switch (unit) {
      case WeightUnit.g:
        weightInGrams = weight;
        break;
      case WeightUnit.kg:
        weightInGrams = weight * 1000;
        break;
      case WeightUnit.lbs:
        weightInGrams = weight * 453.592;
        break;
    }

    // 目標単位に変換
    switch (targetUnit) {
      case WeightUnit.g:
        return weightInGrams;
      case WeightUnit.kg:
        return weightInGrams / 1000;
      case WeightUnit.lbs:
        return weightInGrams / 453.592;
    }
  }

  // 体重範囲の推奨値を取得（種別による）
  Map<String, double> get recommendedWeightRange {
    switch (category) {
      case Category.snake:
        return _getSnakeWeightRange();
      case Category.lizard:
        return _getLizardWeightRange();
      case Category.gecko:
        return _getGeckoWeightRange();
      case Category.turtle:
        return _getTurtleWeightRange();
      default:
        return {'min': 0, 'max': 50000}; // デフォルト範囲（グラム）
    }
  }

  Map<String, double> _getSnakeWeightRange() {
    switch (breed.toLowerCase()) {
      case 'ボールパイソン':
        return {'min': 1000, 'max': 2000};
      case 'コーンスネーク':
        return {'min': 200, 'max': 900};
      default:
        return {'min': 100, 'max': 5000};
    }
  }

  Map<String, double> _getLizardWeightRange() {
    switch (breed.toLowerCase()) {
      case 'フトアゴヒゲトカゲ':
        return {'min': 300, 'max': 600};
      default:
        return {'min': 50, 'max': 2000};
    }
  }

  Map<String, double> _getGeckoWeightRange() {
    switch (breed.toLowerCase()) {
      case 'レオパードゲッコー':
        return {'min': 40, 'max': 100};
      default:
        return {'min': 20, 'max': 200};
    }
  }

  Map<String, double> _getTurtleWeightRange() {
    return {'min': 500, 'max': 10000};
  }

  // コピーメソッド（一部フィールドを更新）
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
    String? ownerId,
    bool? isShared,
    SharePermission? userPermission,
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
      updatedAt: updatedAt ?? DateTime.now(), // 更新時は現在時刻
      ownerId: ownerId ?? this.ownerId,
      isShared: isShared ?? this.isShared,
      userPermission: userPermission ?? this.userPermission,
    );
  }

  // 静的ヘルパーメソッド
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

  // 表示用テキスト取得メソッド
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

  // 単位変換用の便利メソッド
  static List<WeightUnit> get allUnits => WeightUnit.values;

  static String getUnitDescription(WeightUnit unit, {bool isJapanese = true}) {
    if (isJapanese) {
      switch (unit) {
        case WeightUnit.g:
          return 'グラム（小型爬虫類向け）';
        case WeightUnit.kg:
          return 'キログラム（大型爬虫類向け）';
        case WeightUnit.lbs:
          return 'ポンド（海外基準）';
      }
    } else {
      switch (unit) {
        case WeightUnit.g:
          return 'Grams (for small reptiles)';
        case WeightUnit.kg:
          return 'Kilograms (for large reptiles)';
        case WeightUnit.lbs:
          return 'Pounds (imperial)';
      }
    }
  }
}
