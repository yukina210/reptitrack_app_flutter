// lib/screens/pet_share/pet_share_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/shared_models.dart';
import '../services/pet_sharing_service.dart';

class PetShareScreen extends StatefulWidget {
  final String petId;
  final String petName;

  const PetShareScreen({Key? key, required this.petId, required this.petName})
    : super(key: key);

  @override
  State<PetShareScreen> createState() => _PetShareScreenState();
}

class _PetShareScreenState extends State<PetShareScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _emailController = TextEditingController();
  SharePermission _selectedPermission = SharePermission.viewer;
  final _inviteCodeController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _inviteCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.petName}の共有管理'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [Tab(text: 'メンバー'), Tab(text: '招待'), Tab(text: '参加')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildMembersTab(), _buildInviteTab(), _buildJoinTab()],
      ),
    );
  }

  // メンバー一覧タブ
  Widget _buildMembersTab() {
    return StreamBuilder<List<PetShareMember>>(
      stream: context.read<PetSharingService>().getPetShareMembers(
        widget.petId,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text('エラーが発生しました'),
                TextButton(
                  onPressed: () => setState(() {}),
                  child: Text('再試行'),
                ),
              ],
            ),
          );
        }

        final members = snapshot.data ?? [];

        if (members.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  '共有メンバーがいません',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                SizedBox(height: 8),
                Text(
                  '「招待」タブから新しいメンバーを招待できます',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: members.length,
          itemBuilder: (context, index) {
            final member = members[index];
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage:
                      member.profileImageUrl != null
                          ? NetworkImage(member.profileImageUrl!)
                          : null,
                  child:
                      member.profileImageUrl == null
                          ? Icon(Icons.person)
                          : null,
                ),
                title: Text(member.displayName),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(member.email),
                    Text(
                      _getPermissionText(member.permission),
                      style: TextStyle(
                        color: _getPermissionColor(member.permission),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) => _handleMemberAction(value, member),
                  itemBuilder:
                      (context) => [
                        PopupMenuItem(
                          value: 'change_permission',
                          child: Text('権限を変更'),
                        ),
                        PopupMenuItem(
                          value: 'remove',
                          child: Text(
                            '削除',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 招待タブ
  Widget _buildInviteTab() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('メールアドレスで招待', style: Theme.of(context).textTheme.headlineSmall),
          SizedBox(height: 16),
          TextField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'メールアドレス',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          SizedBox(height: 16),
          Text('権限を選択', style: Theme.of(context).textTheme.titleMedium),
          SizedBox(height: 8),
          ...SharePermission.values
              .where((p) => p != SharePermission.owner)
              .map(
                (permission) => RadioListTile<SharePermission>(
                  title: Text(_getPermissionText(permission)),
                  subtitle: Text(_getPermissionDescription(permission)),
                  value: permission,
                  groupValue: _selectedPermission,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedPermission = value;
                      });
                    }
                  },
                ),
              ),
          SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _sendInvitation,
              child: _isLoading ? CircularProgressIndicator() : Text('招待を送信'),
            ),
          ),
        ],
      ),
    );
  }

  // 参加タブ
  Widget _buildJoinTab() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('招待コードで参加', style: Theme.of(context).textTheme.headlineSmall),
          SizedBox(height: 16),
          TextField(
            controller: _inviteCodeController,
            decoration: InputDecoration(
              labelText: '招待コード',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.code),
              hintText: '8文字の招待コードを入力',
            ),
            textCapitalization: TextCapitalization.characters,
            maxLength: 8,
          ),
          SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _joinWithCode,
              child: _isLoading ? CircularProgressIndicator() : Text('参加する'),
            ),
          ),
          SizedBox(height: 24),
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        '招待コードについて',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text('• 招待コードは8文字の英数字です'),
                  Text('• 招待コードの有効期限は7日間です'),
                  Text('• 招待コードは一度しか使用できません'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 招待を送信
  Future<void> _sendInvitation() async {
    if (_emailController.text.trim().isEmpty) {
      _showSnackBar('メールアドレスを入力してください');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final invitation = await context
          .read<PetSharingService>()
          .invitePetAccess(
            petId: widget.petId,
            petName: widget.petName,
            inviteeEmail: _emailController.text.trim(),
            permission: _selectedPermission,
          );

      // 招待コードを共有
      final shareText = '''
ReptiTrackへの招待

${widget.petName}の飼育記録を共有します。

招待コード: ${invitation.invitationCode}

ReptiTrackアプリで「招待コードで参加」から上記コードを入力してください。

※この招待コードの有効期限は${_formatDate(invitation.expiresAt)}までです。
''';

      await Share.share(shareText, subject: 'ReptiTrack - ペット共有への招待');

      _emailController.clear();
      _showSnackBar('招待を送信しました');
    } catch (e) {
      _showSnackBar('招待の送信に失敗しました: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 招待コードで参加
  Future<void> _joinWithCode() async {
    if (_inviteCodeController.text.trim().isEmpty) {
      _showSnackBar('招待コードを入力してください');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await context.read<PetSharingService>().acceptInvitation(
        _inviteCodeController.text.trim(),
      );

      _inviteCodeController.clear();
      _showSnackBar('ペットの共有に参加しました');

      // ペット一覧画面に戻る
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      _showSnackBar('参加に失敗しました: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // メンバーアクション処理
  void _handleMemberAction(String action, PetShareMember member) {
    switch (action) {
      case 'change_permission':
        _showChangePermissionDialog(member);
        break;
      case 'remove':
        _showRemoveMemberDialog(member);
        break;
    }
  }

  // 権限変更ダイアログ
  void _showChangePermissionDialog(PetShareMember member) {
    SharePermission selectedPermission = member.permission;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: Text('権限を変更'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children:
                        SharePermission.values
                            .where((p) => p != SharePermission.owner)
                            .map(
                              (permission) => RadioListTile<SharePermission>(
                                title: Text(_getPermissionText(permission)),
                                value: permission,
                                groupValue: selectedPermission,
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      selectedPermission = value;
                                    });
                                  }
                                },
                              ),
                            )
                            .toList(),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('キャンセル'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          await context
                              .read<PetSharingService>()
                              .updateMemberPermission(
                                petId: widget.petId,
                                memberId: member.userId,
                                newPermission: selectedPermission,
                              );
                          Navigator.of(context).pop();
                          _showSnackBar('権限を変更しました');
                        } catch (e) {
                          _showSnackBar('権限の変更に失敗しました: $e');
                        }
                      },
                      child: Text('変更'),
                    ),
                  ],
                ),
          ),
    );
  }

  // メンバー削除ダイアログ
  void _showRemoveMemberDialog(PetShareMember member) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('メンバーを削除'),
            content: Text('${member.displayName}を共有メンバーから削除しますか？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('キャンセル'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await context.read<PetSharingService>().removeMember(
                      petId: widget.petId,
                      memberId: member.userId,
                    );
                    Navigator.of(context).pop();
                    _showSnackBar('メンバーを削除しました');
                  } catch (e) {
                    _showSnackBar('削除に失敗しました: $e');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: Text('削除'),
              ),
            ],
          ),
    );
  }

  // 権限のテキスト表示
  String _getPermissionText(SharePermission permission) {
    switch (permission) {
      case SharePermission.owner:
        return '所有者';
      case SharePermission.editor:
        return '編集者';
      case SharePermission.viewer:
        return '閲覧者';
    }
  }

  // 権限の説明
  String _getPermissionDescription(SharePermission permission) {
    switch (permission) {
      case SharePermission.owner:
        return '全ての操作が可能';
      case SharePermission.editor:
        return '記録の追加・編集が可能';
      case SharePermission.viewer:
        return '記録の閲覧のみ可能';
    }
  }

  // 権限の色
  Color _getPermissionColor(SharePermission permission) {
    switch (permission) {
      case SharePermission.owner:
        return Colors.purple;
      case SharePermission.editor:
        return Colors.blue;
      case SharePermission.viewer:
        return Colors.green;
    }
  }

  // 日付フォーマット
  String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日';
  }

  // スナックバー表示
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
