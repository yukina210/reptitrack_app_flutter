// lib/services/pet_service.dart (互換性修正版)
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/pet.dart';
import '../models/shared_models.dart';
import 'pet_sharing_service.dart';

class PetService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final PetSharingService _sharingService = PetSharingService();

  // 後方互換性のためのuserId（オプショナル）
  final String? userId;

  PetService({this.userId});

  // 後方互換性のためのメソッド名
  Stream<List<Pet>> getPets() => getAllPets();

  // 自分のペット一覧と共有されているペット一覧を取得
  Stream<List<Pet>> getAllPets() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    // 自分のペットと共有ペットを個別取得して結合
    return getOwnPets().asyncMap((ownPets) async {
      final sharedPets = await getSharedPets().first;
      return [...ownPets, ...sharedPets];
    });
  }

  // 自分のペット一覧を取得
  Stream<List<Pet>> getOwnPets() {
    final user = _auth.currentUser;
    final targetUserId = userId ?? user?.uid;
    if (targetUserId == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(targetUserId)
        .collection('pets')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) => Pet.fromMap(
                      doc.data(),
                      doc.id,
                      userPermission: SharePermission.owner,
                    ),
                  )
                  .toList(),
        );
  }

  // 共有されているペット一覧を取得
  Stream<List<Pet>> getSharedPets() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _sharingService.getSharedPets().asyncMap((sharedPetInfos) async {
      List<Pet> sharedPets = [];

      for (final sharedPetInfo in sharedPetInfos) {
        try {
          final petDoc =
              await _firestore
                  .collection('users')
                  .doc(sharedPetInfo['owner_user_id'])
                  .collection('pets')
                  .doc(sharedPetInfo['pet_id'])
                  .get();

          if (petDoc.exists) {
            final permission = SharePermission.fromString(
              sharedPetInfo['permission'] ?? 'viewer',
            );

            final pet = Pet.fromMap(
              petDoc.data()!,
              petDoc.id,
              ownerId: sharedPetInfo['owner_user_id'],
              userPermission: permission,
            );

            sharedPets.add(pet);
          }
        } catch (e) {
          debugPrint('Error loading shared pet: $e');
        }
      }

      return sharedPets;
    });
  }

  // 特定のペットを取得（権限チェック付き）
  Future<Pet?> getPet(String petId, {String? ownerId}) async {
    final user = _auth.currentUser;
    final targetUserId = userId ?? user?.uid;
    if (targetUserId == null) return null;

    try {
      DocumentSnapshot petDoc;
      SharePermission? permission;

      if (ownerId != null && ownerId != targetUserId) {
        // 共有ペットの場合
        petDoc =
            await _firestore
                .collection('users')
                .doc(ownerId)
                .collection('pets')
                .doc(petId)
                .get();

        permission = await _sharingService.getPetPermission(petId, ownerId);
        if (permission == null) return null; // アクセス権限なし
      } else {
        // 自分のペットの場合
        petDoc =
            await _firestore
                .collection('users')
                .doc(targetUserId)
                .collection('pets')
                .doc(petId)
                .get();

        permission = SharePermission.owner;
      }

      if (!petDoc.exists) return null;

      return Pet.fromMap(
        petDoc.data() as Map<String, dynamic>,
        petDoc.id,
        ownerId: ownerId ?? targetUserId,
        userPermission: permission,
      );
    } catch (e) {
      debugPrint('Error getting pet: $e');
      return null;
    }
  }

  // ペットを追加（後方互換性対応）
  Future<String> addPet(Pet pet, {File? imageFile}) async {
    final user = _auth.currentUser;
    final targetUserId = userId ?? user?.uid;
    if (targetUserId == null) throw Exception('ユーザーがログインしていません');

    try {
      String? imageUrl;

      // 画像をアップロード
      if (imageFile != null) {
        imageUrl = await _uploadPetImage(imageFile);
      }

      // ペットデータを準備（ownerIdを設定）
      final petData =
          pet
              .copyWith(
                imageUrl: imageUrl,
                ownerId: targetUserId,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              )
              .toMap();

      final docRef = await _firestore
          .collection('users')
          .doc(targetUserId)
          .collection('pets')
          .add(petData);

      return docRef.id;
    } catch (e) {
      debugPrint('Error adding pet: $e');
      rethrow;
    }
  }

  // ペット情報を更新
  Future<void> updatePet(Pet pet, {File? imageFile}) async {
    final user = _auth.currentUser;
    final targetUserId = userId ?? user?.uid;
    if (targetUserId == null) throw Exception('ユーザーがログインしていません');

    if (pet.id == null) throw Exception('ペットIDが必要です');

    // 権限チェック
    if (!pet.canEdit) {
      throw Exception('このペットを編集する権限がありません');
    }

    try {
      String? imageUrl = pet.imageUrl;

      // 新しい画像がある場合はアップロード
      if (imageFile != null) {
        // 古い画像を削除
        if (pet.imageUrl != null) {
          await _deletePetImage(pet.imageUrl!);
        }
        imageUrl = await _uploadPetImage(imageFile);
      }

      final updatedPetData =
          pet.copyWith(imageUrl: imageUrl, updatedAt: DateTime.now()).toMap();

      final ownerUid = pet.isShared ? pet.ownerId : targetUserId;

      await _firestore
          .collection('users')
          .doc(ownerUid)
          .collection('pets')
          .doc(pet.id!)
          .update(updatedPetData);
    } catch (e) {
      debugPrint('Error updating pet: $e');
      rethrow;
    }
  }

  // ペットを削除（後方互換性対応）
  Future<bool> deletePet(String petId) async {
    final user = _auth.currentUser;
    final targetUserId = userId ?? user?.uid;
    if (targetUserId == null) throw Exception('ユーザーがログインしていません');

    try {
      // ペット情報を取得
      final pet = await getPet(petId);
      if (pet == null) throw Exception('ペットが見つかりません');

      // 権限チェック
      if (!pet.canDelete) {
        throw Exception('このペットを削除する権限がありません');
      }

      await _deletePetComplete(pet);
      return true;
    } catch (e) {
      debugPrint('Error deleting pet: $e');
      return false;
    }
  }

  // ペットを完全削除（内部メソッド）
  Future<void> _deletePetComplete(Pet pet) async {
    if (pet.id == null) return;

    final batch = _firestore.batch();
    final ownerUid = pet.ownerId ?? userId ?? _auth.currentUser?.uid;
    if (ownerUid == null) return;

    // ペット画像を削除
    if (pet.imageUrl != null) {
      await _deletePetImage(pet.imageUrl!);
    }

    // お世話記録を削除
    final careRecordsSnapshot =
        await _firestore
            .collection('users')
            .doc(ownerUid)
            .collection('pets')
            .doc(pet.id!)
            .collection('care_records')
            .get();

    for (final doc in careRecordsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // 体重記録を削除
    final weightRecordsSnapshot =
        await _firestore
            .collection('users')
            .doc(ownerUid)
            .collection('pets')
            .doc(pet.id!)
            .collection('weight_records')
            .get();

    for (final doc in weightRecordsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // 共有メンバー情報を削除
    final shareMembers =
        await _firestore
            .collection('users')
            .doc(ownerUid)
            .collection('pets')
            .doc(pet.id!)
            .collection('shared_members')
            .get();

    for (final memberDoc in shareMembers.docs) {
      batch.delete(memberDoc.reference);

      // メンバーの共有ペット一覧からも削除
      batch.delete(
        _firestore
            .collection('users')
            .doc(memberDoc.id)
            .collection('shared_pets')
            .doc(pet.id!),
      );
    }

    // ペット本体を削除
    batch.delete(
      _firestore
          .collection('users')
          .doc(ownerUid)
          .collection('pets')
          .doc(pet.id!),
    );

    await batch.commit();
  }

  // ペット画像をアップロード
  Future<String> _uploadPetImage(File imageFile) async {
    final user = _auth.currentUser;
    final targetUserId = userId ?? user?.uid;
    if (targetUserId == null) throw Exception('ユーザーがログインしていません');

    try {
      final fileName =
          'pet_${targetUserId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('pet_images').child(fileName);

      await ref.putFile(imageFile);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading image: $e');
      rethrow;
    }
  }

  // ペット画像を削除
  Future<void> _deletePetImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      debugPrint('Error deleting image: $e');
      // 画像削除エラーは継続処理（ペット自体の削除は継続）
    }
  }

  // 利用可能な品種リストを取得（オートコンプリート用）
  Future<List<String>> getBreedSuggestions(String category) async {
    // 実装例：カテゴリごとの一般的な品種リスト
    switch (category) {
      case 'snake':
        return ['ボールパイソン', 'コーンスネーク', 'キングスネーク', 'ミルクスネーク', 'レインボーボア'];
      case 'lizard':
        return ['フトアゴヒゲトカゲ', 'レオパードゲッコー', 'アカメカブトトカゲ', 'トッケイヤモリ', 'クレステッドゲッコー'];
      case 'turtle':
        return ['ロシアリクガメ', 'ヘルマンリクガメ', 'ギリシャリクガメ', 'ミドリガメ', 'クサガメ'];
      default:
        return [];
    }
  }

  // ペットの統計情報を取得
  Future<Map<String, dynamic>> getPetStatistics() async {
    final user = _auth.currentUser;
    final targetUserId = userId ?? user?.uid;
    if (targetUserId == null) return {};

    try {
      final ownPetsSnapshot =
          await _firestore
              .collection('users')
              .doc(targetUserId)
              .collection('pets')
              .get();

      final sharedPetsInfo = await _sharingService.getSharedPets().first;

      return {
        'totalPets': ownPetsSnapshot.docs.length + sharedPetsInfo.length,
        'ownPets': ownPetsSnapshot.docs.length,
        'sharedPets': sharedPetsInfo.length,
        'categories': _calculateCategoryStatistics(ownPetsSnapshot.docs),
      };
    } catch (e) {
      debugPrint('Error getting statistics: $e');
      return {};
    }
  }

  Map<String, int> _calculateCategoryStatistics(
    List<QueryDocumentSnapshot> docs,
  ) {
    final Map<String, int> categories = {};

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final category = data['category'] ?? 'other';
      categories[category] = (categories[category] ?? 0) + 1;
    }

    return categories;
  }
}
