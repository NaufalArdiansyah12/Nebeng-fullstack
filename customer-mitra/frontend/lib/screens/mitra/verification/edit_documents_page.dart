import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/api_service.dart';
import 'ktp_verification_page.dart';
import 'sim_verification_page.dart';
import 'skck_verification_page.dart';
import 'bank_verification_page.dart';

class EditDocumentsPage extends StatefulWidget {
  final Map<String, dynamic> verificationData;

  const EditDocumentsPage({
    Key? key,
    required this.verificationData,
  }) : super(key: key);

  @override
  State<EditDocumentsPage> createState() => _EditDocumentsPageState();
}

class _EditDocumentsPageState extends State<EditDocumentsPage> {
  Map<String, dynamic>? ktpData;
  Map<String, dynamic>? simData;
  Map<String, dynamic>? skckData;
  Map<String, dynamic>? bankData;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  String _getFullPhotoUrl(String? photoPath) {
    if (photoPath == null || photoPath.isEmpty) return '';

    // If already full URL, return as is
    if (photoPath.startsWith('http://') || photoPath.startsWith('https://')) {
      return photoPath;
    }

    // Build full URL with /storage/ prefix
    final baseUrl = ApiService.baseUrl.replaceAll('/api/v1', '');
    return '$baseUrl/storage/$photoPath';
  }

  Future<void> _initializeData() async {
    // Pre-populate with current verified data
    final data = widget.verificationData;
    final prefs = await SharedPreferences.getInstance();

    // Load KTP data
    if (data['ktp'] != null) {
      final ktpMap = {
        'ktp_number': data['ktp']['ktp_number'] ?? '',
        'ktp_name': data['ktp']['ktp_name'] ?? '',
        'ktp_birth_date': data['ktp']['ktp_birth_date'] ?? '',
        'ktp_photo': _getFullPhotoUrl(data['ktp']['photo']),
      };
      await prefs.setString('temp_ktp_data', jsonEncode(ktpMap));
    }

    // Load SIM data
    if (data['sim'] != null) {
      final simMap = {
        'sim_number': data['sim']['sim_number'] ?? '',
        'nama_lengkap': data['sim']['nama_lengkap'] ?? '',
        'sim_type': data['sim']['sim_type'] ?? 'A',
        'sim_expiry_date': data['sim']['sim_expiry_date'] ?? '',
        'sim_photo': _getFullPhotoUrl(data['sim']['photo']),
      };
      await prefs.setString('temp_sim_data', jsonEncode(simMap));
    }

    // Load SKCK data
    if (data['skck'] != null) {
      final skckMap = {
        'skck_number': data['skck']['skck_number'] ?? '',
        'skck_name': data['skck']['skck_name'] ?? '',
        'skck_expiry_date': data['skck']['skck_expiry_date'] ?? '',
        'skck_photo': _getFullPhotoUrl(data['skck']['photo']),
      };
      await prefs.setString('temp_skck_data', jsonEncode(skckMap));
    }

    // Load Bank data
    if (data['bank'] != null) {
      final bankMap = {
        'bank_account_number': data['bank']['bank_account_number'] ?? '',
        'bank_account_name': data['bank']['bank_account_name'] ?? '',
        'bank_name': data['bank']['bank_name'] ?? '',
        'bank_account_photo': _getFullPhotoUrl(data['bank']['photo']),
      };
      await prefs.setString('temp_bank_data', jsonEncode(bankMap));
    }

    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();

    final ktpJson = prefs.getString('temp_ktp_data');
    final simJson = prefs.getString('temp_sim_data');
    final skckJson = prefs.getString('temp_skck_data');
    final bankJson = prefs.getString('temp_bank_data');

    setState(() {
      ktpData = ktpJson != null ? jsonDecode(ktpJson) : null;
      simData = simJson != null ? jsonDecode(simJson) : null;
      skckData = skckJson != null ? jsonDecode(skckJson) : null;
      bankData = bankJson != null ? jsonDecode(bankJson) : null;
    });
  }

  bool get allDocumentsUploaded {
    return ktpData != null &&
        simData != null &&
        skckData != null &&
        bankData != null;
  }

