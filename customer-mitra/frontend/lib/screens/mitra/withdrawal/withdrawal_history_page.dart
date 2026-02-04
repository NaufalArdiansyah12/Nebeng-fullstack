import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/withdrawal_service.dart';
import 'withdrawal_detail_page.dart';

class WithdrawalHistoryPage extends StatefulWidget {
  const WithdrawalHistoryPage({super.key});

  @override
  State<WithdrawalHistoryPage> createState() => _WithdrawalHistoryPageState();
}

class _WithdrawalHistoryPageState extends State<WithdrawalHistoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _allWithdrawals = [];
  List<Map<String, dynamic>> _processingWithdrawals = [];
  List<Map<String, dynamic>> _completedWithdrawals = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadWithdrawals();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadWithdrawals() async {
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

      // Load all withdrawals
      final allData = await WithdrawalService.getHistory(token: token);
      final processingData = await WithdrawalService.getHistory(
        token: token,
        status: 'processing',
      );
      final completedData = await WithdrawalService.getHistory(
        token: token,
        status: 'completed',
      );

      setState(() {
        _allWithdrawals = allData;
        _processingWithdrawals = processingData;
        _completedWithdrawals = completedData;
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

  Widget _buildWithdrawalList(List<Map<String, dynamic>> withdrawals) {
    if (withdrawals.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Belum ada riwayat penarikan',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: withdrawals.length,
      itemBuilder: (context, index) {
        final withdrawal = withdrawals[index];
        return _buildWithdrawalCard(withdrawal);
      },
    );
  }

  Widget _buildWithdrawalCard(Map<String, dynamic> withdrawal) {
    final amount =
        double.tryParse(withdrawal['amount']?.toString() ?? '0') ?? 0.0;
    final status = withdrawal['status'] as String? ?? '';
    final statusLabel = withdrawal['status_label'] as String? ?? '';
    final date = withdrawal['submitted_at'] as String? ?? '-';
    final time = withdrawal['submitted_at_time'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => WithdrawalDetailPage(
                  withdrawalId: withdrawal['id'],
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$date  $time',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 12,
                          color: _getStatusColor(status),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Penarikan Saldo',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      '-${_currencyFormat.format(amount)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
          'Riwayat Penarikan',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF1E3A8A),
              labelColor: const Color(0xFF1E3A8A),
              unselectedLabelColor: Colors.grey,
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              tabs: const [
                Tab(text: 'Semua'),
                Tab(text: 'Proses'),
                Tab(text: 'Berhasil'),
              ],
            ),
          ),
        ),
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
                          onPressed: _loadWithdrawals,
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
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildWithdrawalList(_allWithdrawals),
                    _buildWithdrawalList(_processingWithdrawals),
                    _buildWithdrawalList(_completedWithdrawals),
                  ],
                ),
    );
  }
}
