import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../services/api_service.dart';

class RegistrationStatusPage extends StatefulWidget {
  const RegistrationStatusPage({Key? key}) : super(key: key);

  @override
  State<RegistrationStatusPage> createState() => _RegistrationStatusPageState();
}

class _RegistrationStatusPageState extends State<RegistrationStatusPage> {
  bool isLoading = true;
  String status = 'none'; // none, pending, approved, rejected
  String? rejectionReason;
  bool hasData = false;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');
      if (token != null) {
        final result = await ApiService.getMitraVerificationStatus(token);
        if (result['success'] == true && result['data'] != null) {
          final overallStatus = result['data']['overall_status'];

          // Check if there's any data
          final ktp = result['data']['ktp'];
          final sim = result['data']['sim'];
          final skck = result['data']['skck'];
          final bank = result['data']['bank'];

          final hasAnyData =
              (ktp?['status'] != null && ktp['status'] != 'null') ||
                  (sim?['status'] != null && sim['status'] != 'null') ||
                  (skck?['status'] != null && skck['status'] != 'null') ||
                  (bank?['status'] != null && bank['status'] != 'null');

          setState(() {
            hasData = hasAnyData;
            if (!hasAnyData) {
              status = 'none';
            } else if (overallStatus == 'approved') {
              status = 'approved';
            } else if (overallStatus == 'rejected') {
              status = 'rejected';
              // Check for rejection reason from any document
              if (ktp?['rejection_reason'] != null) {
                rejectionReason = ktp['rejection_reason'];
              } else if (sim?['rejection_reason'] != null) {
                rejectionReason = sim['rejection_reason'];
              } else if (skck?['rejection_reason'] != null) {
                rejectionReason = skck['rejection_reason'];
              } else if (bank?['rejection_reason'] != null) {
                rejectionReason = bank['rejection_reason'];
              }
            } else {
              status = 'pending';
            }
            isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      print('Error loading status: $e');
    }
    setState(() => isLoading = false);
  }

  Color _getStatusColor() {
    switch (status) {
      case 'approved':
        return const Color(0xFF00D4AA);
      case 'rejected':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFFFFA500);
    }
  }

  String _getStatusLabel() {
    switch (status) {
      case 'approved':
        return 'Terverifikasi';
      case 'rejected':
        return 'Ditolak';
      default:
        return 'Sedang diproses';
    }
  }

  String _getStatusMessage() {
    switch (status) {
      case 'approved':
        return 'Dokumen Anda sudah terkirim dan sedang dalam proses verifikasi';
      case 'rejected':
        return 'Dokumen Anda sudah terkirim dan sedang dalam proses verifikasi';
      default:
        return 'Dokumen Anda sudah terkirim dan sedang dalam proses verifikasi';
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
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Status Verifikasi Dokumen',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Status Dokumen Pendaftaran\nMitra Nebeng',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildStatusCard(),
                    const SizedBox(height: 32),
                    _buildActionButton(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatusCard() {
    if (!hasData) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Anda belum melakukan pendaftaran sebagai mitra. Silahkan unggah dokumen verifikasi terlebih dahulu.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getStatusMessage(),
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Dokumen driver',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getStatusLabel(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(),
                  ),
                ),
              ),
            ],
          ),
          if (status == 'rejected' && rejectionReason != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mohon maaf pendaftaran nebeng Anda ditolak, dikarenakan dokumen yang Anda unggah terpotong atau kurang jelas. Silahkan unggah kembali dokumen Anda dan tunggu verifikasi dari kami',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF991B1B),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: () {
          if (!hasData || status == 'rejected') {
            // Navigate back so user can upload documents
            Navigator.pop(context);
          } else if (status == 'approved') {
            Navigator.pop(context);
          } else {
            _loadStatus();
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A43BF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Text(
          !hasData
              ? 'Unggah dokumen'
              : status == 'rejected'
                  ? 'Unggah kembali dokumen'
                  : status == 'approved'
                      ? 'Kembali'
                      : 'Segarkan',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
