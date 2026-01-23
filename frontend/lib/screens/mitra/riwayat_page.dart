import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import 'package:nebeng/screens/mitra/detail_tebengan_page.dart';

class MitraRiwayatPage extends StatefulWidget {
  const MitraRiwayatPage({Key? key}) : super(key: key);

  @override
  State<MitraRiwayatPage> createState() => _MitraRiwayatPageState();
}

class _MitraRiwayatPageState extends State<MitraRiwayatPage> {
  final tabs = ['Semua', 'Selesai', 'Proses', 'Dibatalkan'];
  String selected = 'Semua';
  String selectedType = 'Semua';
  bool _isShowingSessionDialog = false;

  List<String> get typeTabs {
    final tabs = <String>['Semua'];
    if (items.any((it) => (it['type'] ?? '') == 'motor')) tabs.add('Motor');
    if (items.any((it) => (it['type'] ?? '') == 'mobil')) tabs.add('Mobil');
    if (items.any((it) => (it['type'] ?? '') == 'barang')) tabs.add('Barang');
    if (items.any((it) => (it['type'] ?? '') == 'titip'))
      tabs.add('Titip Barang');
    return tabs;
  }

  bool loading = false;
  String? error;
  List<Map<String, dynamic>> items = [];

  @override
  void initState() {
    super.initState();
    _loadAndFetch();
  }

  Future<void> _loadAndFetch() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');

      print(
          'Fetching riwayat with token: ${token != null ? "Token exists (${token.length} chars)" : "No token"}');

      if (token == null || token.isEmpty) {
        print('No token found, redirecting to login');
        _handleSessionExpired();
        setState(() {
          error = 'User not authenticated';
          items = [];
          loading = false;
        });
        return;
      }

      final statusParam = _mapSelectedToStatusParam(selected);
      final data =
          await ApiService.fetchMitraHistory(token: token, status: statusParam);

      print('Successfully fetched ${data.length} items');

