import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:convert';
import '../../../services/api_service.dart';
import 'ktp_verification_page.dart';
import 'sim_verification_page.dart';
import 'skck_verification_page.dart';
import 'bank_verification_page.dart';

class VerificationDocumentsPage extends StatefulWidget {
  const VerificationDocumentsPage({Key? key}) : super(key: key);

  @override
  State<VerificationDocumentsPage> createState() =>
      _VerificationDocumentsPageState();
}

class _VerificationDocumentsPageState extends State<VerificationDocumentsPage> {
  Map<String, dynamic>? ktpData;
  Map<String, dynamic>? simData;
  Map<String, dynamic>? skckData;
  Map<String, dynamic>? bankData;
  bool _isAgreed = false;
  bool _isSubmitting = false;

  // Verification status
  String?
      _verificationStatus; // 'not_submitted', 'pending', 'approved', 'rejected'
  Map<String, dynamic>? _verificationData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkVerificationStatus();
  }

  Future<void> _checkVerificationStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('api_token');

    if (token == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final result = await ApiService.getMitraVerificationStatus(token);

      setState(() {
        _verificationStatus = result['status'];
        _verificationData = result['data'];
        _isLoading = false;
      });

      // If not submitted, load saved temp data
      if (_verificationStatus == 'not_submitted') {
        _loadSavedData();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _loadSavedData(); // Fallback to load temp data
    }
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

  Future<void> _submitAllDocuments() async {
    if (!allDocumentsUploaded || !_isAgreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon lengkapi semua dokumen dan centang persetujuan'),
          backgroundColor: Colors.red,
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

      // Submit KTP
      final ktpResult = await ApiService.submitKtpVerification(
        token: token,
        ktpNumber: ktpData!['ktp_number'],
        ktpName: ktpData!['ktp_name'],
        ktpBirthDate: ktpData!['ktp_birth_date'],
        ktpPhotoPath: ktpData!['ktp_photo'],
      );

      if (!ktpResult['success']) {
        throw Exception(ktpResult['message'] ?? 'Gagal submit KTP');
      }

      // Submit SIM
      final simResult = await ApiService.submitSimVerification(
        token: token,
        simNumber: simData!['sim_number'],
        simType: simData!['sim_type'],
        simExpiryDate: simData!['sim_expiry_date'],
        simPhotoPath: simData!['sim_photo'],
      );

      if (!simResult['success']) {
        throw Exception(simResult['message'] ?? 'Gagal submit SIM');
      }

      // Submit SKCK
      final skckResult = await ApiService.submitSkckVerification(
        token: token,
        skckNumber: skckData!['skck_number'],
        skckName: skckData!['skck_name'],
        skckExpiryDate: skckData!['skck_expiry_date'],
        skckPhotoPath: skckData!['skck_photo'],
      );

      if (!skckResult['success']) {
        throw Exception(skckResult['message'] ?? 'Gagal submit SKCK');
      }

      // Submit Bank
      final bankResult = await ApiService.submitBankVerification(
        token: token,
        bankAccountNumber: bankData!['bank_account_number'],
        bankAccountName: bankData!['bank_account_name'],
        bankName: bankData!['bank_name'],
        bankPhotoPath: bankData!['bank_account_photo'],
      );

      if (!bankResult['success']) {
        throw Exception(bankResult['message'] ?? 'Gagal submit Bank');
      }

      // Link all verifications to mitra_verifikasi table
      final linkResult = await ApiService.linkMitraVerifications(token);

      if (!linkResult['success']) {
        throw Exception(
            linkResult['message'] ?? 'Gagal menghubungkan verifikasi');
      }

      // Clear saved data
      await prefs.remove('temp_ktp_data');
      await prefs.remove('temp_sim_data');
      await prefs.remove('temp_skck_data');
      await prefs.remove('temp_bank_data');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Semua dokumen berhasil dikirim!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
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
          'Verifikasi Dokumen',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    // If documents already submitted, show status page
    if (_verificationStatus != null && _verificationStatus != 'not_submitted') {
      return _buildStatusPage();
    }

    // Otherwise, show upload form
    return _buildUploadForm();
  }

  Widget _buildStatusPage() {
    final status = _verificationStatus;
    final data = _verificationData;

    Color statusColor;
    String statusText;
    IconData statusIcon;
    String statusMessage;

    switch (status) {
      case 'approved':
        statusColor = const Color(0xFF10B981);
        statusText = 'Terverifikasi';
        statusIcon = Icons.check_circle;
        statusMessage =
            'Selamat! Semua dokumen Anda telah diverifikasi dan disetujui.';
        break;
      case 'rejected':
        statusColor = const Color(0xFFEF4444);
        statusText = 'Ditolak';
        statusIcon = Icons.cancel;
        statusMessage =
            'Beberapa dokumen Anda ditolak. Silakan hubungi admin untuk informasi lebih lanjut.';
        break;
      default: // pending
        statusColor = const Color(0xFFF59E0B);
        statusText = 'Menunggu Verifikasi';
        statusIcon = Icons.hourglass_empty;
        statusMessage =
            'Dokumen Anda sedang dalam proses verifikasi. Mohon tunggu.';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Icon(statusIcon, size: 64, color: statusColor),
                const SizedBox(height: 16),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  statusMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Document Status List
          const Text(
            'Status Dokumen',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),

          _buildDocumentStatusItem(
            'KTP',
            data?['ktp']?['status'] ?? 'pending',
          ),
          const SizedBox(height: 8),
          _buildDocumentStatusItem(
            'SIM',
            data?['sim']?['status'] ?? 'pending',
          ),
          const SizedBox(height: 8),
          _buildDocumentStatusItem(
            'SKCK',
            data?['skck']?['status'] ?? 'pending',
          ),
          const SizedBox(height: 8),
          _buildDocumentStatusItem(
            'Rekening Bank',
            data?['bank']?['status'] ?? 'pending',
          ),

          const SizedBox(height: 24),

          // Submission Info
          if (data?['submitted_at'] != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey[600], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Dikirim pada ${_formatDate(data?['submitted_at'])}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
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

  Widget _buildDocumentStatusItem(String title, String status) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (status) {
      case 'approved':
        statusColor = const Color(0xFF10B981);
        statusText = 'Disetujui';
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = const Color(0xFFEF4444);
        statusText = 'Ditolak';
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = const Color(0xFFF59E0B);
        statusText = 'Menunggu';
        statusIcon = Icons.hourglass_empty;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }

  Widget _buildUploadForm() {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // User Info Section
              // _buildUserInfo(),
              // const SizedBox(height: 24),

              // Upload Section Title
              const Text(
                'Upload Berkas Anda',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Mohon unggah foto dari berkas-berkas berikut dan isi informasi yang dibutuhkan',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 20),

              // Document Items
              _buildDocumentItem(
                title: 'KTP',
                subtitle: ktpData != null ? 'Sudah di-upload' : 'Upload',
                imagePath: ktpData?['ktp_photo'],
                isUploaded: ktpData != null,
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
              const SizedBox(height: 12),
              _buildDocumentItem(
                title: 'SIM',
                subtitle: simData != null ? 'Sudah di-upload' : 'Upload',
                imagePath: simData?['sim_photo'],
                isUploaded: simData != null,
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
              const SizedBox(height: 12),
              _buildDocumentItem(
                title: 'SKCK',
                subtitle: skckData != null ? 'Sudah di-upload' : 'Upload',
                imagePath: skckData?['skck_photo'],
                isUploaded: skckData != null,
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
              const SizedBox(height: 12),
              _buildDocumentItem(
                title: 'Rekening Bank',
                subtitle: bankData != null ? 'Sudah di-upload' : 'Upload',
                imagePath: bankData?['bank_account_photo'],
                isUploaded: bankData != null,
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
              const SizedBox(height: 20),

              // Agreement Checkbox
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _isAgreed,
                    onChanged: (value) {
                      setState(() => _isAgreed = value ?? false);
                    },
                    activeColor: const Color(0xFF1E40AF),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                            height: 1.5,
                          ),
                          children: [
                            TextSpan(
                              text:
                                  'Dengan ini saya memberikan persetujuan dan mengizinkan Nebeng untuk mengumpulkan dan memproses informasi pribadi saya untuk tujuan pendaftaran akun saya dan menyetujui ',
                            ),
                            TextSpan(
                              text: 'Ketentuan Penggunaan ',
                              style: TextStyle(
                                color: Color(0xFF1E40AF),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            TextSpan(text: 'dan '),
                            TextSpan(
                              text: 'Pemberitahuan Privasi Nebeng',
                              style: TextStyle(
                                color: Color(0xFF1E40AF),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),

        // Bottom Button
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
          child: SafeArea(
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting || !allDocumentsUploaded || !_isAgreed
                    ? null
                    : _submitAllDocuments,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E40AF),
                  disabledBackgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        allDocumentsUploaded
                            ? 'Lanjutkan'
                            : 'Kirim dokumen pendaftaran',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Widget _buildUserInfo() {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       const Text(
  //         'Kamado Tanjiro',
  //         style: TextStyle(
  //           fontSize: 16,
  //           fontWeight: FontWeight.w600,
  //           color: Colors.black87,
  //         ),
  //       ),
  //       const SizedBox(height: 4),
  //       const Text(
  //         'kamado.tanjiro@gmail.com | Yogyakarta',
  //         style: TextStyle(
  //           fontSize: 13,
  //           color: Colors.black54,
  //         ),
  //       ),
  //       const SizedBox(height: 2),
  //       const Text(
  //         '+62-813-4918-2987',
  //         style: TextStyle(
  //           fontSize: 13,
  //           color: Colors.black54,
  //         ),
  //       ),
  //     ],
  //   );
  // }

  Widget _buildDocumentItem({
    required String title,
    required String subtitle,
    String? imagePath,
    required bool isUploaded,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: Colors.grey[300]!,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Image preview or placeholder
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isUploaded ? null : Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
                image: isUploaded && imagePath != null
                    ? DecorationImage(
                        image: FileImage(File(imagePath)),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: !isUploaded
                  ? Icon(
                      Icons.image_outlined,
                      color: Colors.grey[400],
                      size: 28,
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color:
                          isUploaded ? const Color(0xFF10B981) : Colors.black54,
                      fontWeight:
                          isUploaded ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}
