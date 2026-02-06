import 'package:flutter/material.dart';
import 'detail_pencairan_page.dart';

class RiwayatPencairanPage extends StatefulWidget {
  const RiwayatPencairanPage({Key? key}) : super(key: key);

  @override
  State<RiwayatPencairanPage> createState() => _RiwayatPencairanPageState();
}

class _RiwayatPencairanPageState extends State<RiwayatPencairanPage> {
  int selectedTab = 0; // 0: Semua, 1: Proses, 2: Berhasil

  final List<Map<String, dynamic>> transactions = [
    {
      'date': '21 Okt 2024',
      'time': '09:00',
      'title': 'Penarikan Saldo',
      'amount': -50000.0,
      'status': 'Proses',
      'statusColor': Color(0xFFFFC107),
    },
    {
      'date': '24 Okt 2024',
      'time': '09:00',
      'title': 'Penarikan Saldo',
      'amount': -50000.0,
      'status': 'Berhasil',
      'statusColor': Color(0xFF4CAF50),
    },
    {
      'date': '21 Okt 2024',
      'time': '09:00',
      'title': 'Penarikan Saldo',
      'amount': -50000.0,
      'status': 'Proses',
      'statusColor': Color(0xFFFFC107),
    },
    {
      'date': '24 Okt 2024',
      'time': '09:00',
      'title': 'Penarikan Saldo',
      'amount': -50000.0,
      'status': 'Berhasil',
      'statusColor': Color(0xFF4CAF50),
    },
    {
      'date': '21 Okt 2024',
      'time': '09:00',
      'title': 'Penarikan Saldo',
      'amount': -50000.0,
      'status': 'Proses',
      'statusColor': Color(0xFFFFC107),
    },
    {
      'date': '24 Okt 2024',
      'time': '09:00',
      'title': 'Penarikan Saldo',
      'amount': -50000.0,
      'status': 'Berhasil',
      'statusColor': Color(0xFF4CAF50),
    },
  ];

  List<Map<String, dynamic>> getFilteredTransactions() {
    if (selectedTab == 0) {
      return transactions; // Semua
    } else if (selectedTab == 1) {
      return transactions
          .where((transaction) => transaction['status'] == 'Proses')
          .toList();
    } else {
      return transactions
          .where((transaction) => transaction['status'] == 'Berhasil')
          .toList();
    }
  }

  String _formatCurrency(double amount) {
    final absAmount = amount.abs();
    final formatted = absAmount.toStringAsFixed(0);
    final regex = RegExp(r'\B(?=(\d{3})+(?!\d))');
    final result = formatted.replaceAllMapped(regex, (match) => '.');
    return amount < 0 ? '-Rp $result' : 'Rp $result';
  }

  @override
  Widget build(BuildContext context) {
    final filteredTransactions = getFilteredTransactions();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF212121)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Riwayat Pencairan',
          style: TextStyle(
            color: Color(0xFF212121),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildTabButton('Semua', 0),
                const SizedBox(width: 12),
                _buildTabButton('Proses', 1),
                const SizedBox(width: 12),
                _buildTabButton('Berhasil', 2),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Transaction List
          Expanded(
            child: filteredTransactions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tidak ada riwayat pencairan',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredTransactions.length,
                    itemBuilder: (context, index) {
                      final transaction = filteredTransactions[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildTransactionCard(transaction),
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
              color: isSelected
                  ? const Color(0xFF1E3A8A)
                  : const Color(0xFFE0E0E0),
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF424242),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailPencairanPage(transaction: transaction),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${transaction['date']} ${transaction['time']}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    transaction['title'],
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF212121),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  transaction['status'],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: transaction['statusColor'],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatCurrency(transaction['amount']),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF212121),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