      setState(() {
        items = data;
        loading = false;
      });
    } catch (e) {
      print('Error fetching mitra history: $e');

      setState(() {
        if (e.toString().contains('401')) {
          print('401 error detected - session expired');
          error = 'Sesi Anda telah berakhir. Silakan login kembali.';
          _handleSessionExpired();
        } else {
          error = e.toString();
        }
        items = [];
        loading = false;
      });
    }
  }

  Future<void> _handleSessionExpired() async {
    if (_isShowingSessionDialog) {
      print('Session expired dialog already showing');
      return;
    }

    _isShowingSessionDialog = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('api_token');
      await prefs.remove('user_id');
      await prefs.remove('user_role');

      print('Cleared session data, showing dialog');

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Sesi Berakhir'),
            content:
                const Text('Sesi Anda telah berakhir. Silakan login kembali.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil('/', (route) => false);
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('Error handling session expired: $e');
      _isShowingSessionDialog = false;
    }
  }

  String? _mapSelectedToStatusParam(String s) {
    switch (s) {
      case 'Selesai':
        return 'selesai';
      case 'Proses':
        return 'proses';
      case 'Dibatalkan':
        return 'dibatalkan';
      default:
        return null;
    }
  }

  // Tab utama dengan underline style
  Widget _filterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      color: Colors.white,
      child: Row(
        children: tabs.map((c) {
          final isSelected = c == selected;
          return Expanded(
            child: InkWell(
              onTap: () {
                setState(() => selected = c);
                _loadAndFetch();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected
                          ? const Color(0xFF1E40AF)
                          : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                child: Text(
                  c,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected
                        ? const Color(0xFF1E40AF)
                        : Colors.grey[600],
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Tab tipe dengan rounded pill style
  Widget _typeChips() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      color: Colors.white,
      child: SizedBox(
        height: 40,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: typeTabs.length,
          itemBuilder: (context, index) {
            final c = typeTabs[index];
            final isSelected = c == selectedType;
            return Container(
              margin: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () {
                  setState(() => selectedType = c);
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF1E40AF) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF1E40AF)
                          : Colors.grey[300]!,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      c,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[700],
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  List<Map<String, dynamic>> get _visibleItems {
    if (selectedType == 'Semua') return items;
    final map = {
      'Motor': 'motor',
      'Mobil': 'mobil',
      'Barang': 'barang',
      'Titip Barang': 'titip'
    };
    final t = map[selectedType] ?? '';
    if (t.isEmpty) return items;
    return items
        .where((it) => (it['type'] ?? '').toString().toLowerCase() == t)
        .toList();
  }

  Widget _card(Map<String, dynamic> item) {
    final ride = item['ride'] ?? {};
    final status = (ride['status'] ?? '').toString().toLowerCase();

    String statusLabel = 'Proses';
    Color statusBgColor = const Color(0xFFDDD6FE);
    Color statusTextColor = const Color(0xFF7C3AED);

    if (status == 'completed' || status.contains('completed')) {
      statusLabel = 'Selesai';
      statusBgColor = const Color(0xFFD1FAE5);
      statusTextColor = const Color(0xFF059669);
    } else if (status == 'active' || status.contains('active')) {
      statusLabel = 'Proses';
      statusBgColor = const Color(0xFFDDD6FE);
      statusTextColor = const Color(0xFF7C3AED);
    } else if (status == 'cancelled' || status.contains('cancel')) {
      statusLabel = 'Dibatalkan';
      statusBgColor = const Color(0xFFFEE2E2);
      statusTextColor = const Color(0xFFDC2626);
    } else if (status == 'full' || status.contains('full')) {
      statusLabel = 'Kosong';
      statusBgColor = const Color(0xFFFEF3C7);
      statusTextColor = const Color(0xFFD97706);
    }

    final origin =
        (ride['origin_location'] is Map && ride['origin_location'] != null)
            ? ride['origin_location']['name'] ?? ''
            : '';
    final destination = (ride['destination_location'] is Map &&
            ride['destination_location'] != null)
        ? ride['destination_location']['name'] ?? ''
        : '';

    final dateStr = (ride['departure_date'] ?? '').toString();
    final timeStr = (ride['departure_time'] ?? '').toString();
    final dateTimeStr = _formatDateTime(dateStr, timeStr);

    final rideType = (item['type'] ?? '').toString().toLowerCase();
    String vehicleLabel = 'Nebeng Motor';
    if (rideType == 'mobil') {
      vehicleLabel = 'Nebeng Mobil';
    } else if (rideType == 'barang') {
      vehicleLabel = 'Nebeng Barang';
    } else if (rideType == 'titip') {
      vehicleLabel = 'Titip Barang';
    }

    final income = (item['income'] ?? 0).toString();
    final displayIncome = _formatPrice(double.tryParse(income) ?? 0);
    final incomeLabel =
        (status == 'completed') ? 'Pendapatan' : 'Estimasi Pendapatan';

    return InkWell(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => MitraTebenganDetailPage(item: item)));
      },
      child: Container(
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    '$dateTimeStr | $vehicleLabel',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusTextColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF3B82F6),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: 2,
                      height: 28,
                      color: Colors.grey[300],
                    ),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        origin.isNotEmpty ? origin : '-',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Alun-alun ${origin.isNotEmpty ? origin : '-'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        destination.isNotEmpty ? destination : '-',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Alun-alun ${destination.isNotEmpty ? destination : '-'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    incomeLabel,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    displayIncome,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(dynamic price) {
    if (price == null) return 'Rp 0,00';
    double amount = 0;
    if (price is int) amount = price.toDouble();
    if (price is double) amount = price;
    if (price is String) amount = double.tryParse(price) ?? 0;
    int intAmount = amount.round();
    final formatted = intAmount.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
    return 'Rp $formatted,00';
  }

  String _formatDateTime(String dateStr, String timeStr) {
    if (dateStr.isEmpty && timeStr.isEmpty) return '';
    DateTime? dt;
    if (dateStr.isNotEmpty) dt = DateTime.tryParse(dateStr);
    if (dt != null && timeStr.isNotEmpty) {
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        final h = int.tryParse(parts[0]) ?? 0;
        final m = int.tryParse(parts[1]) ?? 0;
        dt = DateTime(dt.year, dt.month, dt.day, h, m);
      }
    }
    if (dt == null) return dateStr + (timeStr.isNotEmpty ? ' | $timeStr' : '');
    final days = [
      'Minggu',
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu'
    ];
    final months = [
      '',
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];
    final dayName = days[dt.weekday % 7];
    final day = dt.day.toString().padLeft(2, '0');
    final month = months[dt.month];
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$dayName, $day $month $year | $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Riwayat Tebengan',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.grey[200],
            height: 1,
          ),
        ),
      ),
      body: Column(
        children: [
          _filterChips(),
          _typeChips(),
          Expanded(
            child: Builder(
              builder: (_) {
                if (loading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF0F4AA3)),
                    ),
                  );
                }
                if (error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Terjadi Kesalahan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error!,
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }
                if (_visibleItems.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined,
                            size: 80, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          'Belum Ada Riwayat',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Riwayat tebengan akan muncul di sini',
                          style:
                              TextStyle(color: Colors.grey[500], fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: _loadAndFetch,
                  color: const Color(0xFF0F4AA3),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 16, bottom: 24),
                    itemCount: _visibleItems.length,
                    itemBuilder: (context, i) => _card(_visibleItems[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}