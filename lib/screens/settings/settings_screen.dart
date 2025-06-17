// lib/screens/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../services/settings_service.dart';
import 'account_settings_screen.dart';
import 'language_settings_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_of_service_screen.dart';
import 'data_export_screen.dart';
import '../notifications/notifications_screen.dart';

class SettingsScreen extends StatefulWidget {
  final bool showAppBar;

  const SettingsScreen({super.key, this.showAppBar = true});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final settingsService = Provider.of<SettingsService>(context);
    final user = authService.currentUser;

    return Scaffold(
      appBar:
          widget.showAppBar
              ? AppBar(
                title: Text(settingsService.getText('settings', 'Settings')),
                backgroundColor: Colors.green,
              )
              : AppBar(
                title: Text(settingsService.getText('settings', 'Settings')),
                backgroundColor: Colors.green,
                automaticallyImplyLeading: false,
              ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : ListView(
                padding: EdgeInsets.all(16),
                children: [
                  // User Info Section
                  _buildUserInfoSection(user, settingsService),
                  SizedBox(height: 24),

                  // App Settings Section
                  _buildAppSettingsSection(settingsService),
                  SizedBox(height: 24),

                  // Account Section
                  _buildAccountSection(settingsService),
                  SizedBox(height: 24),

                  // Legal Section
                  _buildLegalSection(settingsService),
                  SizedBox(height: 24),

                  // Data Management Section
                  _buildDataSection(settingsService),
                  SizedBox(height: 32),

                  // Sign Out Button
                  _buildSignOutButton(authService, settingsService),
                ],
              ),
    );
  }

