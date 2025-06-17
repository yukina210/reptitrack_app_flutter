// lib/screens/settings/account_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../services/settings_service.dart';
import '../../services/pet_service.dart';
import '../../services/care_record_service.dart';
import '../../services/weight_record_service.dart';

class AccountSettingsScreen extends StatefulWidget {
  final int initialTab;

  const AccountSettingsScreen({super.key, this.initialTab = 0});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsService = Provider.of<SettingsService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          settingsService.getText('account_settings', 'Account Settings'),
        ),
        backgroundColor: Colors.green,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: Icon(Icons.person),
              text: settingsService.getText('profile', 'Profile'),
            ),
            Tab(
              icon: Icon(Icons.security),
              text: settingsService.getText('security', 'Security'),
            ),
            Tab(
              icon: Icon(Icons.delete_forever),
              text: settingsService.getText('delete_account', 'Delete'),
            ),
          ],
          labelColor: Colors.green[700],
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.green,
        ),
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : TabBarView(
                controller: _tabController,
                children: [
                  _buildProfileTab(settingsService),
                  _buildSecurityTab(settingsService),
                  _buildDeleteTab(settingsService),
                ],
              ),
    );
  }

  Widget _buildProfileTab(SettingsService settingsService) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Info Card
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.green[100],
                        child:
                            user?.photoURL != null
                                ? ClipOval(
                                  child: Image.network(
                                    user!.photoURL!,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.person,
                                        size: 30,
                                        color: Colors.green,
                                      );
                                    },
                                  ),
                                )
                                : Icon(
                                  Icons.person,
                                  size: 30,
                                  color: Colors.green,
                                ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.displayName ??
                                  settingsService.getText(
                                    'unknown_user',
                                    'Unknown User',
                                  ),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              user?.email ?? '',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Divider(),
                  SizedBox(height: 16),
                  _buildInfoRow(
                    settingsService.getText('email', 'Email'),
                    user?.email ?? '',
                    Icons.email,
                  ),
                  SizedBox(height: 12),
                  _buildInfoRow(
                    settingsService.getText(
                      'account_created',
                      'Account Created',
                    ),
                    user?.metadata.creationTime?.toString().split(' ')[0] ?? '',
                    Icons.calendar_today,
                  ),
                  SizedBox(height: 12),
                  _buildInfoRow(
                    settingsService.getText('last_sign_in', 'Last Sign In'),
                    user?.metadata.lastSignInTime?.toString().split(' ')[0] ??
                        '',
                    Icons.login,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 24),

          // Email Change Section
          if (_isEmailPasswordProvider(user))
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      settingsService.getText('change_email', 'Change Email'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: Icon(Icons.edit),
                      label: Text(
                        settingsService.getText('change_email', 'Change Email'),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      onPressed: () => _showChangeEmailDialog(settingsService),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSecurityTab(SettingsService settingsService) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Password Section
          if (_isEmailPasswordProvider(user)) ...[
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      settingsService.getText('password', 'Password'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      settingsService.getText(
                        'password_subtitle',
                        'Keep your account secure with a strong password',
                      ),
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: Icon(Icons.lock),
                      label: Text(
                        settingsService.getText(
                          'change_password',
                          'Change Password',
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      onPressed:
                          () => _showChangePasswordDialog(settingsService),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
          ],

          // Authentication Methods Card
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    settingsService.getText(
                      'auth_methods',
                      'Authentication Methods',
                    ),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  ...user?.providerData.map((provider) {
                        return _buildAuthProviderTile(
                          provider,
                          settingsService,
                        );
                      }).toList() ??
                      [],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteTab(SettingsService settingsService) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: Colors.red[50],
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red),
                      SizedBox(width: 8),
                      Text(
                        settingsService.getText('danger_zone', 'Danger Zone'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red[700],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text(
                    settingsService.getText(
                      'delete_warning',
                      'This action cannot be undone. All your data will be permanently deleted.',
                    ),
                    style: TextStyle(color: Colors.red[700]),
                  ),
                  SizedBox(height: 16),
                  Text(
                    settingsService.getText(
                      'delete_consequences',
                      'This includes:',
                    ),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red[700],
                    ),
                  ),
                  SizedBox(height: 8),
                  _buildDeleteItem(
                    settingsService.getText('pets_data', 'All pet information'),
                  ),
                  _buildDeleteItem(
                    settingsService.getText('care_records', 'Care records'),
                  ),
                  _buildDeleteItem(
                    settingsService.getText('weight_records', 'Weight records'),
                  ),
                  _buildDeleteItem(
                    settingsService.getText(
                      'account_info',
                      'Account information',
                    ),
                  ),
                  SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.delete_forever),
                      label: Text(
                        settingsService.getText(
                          'delete_account',
                          'Delete Account',
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed:
                          () => _showDeleteAccountDialog(settingsService),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              Text(value, style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAuthProviderTile(
    UserInfo provider,
    SettingsService settingsService,
  ) {
    String providerName;
    IconData providerIcon;

    switch (provider.providerId) {
      case 'google.com':
        providerName = settingsService.getText('google_auth', 'Google');
        providerIcon = Icons.g_mobiledata;
        break;
      case 'apple.com':
        providerName = settingsService.getText('apple_auth', 'Apple');
        providerIcon = Icons.apple;
        break;
      case 'password':
      default:
        providerName = settingsService.getText('email_auth', 'Email');
        providerIcon = Icons.email;
        break;
    }

    return ListTile(
      leading: Icon(providerIcon, color: Colors.green),
      title: Text(providerName),
      subtitle: Text(provider.email ?? ''),
      trailing: Icon(Icons.check_circle, color: Colors.green),
    );
  }

  Widget _buildDeleteItem(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(Icons.close, size: 16, color: Colors.red),
          SizedBox(width: 8),
          Text(text, style: TextStyle(color: Colors.red[700])),
        ],
      ),
    );
  }

  bool _isEmailPasswordProvider(User? user) {
    if (user?.providerData.isEmpty ?? true) return false;
    return user!.providerData.any(
      (provider) => provider.providerId == 'password',
    );
  }

  void _showChangeEmailDialog(SettingsService settingsService) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(
              settingsService.getText('change_email', 'Change Email'),
            ),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: settingsService.getText(
                        'new_email',
                        'New Email',
                      ),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return settingsService.getText(
                          'email_required',
                          'Email is required',
                        );
                      }
                      if (!RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      ).hasMatch(value)) {
                        return settingsService.getText(
                          'invalid_email',
                          'Invalid email format',
                        );
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: passwordController,
                    decoration: InputDecoration(
                      labelText: settingsService.getText(
                        'current_password',
                        'Current Password',
                      ),
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return settingsService.getText(
                          'current_password_required',
                          'Current password is required',
                        );
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: Text(settingsService.getText('cancel', 'Cancel')),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
              TextButton(
                child: Text(settingsService.getText('update', 'Update')),
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    Navigator.of(ctx).pop();
                    await _changeEmail(
                      emailController.text,
                      passwordController.text,
                      settingsService,
                    );
                  }
                },
              ),
            ],
          ),
    );
  }

  void _showChangePasswordDialog(SettingsService settingsService) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(
              settingsService.getText('change_password', 'Change Password'),
            ),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: currentPasswordController,
                    decoration: InputDecoration(
                      labelText: settingsService.getText(
                        'current_password',
                        'Current Password',
                      ),
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return settingsService.getText(
                          'current_password_required',
                          'Current password is required',
                        );
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: newPasswordController,
                    decoration: InputDecoration(
                      labelText: settingsService.getText(
                        'new_password',
                        'New Password',
                      ),
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return settingsService.getText(
                          'password_required',
                          'Password is required',
                        );
                      }
                      if (value.length < 6) {
                        return settingsService.getText(
                          'password_too_short',
                          'Password must be at least 6 characters',
                        );
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: confirmPasswordController,
                    decoration: InputDecoration(
                      labelText: settingsService.getText(
                        'confirm_password',
                        'Confirm Password',
                      ),
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value != newPasswordController.text) {
                        return settingsService.getText(
                          'password_mismatch',
                          'Passwords do not match',
                        );
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: Text(settingsService.getText('cancel', 'Cancel')),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
              TextButton(
                child: Text(settingsService.getText('update', 'Update')),
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    Navigator.of(ctx).pop();
                    await _changePassword(
                      currentPasswordController.text,
                      newPasswordController.text,
                      settingsService,
                    );
                  }
                },
              ),
            ],
          ),
    );
  }

  void _showDeleteAccountDialog(SettingsService settingsService) {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(
              settingsService.getText('delete_account', 'Delete Account'),
              style: TextStyle(color: Colors.red),
            ),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    settingsService.getText(
                      'delete_confirmation',
                      'Type "DELETE" to confirm:',
                    ),
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: confirmController,
                    decoration: InputDecoration(
                      labelText: 'DELETE',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value != 'DELETE') {
                        return settingsService.getText(
                          'delete_confirmation_error',
                          'Please type "DELETE"',
                        );
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: passwordController,
                    decoration: InputDecoration(
                      labelText: settingsService.getText(
                        'current_password',
                        'Current Password',
                      ),
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return settingsService.getText(
                          'current_password_required',
                          'Current password is required',
                        );
                      }
                      return null;
                    },
                  ),
                ],
              ),
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
                  if (formKey.currentState!.validate()) {
                    Navigator.of(ctx).pop();
                    await _deleteAccount(
                      passwordController.text,
                      settingsService,
                    );
                  }
                },
              ),
            ],
          ),
    );
  }

  Future<void> _changeEmail(
    String newEmail,
    String password,
    SettingsService settingsService,
  ) async {
    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser!;

      // Re-authenticate user
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      // Update email
      await user.updateEmail(newEmail);
      await user.sendEmailVerification();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              settingsService.getText(
                'verification_email_sent',
                'Verification email sent',
              ),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${settingsService.getText('error', 'Error')}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _changePassword(
    String currentPassword,
    String newPassword,
    SettingsService settingsService,
  ) async {
    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser!;

      // Re-authenticate user
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              settingsService.getText(
                'password_updated',
                'Password updated successfully',
              ),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${settingsService.getText('error', 'Error')}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteAccount(
    String password,
    SettingsService settingsService,
  ) async {
    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser!;

      // Delete all user data first
      await _deleteAllUserData(user.uid);

      // Re-authenticate user
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      // Delete user account
      await user.delete();

      if (mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/auth', (route) => false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              settingsService.getText(
                'account_deleted',
                'Account deleted successfully',
              ),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${settingsService.getText('error', 'Error')}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteAllUserData(String userId) async {
    try {
      final petService = PetService(userId: userId);

      // Get all pets and delete their data
      await for (final pets in petService.getPets().take(1)) {
        for (final pet in pets) {
          if (pet.id != null) {
            // Delete care records
            final careService = CareRecordService(
              userId: userId,
              petId: pet.id!,
            );

            // Get and delete all care records
            await for (final careRecords in careService.getCareRecords().take(
              1,
            )) {
              for (final record in careRecords) {
                if (record.id != null) {
                  await careService.deleteCareRecord(record.id!);
                }
              }
              break;
            }

            // Delete weight records
            final weightService = WeightRecordService(
              userId: userId,
              petId: pet.id!,
            );

            // Get and delete all weight records
            await for (final weightRecords in weightService
                .getWeightRecords()
                .take(1)) {
              for (final record in weightRecords) {
                if (record.id != null) {
                  await weightService.deleteWeightRecord(record.id!);
                }
              }
              break;
            }

            // Delete pet
            await petService.deletePet(pet.id!);
          }
        }
        break;
      }
    } catch (e) {
      debugPrint('Error deleting user data: $e');
    }
  }
}
