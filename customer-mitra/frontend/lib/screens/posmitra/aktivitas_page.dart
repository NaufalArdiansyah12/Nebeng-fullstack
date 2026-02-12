import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/posmitra/posmitra_service.dart';

class AktivitasPage extends StatefulWidget {
  const AktivitasPage({Key? key}) : super(key: key);

  @override
  State<AktivitasPage> createState() => _AktivitasPageState();
}

class _AktivitasPageState extends State<AktivitasPage> {
  int selectedTab = 0; // 0: Semua, 1: Proses (active), 2: Kosong (full)
  List<Map<String, dynamic>> allRides = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUpcomingRides();
  }

  Future<void> _loadUpcomingRides() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final rides = await PosMitraService.getUpcomingRides();
      setState(() {
        allRides = rides;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString().replaceAll('Exception: ', '');
        isLoading = false;
      });
    }
  }

List<Map<String, dynamic>> getFilteredActivities() {
  if (selectedTab == 0) {
    // Semua, termasuk completed
    return allRides;
  } else if (selectedTab == 1) {
    // Proses / aktif
    return allRides.where((ride) => ride['status'] == 'active').toList();
  } else if (selectedTab == 2) {
    // Selesai (sebelumnya Kosong / full)
    return allRides.where((ride) => ride['status'] == 'completed').toList();
  } else {
    return allRides;
  }
}

  String _formatDateTime(String date, String time) {
    try {
      // Parse date (format: 2026-02-05 or 2026-02-05 00:00:00.000000Z)
      final cleanDate = date.split(' ')[0];
      // Parse time (format: 12:13:00)
      final cleanTime = time.split('.')[0];

      final dateTime = DateTime.parse('$cleanDate $cleanTime');
      final dayName = DateFormat('EEE', 'id_ID').format(dateTime);
      final formattedDate =
          DateFormat('dd MMMM yyyy', 'id_ID').format(dateTime);
      final formattedTime = DateFormat('HH:mm').format(dateTime);
      return '$dayName, $formattedDate | $formattedTime';
    } catch (e) {
      return '$date | $time';
    }
  }

  String _getRideTypeLabel(String rideType, String serviceType) {
    if (serviceType == 'barang') return 'Titip Barang';
    if (rideType == 'motor') return 'Nabung Motor';
    if (rideType == 'mobil') return 'Nabung Mobil';
    return 'Tebengan';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return const Color(0xFF7B68EE); // Purple for Proses
      case 'full':
        return const Color(0xFFFF9800); // Orange for Kosong/Full
      case 'completed':
        return const Color(0xFF66BB6A); // Green
      case 'cancelled':
        return const Color(0xFFEF5350); // Red
      default:
        return const Color(0xFF757575); // Gray
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'active':
        return 'akan datang';
      case 'full':
        return 'Kosong';
      case 'completed':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredActivities = getFilteredActivities();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
leading: IconButton(
  icon: const Icon(Icons.arrow_back, color: Color(0xFF212121)),
  onPressed: () {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacementNamed(context, '/home');
    }
  },
),

        title: const Text(
          'Tebengan Akan Datang',
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
                _buildTabButton('Akan Datang', 1),
                const SizedBox(width: 12),
                _buildTabButton('selesai', 2),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Activity List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                errorMessage!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _loadUpcomingRides,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Coba Lagi'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E3A8A),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      )
                    : filteredActivities.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.event_busy,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Tidak ada tebengan',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadUpcomingRides,
                            child: ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: filteredActivities.length,
                              itemBuilder: (context, index) {
                                final ride = filteredActivities[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: InkWell(
                                    onTap: () {
                                      // TODO: Navigate to detail page with ride data
                                    },
                                    child: _buildActivityCard(ride),
                                  ),
                                );
                              },
                            ),
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

  Widget _buildActivityCard(Map<String, dynamic> ride) {
    final origin = ride['origin'] as Map<String, dynamic>?;
    final destination = ride['destination'] as Map<String, dynamic>?;
    final vehicle = ride['vehicle'] as Map<String, dynamic>?;
    final driver = ride['driver'] as Map<String, dynamic>?;

    final status = ride['status'] as String? ?? 'active';
    final statusLabel = _getStatusLabel(status);
    final statusColor = _getStatusColor(status);

    final rideType = ride['ride_type'] as String? ?? 'motor';
    final serviceType = ride['service_type'] as String? ?? 'tebengan';
    final rideTypeLabel = _getRideTypeLabel(rideType, serviceType);

    final date = ride['date'] as String? ?? '';
    final time = ride['time'] as String? ?? '';
    final formattedDateTime = _formatDateTime(date, time);

    final price = ride['price'] as num? ?? 0;
    final formattedPrice = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(price);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with date and status
          Container(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$formattedDateTime | $rideTypeLabel',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF757575),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Divider
          Divider(
            height: 1,
            color: Colors.grey[200],
          ),
          // Locations
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Origin
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1E3A8A),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            origin?['name'] ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF212121),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            origin?['detail'] ?? '',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF757575),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Destination
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF5350),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            destination?['name'] ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF212121),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            destination?['detail'] ?? '',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF757575),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Divider
          Divider(
            height: 1,
            color: Colors.grey[200],
          ),
          // Driver Info
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF1E3A8A),
                  backgroundImage: driver?['photo'] != null
                      ? NetworkImage(driver!['photo'])
                      : null,
                  child: driver?['photo'] == null
                      ? Text(
                          (driver?['name'] ?? 'U')[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driver?['name'] ?? 'Unknown Driver',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF212121),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${vehicle?['brand'] ?? ''} ${vehicle?['type'] ?? ''} - ${vehicle?['plate'] ?? ''}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF757575),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Divider
          Divider(
            height: 1,
            color: Colors.grey[200],
          ),
          // Price
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Estimasi Pendapatan',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF424242),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  formattedPrice,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E3A8A),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
