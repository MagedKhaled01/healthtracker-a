import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/settings_view_model.dart';
import '../l10n/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Watch settings changes
    final settingsVM = context.watch<SettingsViewModel>();
    final loc = AppLocalizations.of(context)!;

    final isDark = settingsVM.themeMode == ThemeMode.dark;
    final isArabic = settingsVM.locale.languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('settings')),
      ),
      body: settingsVM.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                SwitchListTile(
                  title: Text(loc.translate('dark_mode')),
                  // subtitle: Text(isDark ? loc.translate('on') : loc.translate('off')),
                  secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
                  value: isDark,
                  onChanged: (val) {
                    settingsVM.toggleTheme(val);
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.language),
                  title: Text(loc.translate('language')),
                  // subtitle: Text(isArabic ? 'Arabic' : 'English'),
                  trailing: DropdownButton<String>(
                    value: settingsVM.locale.languageCode,
                    underline: Container(),
                    items: const [
                       DropdownMenuItem(value: 'en', child: Text('English')),
                       DropdownMenuItem(value: 'ar', child: Text('العربية')),
                    ],
                    onChanged: (val) {
                      if (val != null) settingsVM.setLanguage(val);
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
