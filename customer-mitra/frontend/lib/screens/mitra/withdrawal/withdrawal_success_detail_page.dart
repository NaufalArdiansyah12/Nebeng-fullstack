import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/mitra/withdrawal_service.dart';

class WithdrawalSuccessDetailPage extends StatefulWidget {
  final int withdrawalId;

  const WithdrawalSuccessDetailPage({
    super.key,
    required this.withdrawalId,
  });

  @override
  State<WithdrawalSuccessDetailPage> createState() =>
      _WithdrawalSuccessDetailPageState();
}

class _WithdrawalSuccessDetailPageState
    extends State<WithdrawalSuccessDetailPage> {
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
          'Penarikan Saldo Berhasil',
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
                          children: [
                            // Success Icon
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.check,
                                size: 80,
                                color: Colors.green.shade600,
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Transaction Details
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey.shade200,
                                ),
                              ),
                              child: Column(
                                children: [
                                  _buildDetailRow(
                                    'Tanggal',
                                    _withdrawal!['completed_at']
                                            ?.split('|')
                                            .first
                                            .trim() ??
                                        '-',
                                  ),
                                  const Divider(height: 32),
                                  _buildDetailRow(
                                    'ID Transaksi',
                                    _withdrawal!['transaction_id'],
                                  ),
                                  const Divider(height: 32),
                                  _buildDetailRow(
                                    'Penerima',
                                    _withdrawal!['bank_account_name'] ?? '-',
                                  ),
                                  const Divider(height: 32),
                                  _buildDetailRow(
                                    'Jenis Transaksi',
                                    'Transfer Bank ${_withdrawal!['bank_name']}',
                                  ),
                                  const Divider(height: 32),
                                  _buildDetailRow(
                                    'Sumber Dana',
                                    _withdrawal!['bank_account_number'],
                                  ),
                                  const Divider(height: 32),
                                  _buildDetailRow(
                                    'Nominal',
                                    _currencyFormat
                                        .format(_withdrawal!['amount']),
                                  ),
                                  const Divider(height: 32),
                                  _buildDetailRow(
                                    'Biaya Admin',
                                    _currencyFormat
                                        .format(_withdrawal!['admin_fee'] ?? 0),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Info Message
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Selamat penarikan saldo Anda telah diterima. Silahkan periksa rekening bank Anda.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF1E3A8A),
                                ),
                              ),
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
                          onPressed: () {
                            // Pop until home
                            Navigator.popUntil(
                                context, (route) => route.isFirst);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A8A),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Kembali',
                            style: TextStyle(
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
