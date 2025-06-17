// lib/screens/settings/language_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/settings_service.dart';

class LanguageSettingsScreen extends StatelessWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsService = Provider.of<SettingsService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          settingsService.getText('select_language', 'Select Language'),
        ),
        backgroundColor: Colors.green,
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Text(
            settingsService.getText('language', 'Language'),
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            settingsService.getText(
              'language_subtitle',
              'Choose your preferred language',
            ),
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          SizedBox(height: 24),

          Card(
            child: Column(
              children:
                  AppLanguage.values.map((language) {
                    final isSelected =
                        settingsService.currentLanguage == language;

                    return ListTile(
                      leading: _getLanguageFlag(language),
                      title: Text(
                        language.displayName,
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.green : null,
                        ),
                      ),
                      subtitle: Text(_getLanguageNativeName(language)),
                      trailing:
                          isSelected
                              ? Icon(Icons.check, color: Colors.green)
                              : null,
                      onTap:
                          () => _changeLanguage(
                            context,
                            settingsService,
                            language,
                          ),
                    );
                  }).toList(),
            ),
          ),

          SizedBox(height: 24),

          Card(
            color: Colors.blue[50],
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      settingsService.getText(
                        'restart_required',
                        'App restart may be required for some changes to take effect',
                      ),
                      style: TextStyle(color: Colors.blue[800]),
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

  Widget _getLanguageFlag(AppLanguage language) {
    String flag;
    switch (language) {
      case AppLanguage.japanese:
        flag = '🇯🇵';
        break;
      case AppLanguage.english:
        flag = '🇺🇸';
        break;
    }

    return Container(
      width: 40,
      height: 30,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Center(child: Text(flag, style: TextStyle(fontSize: 20))),
    );
  }

  String _getLanguageNativeName(AppLanguage language) {
    switch (language) {
      case AppLanguage.japanese:
        return '日本語';
      case AppLanguage.english:
        return 'English';
    }
  }

  Future<void> _changeLanguage(
    BuildContext context,
    SettingsService settingsService,
    AppLanguage language,
  ) async {
    if (settingsService.currentLanguage == language) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(child: CircularProgressIndicator()),
    );

    try {
      await settingsService.setLanguage(language);

      if (context.mounted) {
        // Close loading dialog
        Navigator.of(context).pop();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              settingsService.getText('language_changed', 'Language changed'),
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Go back to settings
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (context.mounted) {
        // Close loading dialog
        Navigator.of(context).pop();

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${settingsService.getText('error', 'Error')}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
