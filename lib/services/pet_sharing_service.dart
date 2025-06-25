// lib/services/pet_sharing_service.dart
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/shared_models.dart';
import '../models/pet.dart';

class PetSharingService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 招待コードを生成
  String _generateInvitationCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        8,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  // ペットを他のユーザーに招待
  Future<PetInvitation> invitePetAccess({
    required String petId,
    required String petName,
    required String inviteeEmail,
    required SharePermission permission,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('ユーザーがログインしていません');

    // 招待情報を作成
    final invitationCode = _generateInvitationCode();
    final invitationId = _firestore.collection('pet_invitations').doc().id;

    final invitation = PetInvitation(
      invitationId: invitationId,
      petId: petId,
      petName: petName,
      inviterUserId: user.uid,
      inviterEmail: user.email ?? '',
      inviterDisplayName: user.displayName ?? user.email ?? 'Unknown',
      inviteeEmail: inviteeEmail,
      permission: permission,
      invitationCode: invitationCode,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(Duration(days: 7)), // 7日間有効
    );

    // Firestoreに招待情報を保存
    await _firestore
        .collection('pet_invitations')
        .doc(invitationId)
        .set(invitation.toMap());

    return invitation;
  }

  // 招待コードで招待を検索
  Future<PetInvitation?> findInvitationByCode(String code) async {
    try {
      final querySnapshot =
          await _firestore
              .collection('pet_invitations')
              .where('invitation_code', isEqualTo: code.toUpperCase())
              .where('is_used', isEqualTo: false)
              .limit(1)
              .get();

      if (querySnapshot.docs.isEmpty) return null;

      final invitation = PetInvitation.fromMap(querySnapshot.docs.first.data());
      return invitation.isValid ? invitation : null;
    } catch (e) {
      debugPrint('Error finding invitation: $e');
      return null;
    }
  }

  // 招待を受け入れる
  Future<void> acceptInvitation(String invitationCode) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('ユーザーがログインしていません');

    final invitation = await findInvitationByCode(invitationCode);
    if (invitation == null) {
      throw Exception('無効または期限切れの招待コードです');
    }

    // 既に共有されているかチェック
    final existingShare =
        await _firestore
            .collection('users')
            .doc(invitation.inviterUserId)
            .collection('pets')
            .doc(invitation.petId)
            .collection('shared_members')
            .doc(user.uid)
            .get();

    if (existingShare.exists) {
      throw Exception('既にこのペットにアクセス権があります');
    }

    final batch = _firestore.batch();

    // 共有メンバーとして追加
    final shareMember = PetShareMember(
      userId: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? user.email ?? 'Unknown',
      permission: invitation.permission,
      sharedAt: DateTime.now(),
      profileImageUrl: user.photoURL,
    );

    final shareMemberRef = _firestore
        .collection('users')
        .doc(invitation.inviterUserId)
        .collection('pets')
        .doc(invitation.petId)
        .collection('shared_members')
        .doc(user.uid);

    batch.set(shareMemberRef, shareMember.toMap());

    // 招待を使用済みにマーク
    final invitationRef = _firestore
        .collection('pet_invitations')
        .doc(invitation.invitationId);

    batch.update(invitationRef, {'is_used': true});

    // ユーザーの共有ペット一覧に追加
    final userSharedPetRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('shared_pets')
        .doc(invitation.petId);

    batch.set(userSharedPetRef, {
      'pet_id': invitation.petId,
      'owner_user_id': invitation.inviterUserId,
      'pet_name': invitation.petName,
      'permission': invitation.permission.value,
      'shared_at': Timestamp.fromDate(DateTime.now()),
    });

    await batch.commit();
  }

  // ペットの共有メンバー一覧を取得
  Stream<List<PetShareMember>> getPetShareMembers(String petId) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('pets')
        .doc(petId)
        .collection('shared_members')
        .orderBy('shared_at', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => PetShareMember.fromMap(doc.data()))
                  .toList(),
        );
  }

  // 共有メンバーの権限を変更
  Future<void> updateMemberPermission({
    required String petId,
    required String memberId,
    required SharePermission newPermission,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('ユーザーがログインしていません');

    // 所有者かチェック
    final petDoc =
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('pets')
            .doc(petId)
            .get();

    if (!petDoc.exists) {
      throw Exception('ペットが見つかりません');
    }

    // 共有メンバーの権限を更新
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('pets')
        .doc(petId)
        .collection('shared_members')
        .doc(memberId)
        .update({'permission': newPermission.value});

    // メンバーの共有ペット情報も更新
    await _firestore
        .collection('users')
        .doc(memberId)
        .collection('shared_pets')
        .doc(petId)
        .update({'permission': newPermission.value});
  }

  // 共有メンバーを削除
  Future<void> removeMember({
    required String petId,
    required String memberId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('ユーザーがログインしていません');

    final batch = _firestore.batch();

    // 共有メンバーから削除
    final memberRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('pets')
        .doc(petId)
        .collection('shared_members')
        .doc(memberId);

    batch.delete(memberRef);

    // メンバーの共有ペット一覧からも削除
    final sharedPetRef = _firestore
        .collection('users')
        .doc(memberId)
        .collection('shared_pets')
        .doc(petId);

    batch.delete(sharedPetRef);

    await batch.commit();
  }

  // ユーザーが共有されているペット一覧を取得
  Stream<List<Map<String, dynamic>>> getSharedPets() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('shared_pets')
        .orderBy('shared_at', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => {'id': doc.id, ...doc.data()})
                  .toList(),
        );
  }

  // ペットに対する権限を確認
  Future<SharePermission?> getPetPermission(
    String petId,
    String ownerId,
  ) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    // 自分のペットの場合は所有者権限
    if (user.uid == ownerId) return SharePermission.owner;

    // 共有されているペットの権限を確認
    final sharedPetDoc =
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('shared_pets')
            .doc(petId)
            .get();

    if (!sharedPetDoc.exists) return null;

    final data = sharedPetDoc.data()!;
    return SharePermission.fromString(data['permission'] ?? 'viewer');
  }

  // 権限チェック用のヘルパーメソッド
  bool canEdit(SharePermission? permission) {
    return permission == SharePermission.owner ||
        permission == SharePermission.editor;
  }

  bool canDelete(SharePermission? permission) {
    return permission == SharePermission.owner;
  }

  bool canManageMembers(SharePermission? permission) {
    return permission == SharePermission.owner;
  }
}
