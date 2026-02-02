import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:easy_localization/easy_localization.dart';

/// Helper class untuk handle phone call functionality dengan dialog konfirmasi
class PhoneHelper {
  /// Tampilkan dialog konfirmasi sebelum melakukan phone call
  ///
  /// Parameters:
  /// - context: BuildContext untuk menampilkan dialog
  /// - phoneNumber: Nomor telepon yang akan dihubungi
  /// - userName: Nama user yang akan dihubungi (untuk ditampilkan di dialog)
  /// - userPhoto: URL foto user (optional)
  static Future<void> showCallDialog({
    required BuildContext context,
    required String phoneNumber,
    required String userName,
    String? userPhoto,
  }) async {
    // Validate phone number
    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('phone_not_available'.tr()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Clean phone number (remove spaces, dashes, etc)
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Avatar
                CircleAvatar(
                  radius: 40,
                  backgroundColor: const Color(0xFF0F4AA3).withOpacity(0.1),
                  backgroundImage: userPhoto != null && userPhoto.isNotEmpty
                      ? NetworkImage(userPhoto)
                      : null,
                  child: userPhoto == null || userPhoto.isEmpty
                      ? const Icon(
                          Icons.person,
                          size: 40,
                          color: Color(0xFF0F4AA3),
                        )
                      : null,
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  '${'call_driver'.tr()} $userName',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Phone number
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.phone,
                        size: 20,
                        color: Color(0xFF0F4AA3),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        phoneNumber,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF0F4AA3),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Action buttons
                Row(
                  children: [
                    // Copy button
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: phoneNumber));
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('phone_copied'.tr()),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy, size: 18),
                        label: Text('copy'.tr()),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0F4AA3),
                          side: const BorderSide(color: Color(0xFF0F4AA3)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Call button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.pop(context);
                          await _makePhoneCall(context, cleanNumber);
                        },
                        icon: const Icon(Icons.phone, size: 18),
                        label: Text('call'.tr()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F4AA3),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Cancel button
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'cancel'.tr(),
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Make phone call using url_launcher
  static Future<void> _makePhoneCall(
    BuildContext context,
    String phoneNumber,
  ) async {
    final Uri telUri = Uri(scheme: 'tel', path: phoneNumber);

    try {
      if (await canLaunchUrl(telUri)) {
        await launchUrl(telUri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('cannot_open_phone_app'.tr()),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'error_occurred'.tr()}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Langsung make phone call tanpa dialog (untuk case khusus)
  static Future<void> makeDirectCall({
    required BuildContext context,
    required String phoneNumber,
  }) async {
    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Nomor telepon tidak tersedia'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    await _makePhoneCall(context, cleanNumber);
  }
}
