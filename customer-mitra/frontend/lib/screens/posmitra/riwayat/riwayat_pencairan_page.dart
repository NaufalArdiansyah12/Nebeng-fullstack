import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/posmitra/posmitra_service.dart';
import 'package:nebeng/screens/posmitra/saldo/withdrawal_progress_page.dart';

class RiwayatPencairanPage extends StatefulWidget {
  const RiwayatPencairanPage({Key? key}) : super(key: key);

  @override
  State<RiwayatPencairanPage> createState() => _RiwayatPencairanPageState();
}

class _RiwayatPencairanPageState extends State<RiwayatPencairanPage> {
  int selectedTab = 0; // 0 = Proses, 1 = Berhasil
  bool isLoading = true;
  List<dynamic> transactions = [];

  @override
  void initState() {
    super.initState();
    fetchWithdrawHistory();
  }

  Future<void> fetchWithdrawHistory() async {
    print("🔥 fetchWithdrawHistory TERPANGGIL");
    try {
      final data = await PosMitraService.getWithdrawalHistory();
      setState(() {
        transactions = data;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching withdrawal history: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  List<dynamic> getFilteredTransactions() {
    if (selectedTab == 0) {
      return transactions.where((trx) => trx['status'] != 'completed').toList();
    } else {
      return transactions.where((trx) => trx['status'] == 'completed').toList();
    }
  }

  String formatCurrency(num amount) {
    final format =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return format.format(amount);
  }

  String formatDate(String dateTime) {
    final parsed = DateTime.parse(dateTime);
    return DateFormat('dd MMM yyyy HH:mm', 'id_ID').format(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final filteredTransactions = getFilteredTransactions();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Riwayat Pencairan',
          style: TextStyle(
            color: Color(0xFF212121),
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          // TAB FILTER
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildTabButton('Proses', 0),
                const SizedBox(width: 12),
                _buildTabButton('Berhasil', 1),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // CONTENT
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredTransactions.isEmpty
                    ? const Center(
                        child: Text(
                          'Tidak ada riwayat',
                          style: TextStyle(fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredTransactions.length,
                        itemBuilder: (context, index) {
                          final trx = filteredTransactions[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildTransactionCard(trx),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isSelected = selectedTab == index;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            selectedTab = index;
          });
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1E3A8A) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? const Color(0xFF1E3A8A) : const Color(0xFFE0E0E0),
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF424242),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionCard(dynamic trx) {
    final isCompleted = trx['status'] == 'completed';

    return InkWell(
onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => WithdrawalProgressPage(
        amount: (trx['amount'] as num).toDouble(),
        status: trx['status'],
      ),
    ),
  );
},
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatDate(trx['submitted_at']),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Penarikan Saldo',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    isCompleted ? 'Berhasil' : 'Proses',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isCompleted ? Colors.green : Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    formatCurrency(trx['amount']),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