  Widget _buildUserInfoSection(User? user, SettingsService settingsService) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
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
                      : Icon(Icons.person, size: 30, color: Colors.green),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.displayName ??
                        settingsService.getText('unknown_user', 'Unknown User'),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    user?.email ?? '',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _getAuthProviderText(user, settingsService),
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppSettingsSection(SettingsService settingsService) {
    return _buildSection(
      title: settingsService.getText('app_settings', 'App Settings'),
      icon: Icons.settings,
      children: [
        _buildSettingsTile(
          icon: Icons.language,
          title: settingsService.getText('language', 'Language'),
          subtitle: settingsService.getText(
            'language_subtitle',
            'Choose your preferred language',
          ),
          trailing: Text(
            settingsService.getCurrentLanguageDisplay(),
            style: TextStyle(color: Colors.grey[600]),
          ),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => LanguageSettingsScreen()),
            );
          },
        ),
        _buildSettingsTile(
          icon: Icons.notifications,
          title: settingsService.getText('notifications', 'Notifications'),
          subtitle: settingsService.getText(
            'notification_subtitle',
            'Manage notification preferences',
          ),
          trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => NotificationsScreen(showAppBar: true),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAccountSection(SettingsService settingsService) {
    return _buildSection(
      title: settingsService.getText('account', 'Account'),
      icon: Icons.account_circle,
      children: [
        _buildSettingsTile(
          icon: Icons.person,
          title: settingsService.getText(
            'account_settings',
            'Account Settings',
          ),
          subtitle: settingsService.getText(
            'account_subtitle',
            'Manage your account information',
          ),
          trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => AccountSettingsScreen()),
            );
          },
        ),
        _buildSettingsTile(
          icon: Icons.security,
          title: settingsService.getText('security', 'Security'),
          subtitle: settingsService.getText(
            'security_subtitle',
            'Password and security settings',
          ),
          trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => AccountSettingsScreen(initialTab: 1),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLegalSection(SettingsService settingsService) {
    return _buildSection(
      title: settingsService.getText('legal', 'Legal'),
      icon: Icons.description,
      children: [
        _buildSettingsTile(
          icon: Icons.description,
          title: settingsService.getText(
            'terms_of_service',
            'Terms of Service',
          ),
          subtitle: settingsService.getText(
            'terms_subtitle',
            'Read our terms of service',
          ),
          trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => TermsOfServiceScreen()),
            );
          },
        ),
        _buildSettingsTile(
          icon: Icons.privacy_tip,
          title: settingsService.getText('privacy_policy', 'Privacy Policy'),
          subtitle: settingsService.getText(
            'privacy_subtitle',
            'Read our privacy policy',
          ),
          trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => PrivacyPolicyScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDataSection(SettingsService settingsService) {
    return _buildSection(
      title: settingsService.getText('data_management', 'Data Management'),
      icon: Icons.storage,
      children: [
        _buildSettingsTile(
          icon: Icons.download,
          title: settingsService.getText('export_data', 'Export Data'),
          subtitle: settingsService.getText(
            'export_subtitle',
            'Download your data',
          ),
          trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          onTap: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (context) => DataExportScreen()));
          },
        ),
        _buildSettingsTile(
          icon: Icons.delete_forever,
          title: settingsService.getText('delete_account', 'Delete Account'),
          subtitle: settingsService.getText(
            'delete_subtitle',
            'Permanently delete your account',
          ),
          trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.red),
          titleColor: Colors.red,
          onTap: () {
            _showDeleteAccountDialog(settingsService);
          },
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 8, bottom: 8),
          child: Row(
            children: [
              Icon(icon, size: 20, color: Colors.green),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
        ),
        Card(child: Column(children: children)),
      ],
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    required VoidCallback onTap,
    Color? titleColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: titleColor ?? Colors.grey[700]),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w500, color: titleColor),
      ),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12)),
      trailing: trailing,
      onTap: onTap,
    );
  }

  Widget _buildSignOutButton(
    AuthService authService,
    SettingsService settingsService,
  ) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: Icon(Icons.logout, color: Colors.red),
        label: Text(
          settingsService.getText('sign_out', 'Sign Out'),
          style: TextStyle(color: Colors.red),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.red),
          padding: EdgeInsets.symmetric(vertical: 12),
        ),
        onPressed: () => _showSignOutDialog(authService, settingsService),
      ),
    );
  }

  String _getAuthProviderText(User? user, SettingsService settingsService) {
    if (user?.providerData.isEmpty ?? true) {
      return settingsService.getText('email_auth', 'Email Authentication');
    }

    final providerId = user!.providerData.first.providerId;
    switch (providerId) {
      case 'google.com':
        return settingsService.getText('google_auth', 'Google Authentication');
      case 'apple.com':
        return settingsService.getText('apple_auth', 'Apple Authentication');
      case 'password':
      default:
        return settingsService.getText('email_auth', 'Email Authentication');
    }
  }

  void _showSignOutDialog(
    AuthService authService,
    SettingsService settingsService,
  ) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(
              settingsService.getText('confirm_sign_out', 'Confirm Sign Out'),
            ),
            content: Text(
              settingsService.getText(
                'sign_out_message',
                'Are you sure you want to sign out?',
              ),
            ),
            actions: [
              TextButton(
                child: Text(settingsService.getText('cancel', 'Cancel')),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
              TextButton(
                child: Text(
                  settingsService.getText('sign_out', 'Sign Out'),
                  style: TextStyle(color: Colors.red),
                ),
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  setState(() => _isLoading = true);

                  try {
                    await authService.signOut();
                    if (mounted) {
                      Navigator.of(
                        context,
                      ).pushNamedAndRemoveUntil('/auth', (route) => false);
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${settingsService.getText('error', 'Error')}: $e',
                          ),
                        ),
                      );
                    }
                  } finally {
                    if (mounted) {
                      setState(() => _isLoading = false);
                    }
                  }
                },
              ),
            ],
          ),
    );
  }

  void _showDeleteAccountDialog(SettingsService settingsService) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(
              settingsService.getText('delete_account', 'Delete Account'),
              style: TextStyle(color: Colors.red),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  settingsService.getText(
                    'delete_warning',
                    'This action cannot be undone. All your data will be permanently deleted.',
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  settingsService.getText(
                    'delete_consequences',
                    'This includes:',
                  ),
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  '• ${settingsService.getText('pets_data', 'All pet information')}',
                ),
                Text(
                  '• ${settingsService.getText('care_records', 'Care records')}',
                ),
                Text(
                  '• ${settingsService.getText('weight_records', 'Weight records')}',
                ),
                Text(
                  '• ${settingsService.getText('account_info', 'Account information')}',
                ),
              ],
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
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder:
                          (context) => AccountSettingsScreen(initialTab: 2),
                    ),
                  );
                },
              ),
            ],
          ),
    );
  }
}