  Future<void> _submitChanges() async {
    if (!allDocumentsUploaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon lengkapi semua dokumen'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if there are any changes to submit
    final hasKtpChanges = ktpData != null &&
        ktpData!['ktp_photo'] != null &&
        !ktpData!['ktp_photo'].toString().startsWith('http');
    final hasSimChanges = simData != null &&
        simData!['sim_photo'] != null &&
        !simData!['sim_photo'].toString().startsWith('http');
    final hasSkckChanges = skckData != null &&
        skckData!['skck_photo'] != null &&
        !skckData!['skck_photo'].toString().startsWith('http');
    final hasBankChanges = bankData != null &&
        bankData!['bank_account_photo'] != null &&
        !bankData!['bank_account_photo'].toString().startsWith('http');

    if (!hasKtpChanges &&
        !hasSimChanges &&
        !hasSkckChanges &&
        !hasBankChanges) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak ada perubahan dokumen untuk dikirim'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');

      if (token == null) {
        throw Exception('Token tidak ditemukan. Silakan login kembali.');
      }

      // Submit only changed documents
      // Submit KTP if changed
      if (hasKtpChanges) {
        await ApiService.updateKtpVerification(
          token: token,
          ktpNumber: ktpData!['ktp_number'],
          ktpName: ktpData!['ktp_name'],
          ktpBirthDate: ktpData!['ktp_birth_date'],
          ktpPhotoPath: ktpData!['ktp_photo'],
        );
      }

      // Submit SIM if changed
      if (hasSimChanges) {
        await ApiService.updateSimVerification(
          token: token,
          simNumber: simData!['sim_number'],
          namaLengkap: simData!['nama_lengkap'] ?? '',
          simType: simData!['sim_type'],
          simExpiryDate: simData!['sim_expiry_date'],
          simPhotoPath: simData!['sim_photo'],
        );
      }

      // Submit SKCK if changed
      if (hasSkckChanges) {
        await ApiService.updateSkckVerification(
          token: token,
          skckNumber: skckData!['skck_number'],
          skckName: skckData!['skck_name'],
          skckExpiryDate: skckData!['skck_expiry_date'],
          skckPhotoPath: skckData!['skck_photo'],
        );
      }

      // Submit Bank if changed
      if (hasBankChanges) {
        await ApiService.updateBankVerification(
          token: token,
          bankAccountNumber: bankData!['bank_account_number'],
          bankAccountName: bankData!['bank_account_name'],
          bankName: bankData!['bank_name'],
          bankPhotoPath: bankData!['bank_account_photo'],
        );
      }

      // Link verifications
      await ApiService.linkMitraVerifications(token);

      // Clear saved data
      await prefs.remove('temp_ktp_data');
      await prefs.remove('temp_sim_data');
      await prefs.remove('temp_skck_data');
      await prefs.remove('temp_bank_data');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Perubahan dokumen berhasil dikirim. Status verifikasi Anda diubah menjadi menunggu persetujuan admin.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
        // Pop twice to go back to profile/home page
        Navigator.pop(context, true);
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Dokumen',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // KTP
                _buildDocumentItem(
                  title: 'KTP',
                  subtitle: ktpData != null
                      ? (ktpData!['ktp_photo']?.startsWith('http') == true
                          ? 'Sudah di-upload'
                          : 'Klik tombol kirim perubahan untuk verifikasi admin')
                      : 'Belum di-upload',
                  imagePath: ktpData?['ktp_photo'],
                  isUploaded: ktpData != null,
                  hasChanges: ktpData != null &&
                      ktpData!['ktp_photo']?.startsWith('http') == false,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const KtpVerificationPage(),
                      ),
                    );
                    _loadSavedData();
                  },
                ),
                const SizedBox(height: 16),

                // SIM
                _buildDocumentItem(
                  title: 'SIM',
                  subtitle: simData != null
                      ? (simData!['sim_photo']?.startsWith('http') == true
                          ? 'Sudah di-upload'
                          : 'Klik tombol kirim perubahan untuk verifikasi admin')
                      : 'Belum di-upload',
                  imagePath: simData?['sim_photo'],
                  isUploaded: simData != null,
                  hasChanges: simData != null &&
                      simData!['sim_photo']?.startsWith('http') == false,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SimVerificationPage(),
                      ),
                    );
                    _loadSavedData();
                  },
                ),
                const SizedBox(height: 16),

                // SKCK
                _buildDocumentItem(
                  title: 'SKCK',
                  subtitle: skckData != null
                      ? (skckData!['skck_photo']?.startsWith('http') == true
                          ? 'Sudah di-upload'
                          : 'Klik tombol kirim perubahan untuk verifikasi admin')
                      : 'Belum di-upload',
                  imagePath: skckData?['skck_photo'],
                  isUploaded: skckData != null,
                  hasChanges: skckData != null &&
                      skckData!['skck_photo']?.startsWith('http') == false,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SkckVerificationPage(),
                      ),
                    );
                    _loadSavedData();
                  },
                ),
                const SizedBox(height: 16),

                // Rekening Bank
                _buildDocumentItem(
                  title: 'Rekening Bank',
                  subtitle: bankData != null
                      ? (bankData!['bank_account_photo']?.startsWith('http') ==
                              true
                          ? 'Sudah di-upload'
                          : 'Klik tombol kirim perubahan untuk verifikasi admin')
                      : 'Belum di-upload',
                  imagePath: bankData?['bank_account_photo'],
                  isUploaded: bankData != null,
                  hasChanges: bankData != null &&
                      bankData!['bank_account_photo']?.startsWith('http') ==
                          false,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BankVerificationPage(),
                      ),
                    );
                    _loadSavedData();
                  },
                ),
              ],
            ),
          ),

          // Submit Button
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                // Warning message
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber[200]!),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline,
                          size: 18, color: Colors.amber[900]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Perubahan dokumen akan direview kembali oleh admin.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.amber[900],
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A43BF),
                      disabledBackgroundColor: Colors.grey[300],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Kirim Perubahan',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentItem({
    required String title,
    required String subtitle,
    String? imagePath,
    required bool isUploaded,
    bool hasChanges = false,
    required VoidCallback onTap,
  }) {
    // Check if image is local file or network URL
    final bool isLocalFile = imagePath != null &&
        imagePath.isNotEmpty &&
        !imagePath.startsWith('http');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Document preview image
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: imagePath != null && imagePath.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: isLocalFile
                          ? Image.file(
                              File(imagePath),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(Icons.image,
                                    size: 32, color: Colors.grey[400]);
                              },
                            )
                          : Image.network(
                              imagePath,
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                    strokeWidth: 2,
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(Icons.image,
                                    size: 32, color: Colors.grey[400]);
                              },
                            ),
                    )
                  : Icon(Icons.image, size: 32, color: Colors.grey[400]),
            ),
            const SizedBox(width: 16),

            // Title and subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: hasChanges
                          ? Colors.orange[700]
                          : (isUploaded
                              ? const Color(0xFF00D4AA)
                              : Colors.grey[600]),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Change button
            OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF1A43BF)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: const Text(
                'Ubah',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A43BF),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
