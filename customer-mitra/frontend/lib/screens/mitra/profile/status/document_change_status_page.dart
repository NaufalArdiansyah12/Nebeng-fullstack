import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../services/api_service.dart';

class DocumentChangeStatusPage extends StatefulWidget {
  const DocumentChangeStatusPage({Key? key}) : super(key: key);

  @override
  State<DocumentChangeStatusPage> createState() =>
      _DocumentChangeStatusPageState();
}

class _DocumentChangeStatusPageState extends State<DocumentChangeStatusPage> {
  bool isLoading = true;
  bool hasData = false;
  Map<String, dynamic> statuses = {
    'ktp': {'status': 'none', 'rejectionReason': null},
    'sim': {'status': 'none', 'rejectionReason': null},
    'skck': {'status': 'none', 'rejectionReason': null},
    'bank': {'status': 'none', 'rejectionReason': null},
  };

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
          final data = result['data'];

          bool dataExists = false;

          setState(() {
            // KTP
            if (data['ktp'] != null &&
                data['ktp']['status'] != null &&
                data['ktp']['status'] != 'null') {
              statuses['ktp'] = {
                'status': data['ktp']['status'],
                'rejectionReason': data['ktp']['rejection_reason'],
              };
              dataExists = true;
            }
            // SIM
            if (data['sim'] != null &&
                data['sim']['status'] != null &&
                data['sim']['status'] != 'null') {
              statuses['sim'] = {
                'status': data['sim']['status'],
                'rejectionReason': data['sim']['rejection_reason'],
              };
              dataExists = true;
            }
            // SKCK
            if (data['skck'] != null &&
                data['skck']['status'] != null &&
                data['skck']['status'] != 'null') {
              statuses['skck'] = {
                'status': data['skck']['status'],
                'rejectionReason': data['skck']['rejection_reason'],
              };
              dataExists = true;
            }
            // Bank
            if (data['bank'] != null &&
                data['bank']['status'] != null &&
                data['bank']['status'] != 'null') {
              statuses['bank'] = {
                'status': data['bank']['status'],
                'rejectionReason': data['bank']['rejection_reason'],
              };
              dataExists = true;
            }
            hasData = dataExists;
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return const Color(0xFF00D4AA);
      case 'rejected':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFFFFA500);
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'approved':
        return 'Terverifikasi';
      case 'rejected':
        return 'Ditolak';
      default:
        return 'Sedang diproses';
    }
  }

  bool _hasRejection() {
    return statuses.values.any((s) => s['status'] == 'rejected');
  }

  bool _allApproved() {
    return statuses.values.every((s) => s['status'] == 'approved');
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
          'Status Perubahan Dokumen',
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
                      'Status Perubahan Dokumen Mitra\nNebeng',
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
              'Anda belum melakukan perubahan dokumen. Silahkan unggah dokumen verifikasi terlebih dahulu.',
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
            'Dokumen Anda sudah terkirim dan sedang dalam proses verifikasi',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          if (statuses['ktp']!['status'] != 'none') ...[
            _buildDocumentStatus('KTP', statuses['ktp']!),
            const SizedBox(height: 12)
          ],
          if (statuses['sim']!['status'] != 'none') ...[
            _buildDocumentStatus('SIM', statuses['sim']!),
            const SizedBox(height: 12)
          ],
          if (statuses['skck']!['status'] != 'none') ...[
            _buildDocumentStatus('SKCK', statuses['skck']!),
            const SizedBox(height: 12)
          ],
          if (statuses['bank']!['status'] != 'none')
            _buildDocumentStatus('Rekening Bank', statuses['bank']!),
          if (_hasRejection()) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: const Text(
                'Mohon maaf pendaftaran nebeng Anda ditolak, dikarenakan dokumen yang Anda unggah terpotong atau kurang jelas. Silahkan unggah kembali dokumen Anda dan tunggu verifikasi dari kami',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF991B1B),
                  height: 1.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDocumentStatus(String label, Map<String, dynamic> statusData) {
    final status = statusData['status'] as String;
    final color = _getStatusColor(status);
    final statusLabel = _getStatusLabel(status);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            statusLabel,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: () {
          if (!hasData || _hasRejection()) {
            Navigator.pop(context);
          } else if (_allApproved()) {
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
              : _hasRejection()
                  ? 'Unggah kembali dokumen'
                  : _allApproved()
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
