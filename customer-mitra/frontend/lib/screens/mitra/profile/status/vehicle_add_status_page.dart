import 'package:flutter/material.dart';

class VehicleAddStatusPage extends StatefulWidget {
  const VehicleAddStatusPage({Key? key}) : super(key: key);

  @override
  State<VehicleAddStatusPage> createState() => _VehicleAddStatusPageState();
}

class _VehicleAddStatusPageState extends State<VehicleAddStatusPage> {
  bool isLoading = true;
  String status = 'none'; // none, pending, approved, rejected
  bool hasData = false;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    setState(() => isLoading = true);
    // TODO: Implement API call to fetch vehicle addition status
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      // Set hasData = true if there's any vehicle addition request
      hasData = false; // Change this based on API response
      status =
          hasData ? 'pending' : 'none'; // Change this based on API response
      isLoading = false;
    });
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

  String _getButtonLabel() {
    switch (status) {
      case 'approved':
        return 'Lihat daftar kendaraanmu';
      case 'rejected':
        return 'Unggah kembali dokumen';
      default:
        return 'Segarkan';
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
          'Status Kendaraan',
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
                      'Status Penambahan Kendaraan',
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
              'Anda belum melakukan pengajuan penambahan kendaraan.',
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'STNK',
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
          if (status == 'rejected') ...[
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

  Widget _buildActionButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: () {
          if (!hasData) {
            Navigator.pop(context);
          } else if (status == 'rejected') {
            Navigator.pop(context);
          } else if (status == 'approved') {
            Navigator.pop(context);
            // TODO: Navigate to vehicle list
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
          !hasData ? 'Kembali' : _getButtonLabel(),
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
