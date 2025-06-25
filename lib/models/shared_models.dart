// lib/models/shared_models.dart
import 'package:cloud_firestore/cloud_firestore.dart';

// 権限の種類
enum SharePermission {
  owner('owner'), // 所有者: 全権限
  editor('editor'), // 共有メンバー: 記録の追加・編集のみ
  viewer('viewer'); // 閲覧者: 記録の閲覧のみ

  const SharePermission(this.value);
  final String value;

  static SharePermission fromString(String value) {
    return SharePermission.values.firstWhere(
      (permission) => permission.value == value,
      orElse: () => SharePermission.viewer,
    );
  }
}

// ペット共有メンバー情報
class PetShareMember {
  final String userId;
  final String email;
  final String displayName;
  final SharePermission permission;
  final DateTime sharedAt;
  final String? profileImageUrl;

  PetShareMember({
    required this.userId,
    required this.email,
    required this.displayName,
    required this.permission,
    required this.sharedAt,
    this.profileImageUrl,
  });

  factory PetShareMember.fromMap(Map<String, dynamic> map) {
    return PetShareMember(
      userId: map['user_id'] ?? '',
      email: map['email'] ?? '',
      displayName: map['display_name'] ?? '',
      permission: SharePermission.fromString(map['permission'] ?? 'viewer'),
      sharedAt: (map['shared_at'] as Timestamp).toDate(),
      profileImageUrl: map['profile_image_url'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'email': email,
      'display_name': displayName,
      'permission': permission.value,
      'shared_at': Timestamp.fromDate(sharedAt),
      'profile_image_url': profileImageUrl,
    };
  }
}

// 招待情報
class PetInvitation {
  final String invitationId;
  final String petId;
  final String petName;
  final String inviterUserId;
  final String inviterEmail;
  final String inviterDisplayName;
  final String inviteeEmail;
  final SharePermission permission;
  final String invitationCode;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isUsed;

  PetInvitation({
    required this.invitationId,
    required this.petId,
    required this.petName,
    required this.inviterUserId,
    required this.inviterEmail,
    required this.inviterDisplayName,
    required this.inviteeEmail,
    required this.permission,
    required this.invitationCode,
    required this.createdAt,
    required this.expiresAt,
    this.isUsed = false,
  });

  factory PetInvitation.fromMap(Map<String, dynamic> map) {
    return PetInvitation(
      invitationId: map['invitation_id'] ?? '',
      petId: map['pet_id'] ?? '',
      petName: map['pet_name'] ?? '',
      inviterUserId: map['inviter_user_id'] ?? '',
      inviterEmail: map['inviter_email'] ?? '',
      inviterDisplayName: map['inviter_display_name'] ?? '',
      inviteeEmail: map['invitee_email'] ?? '',
      permission: SharePermission.fromString(map['permission'] ?? 'viewer'),
      invitationCode: map['invitation_code'] ?? '',
      createdAt: (map['created_at'] as Timestamp).toDate(),
      expiresAt: (map['expires_at'] as Timestamp).toDate(),
      isUsed: map['is_used'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'invitation_id': invitationId,
      'pet_id': petId,
      'pet_name': petName,
      'inviter_user_id': inviterUserId,
      'inviter_email': inviterEmail,
      'inviter_display_name': inviterDisplayName,
      'invitee_email': inviteeEmail,
      'permission': permission.value,
      'invitation_code': invitationCode,
      'created_at': Timestamp.fromDate(createdAt),
      'expires_at': Timestamp.fromDate(expiresAt),
      'is_used': isUsed,
    };
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isValid => !isUsed && !isExpired;
}
