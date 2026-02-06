import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/mitra/withdrawal_service.dart';
import 'withdrawal_progress_page.dart';
import 'withdrawal_success_detail_page.dart';

class WithdrawalDetailPage extends StatefulWidget {
  final int withdrawalId;

  const WithdrawalDetailPage({
    super.key,
    required this.withdrawalId,
  });

  @override
  State<WithdrawalDetailPage> createState() => _WithdrawalDetailPageState();
}

class _WithdrawalDetailPageState extends State<WithdrawalDetailPage> {
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _withdrawal;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');

      if (token == null) {
        throw Exception('Token tidak ditemukan');
      }

      final detail = await WithdrawalService.getWithdrawalDetail(
        token: token,
        withdrawalId: widget.withdrawalId,
      );

      setState(() {
        _withdrawal = detail.toJson();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'processing':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'failed':
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'processing':
        return 'Pencairan Proses';
      case 'completed':
        return 'Pencairan Berhasil';
      case 'failed':
        return 'Pencairan Gagal';
      case 'rejected':
        return 'Pencairan Ditolak';
      default:
        return status;
    }
  }

  String _getStatusDescription(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'processing':
        return 'Pengajuan sedang di proses';
      case 'completed':
        return 'Pengajuan selesai';
      case 'failed':
        return 'Pengajuan gagal diproses';
      case 'rejected':
        return 'Pengajuan ditolak';
      default:
        return '';
    }
  }

  void _navigateToProgress() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => WithdrawalProgressPage(
          withdrawalId: widget.withdrawalId,
          transactionId: _withdrawal!['transaction_id'],
        ),
      ),
    );
  }

  void _navigateToSuccess() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => WithdrawalSuccessDetailPage(
          withdrawalId: widget.withdrawalId,
        ),
      ),
    );
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
          'Detail Pencairan',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _loadDetail,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A8A),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 12,
                            ),
                          ),
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Status Header with Icon
                            Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: _withdrawal!['status'] == 'completed'
                                        ? Colors.green.shade50
                                        : Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.receipt_long_outlined,
                                    size: 24,
                                    color: _withdrawal!['status'] == 'completed'
                                        ? Colors.green
                                        : const Color(0xFF1E3A8A),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _getStatusText(_withdrawal!['status']),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _getStatusDescription(
                                            _withdrawal!['status']),
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),

                            // Transaction Details
                            _buildDetailRow(
                              'Jumlah Tarik Saldo',
                              _currencyFormat.format(_withdrawal!['amount']),
                            ),
                            const Divider(height: 32),
                            _buildDetailRow(
                              'ID Transaksi',
                              _withdrawal!['transaction_id'],
                            ),
                            const Divider(height: 32),
                            _buildDetailRow(
                              'Tanggal',
                              _withdrawal!['submitted_at']
                                      ?.split('|')
                                      .first
                                      .trim() ??
                                  '-',
                            ),
                            if (_withdrawal!['status'] == 'completed') ...[
                              const Divider(height: 32),
                              _buildDetailRow(
                                'Pencairan',
                                _withdrawal!['completed_at']
                                        ?.split('|')
                                        .first
                                        .trim() ??
                                    '-',
                              ),
                            ],
                            if (_withdrawal!['status'] == 'rejected' &&
                                _withdrawal!['rejection_reason'] != null) ...[
                              const Divider(height: 32),
                              _buildDetailRow(
                                'Alasan Penolakan',
                                _withdrawal!['rejection_reason'],
                              ),
                            ],
                            const Divider(height: 32),
                            _buildDetailRow(
                              'Waktu',
                              _withdrawal!['submitted_at']
                                      ?.split('|')
                                      .last
                                      .trim() ??
                                  '-',
                            ),
                            const Divider(height: 32),
                            _buildDetailRow(
                              'Pembayaran',
                              'Transfer Bank ${_withdrawal!['bank_name']}',
                            ),
                            const Divider(height: 32),
                            _buildDetailRow(
                              'No Rekening',
                              _withdrawal!['bank_account_number'],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Bottom Button
                    Container(
                      padding: const EdgeInsets.all(24),
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
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _withdrawal!['status'] == 'completed'
                              ? _navigateToSuccess
                              : _navigateToProgress,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A8A),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            _withdrawal!['status'] == 'completed'
                                ? 'Lihat Bukti'
                                : 'Lihat Progres',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
