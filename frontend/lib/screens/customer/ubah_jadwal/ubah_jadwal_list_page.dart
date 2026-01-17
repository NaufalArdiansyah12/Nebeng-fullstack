import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import 'ubah_jadwal_detail_page.dart';

class UbahJadwalListPage extends StatefulWidget {
  final Map<String, dynamic> booking;
  final List<Map<String, dynamic>> availableRides;
  final DateTime selectedDate;

  const UbahJadwalListPage({
    Key? key,
    required this.booking,
    required this.availableRides,
    required this.selectedDate,
  }) : super(key: key);

  @override
  State<UbahJadwalListPage> createState() => _UbahJadwalListPageState();
}

class _UbahJadwalListPageState extends State<UbahJadwalListPage> {
  DateTime selectedDate = DateTime.now();
  List<Map<String, dynamic>> currentAvailableRides = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    selectedDate = widget.selectedDate;
    currentAvailableRides = widget.availableRides;
  }

  List<DateTime> _generateDateList() {
    List<DateTime> dates = [];
    DateTime startDate = DateTime.now();
    for (int i = 0; i < 7; i++) {
      dates.add(startDate.add(Duration(days: i)));
    }
    return dates;
  }

  String _getDayName(DateTime date) {
    List<String> days = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
    return days[date.weekday % 7];
  }

  Future<void> _fetchAvailableRides(DateTime date) async {
    setState(() {
      isLoading = true;
    });

    try {
      final bookingId = widget.booking['id'];
      final bookingType =
          (widget.booking['booking_type'] ?? 'mobil').toString();

      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      final available = await ApiService.fetchAvailableRides(
        bookingId,
        bookingType,
        date: dateStr,
      );

      setState(() {
        currentAvailableRides = available;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ride = widget.booking['ride'] ?? {};
    String origin = 'Yogyakarta';
    String destination = 'Purwokerto';

    if (ride['origin_location'] is Map && ride['origin_location'] != null) {
      origin = ride['origin_location']['name'] ?? 'Yogyakarta';
      if (origin.contains(' - ')) {
        origin = origin.split(' - ')[0];
      }
    }
    if (ride['destination_location'] is Map &&
        ride['destination_location'] != null) {
      destination = ride['destination_location']['name'] ?? 'Purwokerto';
      if (destination.contains(' - ')) {
        destination = destination.split(' - ')[0];
      }
    }

    final dateList = _generateDateList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton(
            icon: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.black87,
                size: 18,
              ),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              origin,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Colors.black87,
            ),
            const SizedBox(width: 8),
            Text(
              destination,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E3A8A),
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Date Selector
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: dateList.length,
                itemBuilder: (context, index) {
                  final date = dateList[index];
                  final isSelected = date.day == selectedDate.day &&
                      date.month == selectedDate.month &&
                      date.year == selectedDate.year;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedDate = date;
                      });
                      _fetchAvailableRides(date);
                    },
                    child: Container(
                      width: 55,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color:
                            isSelected ? const Color(0xFF1E3A8A) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF1E3A8A)
                              : Colors.grey[300]!,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${_getDayName(date)}, ${index + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // Ride List
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF1E3A8A)),
                    ),
                  )
                : currentAvailableRides.isEmpty
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
                              'Tidak ada jadwal tersedia',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: currentAvailableRides.length,
                        itemBuilder: (context, index) {
                          final rideData = currentAvailableRides[index];
                          return _RideCard(
                            ride: rideData,
                            booking: widget.booking,
                            selectedDate: selectedDate,
                            onRefresh: () => _fetchAvailableRides(selectedDate),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _RideCard extends StatelessWidget {
  final Map<String, dynamic> ride;
  final Map<String, dynamic> booking;
  final DateTime selectedDate;
  final VoidCallback onRefresh;

  const _RideCard({
    required this.ride,
    required this.booking,
    required this.selectedDate,
    required this.onRefresh,
  });

  String _formatTime(String? time) {
    if (time == null || time.isEmpty) return '00:00';
    try {
      // Handle HH:MM:SS format
      final parts = time.split(':');
      if (parts.length >= 2) {
        return '${parts[0]}:${parts[1]}';
      }
      return time;
    } catch (e) {
      return time;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Debug: Print ride data to see what we're receiving
    print('Ride data: $ride');
    print('Price value: ${ride['price']} (type: ${ride['price'].runtimeType})');

    // Check if this is the current trip
    final currentRideId = booking['ride_id'] ??
        booking['barang_ride_id'] ??
        booking['titip_barang_id'];
    final thisRideId = ride['id'] ?? ride['ride_id'];
    final isCurrentTrip = currentRideId != null &&
        thisRideId != null &&
        currentRideId == thisRideId;

    // Extract data from ride
    final departureTime = _formatTime(ride['departure_time']);
    final arrivalTime = _formatTime(ride['arrival_time']);

    // Parse price - handle both int, double, and string
    int price = 50000;
    if (ride['price'] != null) {
      if (ride['price'] is int) {
        price = ride['price'];
      } else if (ride['price'] is double) {
        price = (ride['price'] as double).toInt();
      } else if (ride['price'] is String) {
        price = int.tryParse(ride['price']) ?? 50000;
      }
    }
    print('Parsed price: $price');

    final availableSeats = ride['available_seats'] ?? 2;

    String origin = 'Yogyakarta';
    String destination = 'Purwokerto';
    String originAddress =
        'Pos 1, Kecamatan Kraton, Kota Yogyakarta Daerah Istimewa Yogyakarta 55133';
    String destinationAddress =
        'Jl Prof. Dr. Suharso No.8, Mangunjaya, Purwokerto Lor Kec. Purwokerto Tim. Kabupaten Banyumas, Jawa Tengah 53112';

    if (ride['origin_location'] is Map && ride['origin_location'] != null) {
      origin = ride['origin_location']['name'] ?? origin;
      originAddress = ride['origin_location']['address'] ?? originAddress;
    }
    if (ride['destination_location'] is Map &&
        ride['destination_location'] != null) {
      destination = ride['destination_location']['name'] ?? destination;
      destinationAddress =
          ride['destination_location']['address'] ?? destinationAddress;
    }

    final dateStr =
        '${selectedDate.day.toString().padLeft(2, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date and Price Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    dateStr,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  if (isCurrentTrip) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: const Color(0xFF10B981),
                          width: 1,
                        ),
                      ),
                      child: const Text(
                        'Trip Saat Ini',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Text(
                'Rp. ${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Origin
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.circle,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...List.generate(
                    3,
                    (index) => Container(
                      margin: const EdgeInsets.only(bottom: 3),
                      width: 2,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(1),
                      ),
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
                      origin,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      originAddress,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Destination
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Color(0xFFF97316),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.circle,
                  color: Colors.white,
                  size: 12,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      destination,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      destinationAddress,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Divider
          Container(
            height: 1,
            color: Colors.grey[200],
          ),
          const SizedBox(height: 12),
          // Time and Seats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$departureTime-$arrivalTime',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              Row(
                children: [
                  const Icon(
                    Icons.person,
                    size: 16,
                    color: Colors.black87,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Sisa $availableSeats Kursi',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: isCurrentTrip
                  ? null
                  : () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UbahJadwalDetailPage(
                            booking: booking,
                            selectedRide: ride,
                            selectedDate: selectedDate,
                          ),
                        ),
                      );

                      // Refresh data when coming back
                      if (result == true || result == null) {
                        onRefresh();
                      }
                    },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(
                  color: isCurrentTrip
                      ? Colors.grey[300]!
                      : const Color(0xFF1E3A8A),
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                isCurrentTrip ? 'Trip Saat Ini' : 'Selengkapnya',
                style: TextStyle(
                  color: isCurrentTrip
                      ? Colors.grey[400]
                      : const Color(0xFF1E3A8A),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
