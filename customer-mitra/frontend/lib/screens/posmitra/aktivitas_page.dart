import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/posmitra/posmitra_service.dart';
import 'aktivitas/detail_tebengan_page.dart';

class AktivitasPage extends StatefulWidget {
  const AktivitasPage({Key? key}) : super(key: key);

  @override
  State<AktivitasPage> createState() => _AktivitasPageState();
}

class _AktivitasPageState extends State<AktivitasPage> {
  int selectedTab = 0; // 0: Semua, 1: Akan Datang, 2: Selesai
  List<Map<String, dynamic>> allRides = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAllRides();
  }

  Future<void> _loadAllRides() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final rides = await PosMitraService.getAllRides();
      
      debugPrint('=== LOAD RIDES DEBUG ===');
      debugPrint('Total rides loaded: ${rides.length}');
      
      final activeCount = rides.where((r) => r['status'] == 'active').length;
      final completedCount = rides.where((r) => r['status'] == 'completed').length;
      final fullCount = rides.where((r) => r['status'] == 'full').length;
      
      debugPrint('Active: $activeCount');
      debugPrint('Completed: $completedCount');
      debugPrint('Full: $fullCount');
      debugPrint('=========================');
      
      setState(() {
        allRides = rides;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading rides: $e');
      
      try {
        final rides = await PosMitraService.getUpcomingRides();
        setState(() {
          allRides = rides;
          isLoading = false;
        });
      } catch (e2) {
        setState(() {
          errorMessage = e2.toString().replaceAll('Exception: ', '');
          isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> getFilteredActivities() {
    if (selectedTab == 0) {
      return allRides;
    } else if (selectedTab == 1) {
      return allRides.where((ride) => 
        ride['status'] == 'active' || ride['status'] == 'full'
      ).toList();
    } else if (selectedTab == 2) {
      return allRides.where((ride) => ride['status'] == 'completed').toList();
    }
    return allRides;
  }

  String _formatDateTime(String date, String time) {
    try {
      if (date.isEmpty || time.isEmpty) return 'Waktu tidak tersedia';
      
      final cleanDate = date.split(' ')[0];
      final cleanTime = time.split('.')[0];

      final dateTime = DateTime.parse('$cleanDate $cleanTime');
      final dayName = DateFormat('EEE', 'id_ID').format(dateTime);
      final formattedDate = DateFormat('dd MMMM yyyy', 'id_ID').format(dateTime);
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
        return const Color(0xFF7B68EE);
      case 'full':
        return const Color(0xFFFF9800);
      case 'completed':
        return const Color(0xFF66BB6A);
      case 'cancelled':
        return const Color(0xFFEF5350);
      default:
        return const Color(0xFF757575);
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'active':
        return 'Akan Datang';
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

  /// Konversi data ride dari API ke format activity untuk DetailTebenganPage
  Map<String, dynamic> _rideToActivity(Map<String, dynamic> ride) {
    final origin = ride['origin'] is Map
        ? Map<String, dynamic>.from(ride['origin'])
        : {'name': 'Tidak tersedia', 'detail': ''};
    final destination = ride['destination'] is Map
        ? Map<String, dynamic>.from(ride['destination'])
        : {'name': 'Tidak tersedia', 'detail': ''};
    final vehicle = ride['vehicle'] is Map
        ? Map<String, dynamic>.from(ride['vehicle'])
        : {'brand': '', 'type': '', 'plate': '', 'color': ''};
    final driver = ride['driver'] is Map
        ? Map<String, dynamic>.from(ride['driver'])
        : {'name': 'Unknown Driver'};

    final status = ride['status']?.toString() ?? 'active';
    final statusLabel = _getStatusLabel(status);
    final statusColor = _getStatusColor(status);

    final date = ride['date']?.toString() ?? '';
    final time = ride['time']?.toString() ?? '';
    final formattedDateTime = _formatDateTime(date, time);

    final rideType = ride['ride_type']?.toString() ?? 'motor';
    final serviceType = ride['service_type']?.toString() ?? 'tebengan';
    final rideTypeLabel = _getRideTypeLabel(rideType, serviceType);

    final price = ride['price'] ?? 0;
    final formattedPrice = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(price);

    final passengers = (ride['passengers'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e is Map ? e : {}))
        .toList();

    return {
      'id': ride['id'],
      'date': formattedDateTime,
      'status': statusLabel,
      'statusColor': statusColor,
      'slot': rideTypeLabel,
      'locations': [
        {'name': origin['name'] ?? 'Tidak tersedia', 'detail': origin['detail'] ?? '', 'isPrimary': true},
        {'name': destination['name'] ?? 'Tidak tersedia', 'detail': destination['detail'] ?? '', 'isPrimary': false},
      ],
      'price': formattedPrice,
      'driverName': driver['name'] ?? 'Unknown Driver',
      'vehicleType': vehicle['type'] ?? rideType,
      'plateNumber': vehicle['plate'] ?? '-',
      'vehicleModel': '${vehicle['brand'] ?? ''} ${vehicle['type'] ?? ''}'.trim().isEmpty ? rideTypeLabel : '${vehicle['brand'] ?? ''} ${vehicle['type'] ?? ''}'.trim(),
      'vehicleColor': vehicle['color'] ?? '-',
      'seats': ride['available_seats'] ?? ride['seats'] ?? '-',
      'passengers': passengers,
    };
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
          'Aktivitas Tebengan',
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
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildTabButton('Semua', 0),
                const SizedBox(width: 12),
                _buildTabButton('Akan Datang', 1),
                const SizedBox(width: 12),
                _buildTabButton('Selesai', 2),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage != null
                    ? _buildErrorState()
                    : filteredActivities.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: _loadAllRides,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: filteredActivities.length,
                              itemBuilder: (context, index) {
                                final ride = filteredActivities[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: InkWell(
                                    onTap: () {
                                      final activity = _rideToActivity(ride);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => DetailTebenganPage(activity: activity),
                                        ),
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(12),
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

  Widget _buildErrorState() {
    return Center(
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
            padding: const EdgeInsets.symmetric(horizontal: 32),
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
            onPressed: _loadAllRides,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    String message = 'Tidak ada tebengan';
    if (selectedTab == 1) {
      message = 'Tidak ada tebengan akan datang';
    } else if (selectedTab == 2) {
      message = 'Belum ada tebengan selesai';
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            selectedTab == 2 ? Icons.check_circle_outline : Icons.event_busy,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> ride) {
    final origin = ride['origin'] is Map 
        ? Map<String, dynamic>.from(ride['origin']) 
        : {'name': 'Tidak tersedia', 'detail': ''};
    
    final destination = ride['destination'] is Map
        ? Map<String, dynamic>.from(ride['destination'])
        : {'name': 'Tidak tersedia', 'detail': ''};
    
    final vehicle = ride['vehicle'] is Map
        ? Map<String, dynamic>.from(ride['vehicle'])
        : {'brand': '', 'type': '', 'plate': ''};
    
    final driver = ride['driver'] is Map
        ? Map<String, dynamic>.from(ride['driver'])
        : {'name': 'Unknown Driver', 'photo': null};

    final status = ride['status']?.toString() ?? 'active';
    final statusLabel = _getStatusLabel(status);
    final statusColor = _getStatusColor(status);

    final rideType = ride['ride_type']?.toString() ?? 'motor';
    final serviceType = ride['service_type']?.toString() ?? 'tebengan';
    final rideTypeLabel = _getRideTypeLabel(rideType, serviceType);

    final date = ride['date']?.toString() ?? '';
    final time = ride['time']?.toString() ?? '';
    final formattedDateTime = _formatDateTime(date, time);

    final price = ride['price'] ?? 0;
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
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formattedDateTime,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF757575),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        rideTypeLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF424242),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
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
          ),
          
          Divider(height: 1, color: Colors.grey[200]),
          
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                _buildLocationRow(
                  title: origin['name'] ?? 'Tidak tersedia',
                  subtitle: origin['detail'] ?? '',
                  color: const Color(0xFF1E3A8A),
                ),
                const SizedBox(height: 12),
                _buildLocationRow(
                  title: destination['name'] ?? 'Tidak tersedia',
                  subtitle: destination['detail'] ?? '',
                  color: const Color(0xFFEF5350),
                ),
              ],
            ),
          ),
          
          Divider(height: 1, color: Colors.grey[200]),
          
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF1E3A8A),
                  backgroundImage: driver['photo'] != null
                      ? NetworkImage(driver['photo'])
                      : null,
                  child: driver['photo'] == null
                      ? Text(
                          (driver['name']?.isNotEmpty ?? false)
                              ? driver['name'][0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
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
                        driver['name'] ?? 'Unknown Driver',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF212121),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${vehicle['brand']} ${vehicle['type']} - ${vehicle['plate']}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF757575),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          Divider(height: 1, color: Colors.grey[200]),
          
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

  Widget _buildLocationRow({
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 6),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF212121),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF757575),
                  fontWeight: FontWeight.w400,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}