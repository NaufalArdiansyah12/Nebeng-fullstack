import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/verifikasi_service.dart';
import 'verifikasi_type_page.dart';

class VerifikasiStatusPage extends StatefulWidget {
  const VerifikasiStatusPage({Key? key}) : super(key: key);

  @override
  State<VerifikasiStatusPage> createState() => _VerifikasiStatusPageState();
}

class _VerifikasiStatusPageState extends State<VerifikasiStatusPage> {
  bool _isLoading = true;
  Map<String, dynamic>? _verificationStatus;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadVerificationStatus();
  }

  Future<void> _loadVerificationStatus() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');

      if (token == null) {
        throw Exception('Token tidak ditemukan. Silakan login kembali.');
      }

      final response = await VerifikasiService.getVerificationStatus(token);

      setState(() {
        _verificationStatus = response['data'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
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
          'Verifikasi',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorState()
              : _buildContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Color(0xFFEF4444),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF666666),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadVerificationStatus,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E40AF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final hasVerification = _verificationStatus?['has_verification'] ?? false;
    final status = _verificationStatus?['status'];
    final verifikasiWajah = _verificationStatus?['verifikasi_wajah'] ?? false;
    final verifikasiKtp = _verificationStatus?['verifikasi_ktp'] ?? false;
    final verifikasiWajahKtp =
        _verificationStatus?['verifikasi_wajah_ktp'] ?? false;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Verifikasi Identitas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Lengkapi langkah-langkah berikut ini',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF999999),
            ),
          ),
          const SizedBox(height: 32),
          // Verification status items
          _buildVerificationItem(
            icon: Icons.face,
            title: 'Verifikasi wajah',
            isCompleted: verifikasiWajah,
            status: hasVerification ? status : null,
          ),
          const SizedBox(height: 16),
          _buildVerificationItem(
            icon: Icons.credit_card,
            title: 'Verifikasi e-ktp',
            isCompleted: verifikasiKtp,
            status: hasVerification ? status : null,
          ),
          const SizedBox(height: 16),
          _buildVerificationItem(
            icon: Icons.how_to_reg,
            title: 'Verifikasi wajah dan e-ktp',
            isCompleted: verifikasiWajahKtp,
            status: hasVerification ? status : null,
          ),
          const Spacer(),
          // Status information
          if (hasVerification) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getStatusColor(status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getStatusColor(status).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getStatusIcon(status),
                    color: _getStatusColor(status),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getStatusTitle(status),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(status),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getStatusMessage(status),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF666666),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          // Action button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: hasVerification &&
                      (status == 'pending' || status == 'approved')
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const VerifikasiTypePage(),
                        ),
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E40AF),
                disabledBackgroundColor: const Color(0xFFE5E7EB),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: Text(
                hasVerification && status == 'approved'
                    ? 'Verifikasi Selesai'
                    : hasVerification && status == 'pending'
                        ? 'Menunggu Review'
                        : 'Lanjut',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: hasVerification &&
                          (status == 'pending' || status == 'approved')
                      ? const Color(0xFF9CA3AF)
                      : Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildVerificationItem({
    required IconData icon,
    required String title,
    required bool isCompleted,
    String? status,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCompleted ? const Color(0xFF1E40AF) : Colors.white,
        border: Border.all(
          color:
              isCompleted ? const Color(0xFF1E40AF) : const Color(0xFFE5E7EB),
          width: isCompleted ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isCompleted
                  ? Colors.white.withOpacity(0.2)
                  : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              icon,
              color: isCompleted ? Colors.white : const Color(0xFF6B7280),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isCompleted ? FontWeight.w600 : FontWeight.w500,
                color: isCompleted ? Colors.white : const Color(0xFF4B5563),
              ),
            ),
          ),
          if (isCompleted)
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Color(0xFF1E40AF),
                size: 16,
              ),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'approved':
        return const Color(0xFF10B981);
      case 'rejected':
        return const Color(0xFFEF4444);
      case 'pending':
      default:
        return const Color(0xFFF59E0B);
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status) {
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'pending':
      default:
        return Icons.pending;
    }
  }

  String _getStatusTitle(String? status) {
    switch (status) {
      case 'approved':
        return 'Verifikasi Disetujui';
      case 'rejected':
        return 'Verifikasi Ditolak';
      case 'pending':
      default:
        return 'Menunggu Review';
    }
  }

  String _getStatusMessage(String? status) {
    switch (status) {
      case 'approved':
        return 'Akun Anda telah terverifikasi';
      case 'rejected':
        return 'Silakan upload ulang dokumen verifikasi';
      case 'pending':
      default:
        return 'Verifikasi sedang dalam proses review';
    }
  }
}
