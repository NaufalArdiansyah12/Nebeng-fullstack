import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/withdrawal_model.dart';
import '../../../services/mitra/withdrawal_service.dart';
import 'withdrawal_success_page.dart';

class WithdrawalProgressPage extends StatefulWidget {
  final int withdrawalId;
  final String transactionId;

  const WithdrawalProgressPage({
    super.key,
    required this.withdrawalId,
    required this.transactionId,
  });

  @override
  State<WithdrawalProgressPage> createState() => _WithdrawalProgressPageState();
}

class _WithdrawalProgressPageState extends State<WithdrawalProgressPage> {
  bool _isLoading = true;
  WithdrawalModel? _withdrawal;
  String? _errorMessage;
  Timer? _statusCheckTimer;

  @override
  void initState() {
    super.initState();
    _loadWithdrawalDetail();
    _startStatusChecking();
  }

  @override
  void dispose() {
    _statusCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadWithdrawalDetail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');

      if (token == null) {
        throw Exception('Token tidak ditemukan');
      }

      final withdrawal = await WithdrawalService.getWithdrawalDetail(
        token: token,
        withdrawalId: widget.withdrawalId,
      );

      if (!mounted) return;

      setState(() {
        _withdrawal = withdrawal;
        _isLoading = false;
      });

      // Check if already completed
      if (withdrawal.status == 'completed') {
        _statusCheckTimer?.cancel();
        _navigateToSuccess();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _startStatusChecking() {
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _checkStatus();
    });
  }

  Future<void> _checkStatus() async {
    if (_withdrawal == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');

      if (token == null) return;

      final statusData = await WithdrawalService.checkStatus(
        token: token,
        withdrawalId: widget.withdrawalId,
      );

      if (!mounted) return;

      if (statusData['is_completed'] == true) {
        _statusCheckTimer?.cancel();

        // Reload detail to get updated progress
        await _loadWithdrawalDetail();

        // Navigate to success page after a short delay
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          _navigateToSuccess();
        }
      }
    } catch (e) {
      // Silently fail status check
    }
  }

  void _navigateToSuccess() {
    if (_withdrawal == null) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => WithdrawalSuccessPage(
          withdrawal: _withdrawal!,
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
          'Progres Tarik Saldo',
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
                          onPressed: () {
                            Navigator.of(context).popUntil(
                              (route) => route.isFirst,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A8A),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 12,
                            ),
                          ),
                          child: const Text('Kembali'),
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
                            // Progress Items
                            if (_withdrawal?.progress != null)
                              ..._withdrawal!.progress!
                                  .asMap()
                                  .entries
                                  .map((entry) {
                                final index = entry.key;
                                final item = entry.value;
                                final isLast =
                                    index == _withdrawal!.progress!.length - 1;

                                return _buildProgressItem(
                                  title: item.title,
                                  description: item.description,
                                  date: item.date,
                                  time: item.time,
                                  isCompleted: item.completed,
                                  isLast: isLast,
                                );
                              }).toList(),

                            const SizedBox(height: 32),

                            // Detail Section
                            const Text(
                              'Detail Tarik Saldo',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),

                            _buildDetailRow(
                              'Rincian Dana Saldo',
                              '',
                              isHeader: false,
                            ),
                            const Divider(height: 24),
                            _buildDetailRow(
                              'Total Dana Asli',
                              'Rp${_withdrawal!.amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                              isHeader: false,
                            ),
                            const Divider(height: 24),
                            _buildDetailRow(
                              'Estimasi Tarik Saldo',
                              'Rp${_withdrawal!.totalAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                              isHeader: false,
                            ),
                            const SizedBox(height: 24),

                            // Duration Section
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.access_time,
                                    size: 20,
                                    color: Color(0xFF1E3A8A),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _withdrawal!.estimatedDuration ??
                                          'Durasi Proses Pencairan',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF1E3A8A),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
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
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Color(0xFF1E3A8A),
                              width: 2,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Kembali',
                            style: TextStyle(
                              color: Color(0xFF1E3A8A),
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

  Widget _buildProgressItem({
    required String title,
    required String description,
    String? date,
    String? time,
    required bool isCompleted,
    required bool isLast,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted
                      ? const Color(0xFF1E3A8A)
                      : Colors.grey.shade300,
                ),
                child: isCompleted
                    ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      )
                    : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isCompleted
                        ? const Color(0xFF1E3A8A)
                        : Colors.grey.shade300,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isCompleted ? Colors.black : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  if (date != null && time != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '$date | $time',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isHeader = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isHeader ? 14 : 13,
            fontWeight: isHeader ? FontWeight.w600 : FontWeight.normal,
            color: isHeader ? Colors.black : Colors.grey.shade700,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isHeader ? 14 : 13,
            fontWeight: isHeader ? FontWeight.w600 : FontWeight.w500,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}
