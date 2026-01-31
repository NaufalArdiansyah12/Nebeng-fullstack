import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../utils/app_localizations.dart';

/// Contoh penggunaan localization di berbagai widget
class LocalizationExamples extends StatelessWidget {
  const LocalizationExamples({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('language'.tr()), // Metode 1: Langsung dengan .tr()
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // CONTOH 1: Menggunakan .tr() extension
          Text('profile'.tr()),
          const SizedBox(height: 8),

          // CONTOH 2: Menggunakan Helper Class (Recommended)
          Text(AppLocalizations.editProfile),
          const SizedBox(height: 8),

          // CONTOH 3: Di dalam widget parameter
          ElevatedButton(
            onPressed: () {},
            child: Text('save'.tr()),
          ),
          const SizedBox(height: 16),

          // CONTOH 4: Untuk SnackBar
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('language_changed_success'.tr()),
                ),
              );
            },
            child: const Text('Show SnackBar'),
          ),
          const SizedBox(height: 16),

          // CONTOH 5: Untuk Dialog
          ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('confirmation'.tr()),
                  content: Text('are_you_sure_logout'.tr()),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('no'.tr()),
                    ),
                    TextButton(
                      onPressed: () {
                        // Logout logic
                        Navigator.pop(context);
                      },
                      child: Text('yes'.tr()),
                    ),
                  ],
                ),
              );
            },
            child: const Text('Show Dialog'),
          ),
          const SizedBox(height: 16),

          // CONTOH 6: Conditional text berdasarkan status
          _buildStatusText('success'),
          _buildStatusText('failed'),
          _buildStatusText('processing'),
          const SizedBox(height: 16),

          // CONTOH 7: Ganti bahasa programmatically
          Row(
            children: [
              ElevatedButton(
                onPressed: () => context.setLocale(const Locale('id')),
                child: const Text('🇮🇩 ID'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => context.setLocale(const Locale('en')),
                child: const Text('🇬🇧 EN'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // CONTOH 8: Menampilkan bahasa saat ini
          Text('Current language: ${context.locale.languageCode}'),
        ],
      ),
    );
  }

  Widget _buildStatusText(String status) {
    String translatedStatus;
    Color color;

    switch (status) {
      case 'success':
        translatedStatus = 'success'.tr();
        color = Colors.green;
        break;
      case 'failed':
        translatedStatus = 'failed'.tr();
        color = Colors.red;
        break;
      case 'processing':
        translatedStatus = 'processing'.tr();
        color = Colors.orange;
        break;
      default:
        translatedStatus = status;
        color = Colors.grey;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        translatedStatus,
        style: TextStyle(color: color),
      ),
    );
  }
}
