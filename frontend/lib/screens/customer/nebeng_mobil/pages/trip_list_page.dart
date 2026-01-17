import 'package:flutter/material.dart';
import '../../../../services/api_service.dart';
import '../models/trip_model.dart';
import '../widgets/trip_card.dart';
import 'booking_detail_page.dart';

class TripListPage extends StatefulWidget {
  final String lokasiAwal;
  final String lokasiTujuan;
  final DateTime tanggalKeberangkatan;
  final int? originLocationId;
  final int? destinationLocationId;

  const TripListPage({
    Key? key,
    required this.lokasiAwal,
    required this.lokasiTujuan,
    required this.tanggalKeberangkatan,
    this.originLocationId,
    this.destinationLocationId,
  }) : super(key: key);

  @override
  State<TripListPage> createState() => _TripListPageState();
}

class _TripListPageState extends State<TripListPage> {
  List<TripModel> trips = [];
  bool isReversed = false;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  void _loadTrips() {
    setState(() {
      isLoading = true;
      error = null;
    });

    final originId =
        isReversed ? widget.destinationLocationId : widget.originLocationId;
    final destId =
        isReversed ? widget.originLocationId : widget.destinationLocationId;
    final dateStr = widget.tanggalKeberangkatan.toIso8601String().split('T')[0];

    print('🚗 Fetching mobil rides with params:');
    print('  originId: $originId');
    print('  destId: $destId');
    print('  date: $dateStr');
    print('  rideType: mobil');

    ApiService.fetchRides(
      originLocationId: originId,
      destinationLocationId: destId,
      date: dateStr,
      rideType: 'mobil',
    ).then((rows) {
      print('✅ Received ${rows.length} mobil rides from API');
      if (rows.isNotEmpty) {
        print('First ride sample: ${rows[0]}');
      }
      final list = rows.map((r) => TripModel.fromApi(r)).toList();
      print('📋 Parsed ${list.length} TripModels');
      setState(() {
        trips = list;
        isLoading = false;
      });
    }).catchError((e) {
      print('❌ Error fetching mobil rides: $e');
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    });
  }

  void _toggleDirection() {
    setState(() {
      isReversed = !isReversed;
      _loadTrips();
    });
  }

  String _getFromCity() {
    final location = isReversed ? widget.lokasiTujuan : widget.lokasiAwal;
    return location.split(' - ')[0];
  }

  String _getToCity() {
    final location = isReversed ? widget.lokasiAwal : widget.lokasiTujuan;
    return location.split(' - ')[0];
  }

  String _getFormattedDate() {
    final days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu'
    ];
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des'
    ];

    final date = widget.tanggalKeberangkatan;
    final dayName = days[date.weekday - 1];
    final monthName = months[date.month - 1];

    return '$dayName, ${date.day} $monthName ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : (error != null
                    ? Center(child: Text('Error: $error'))
                    : (trips.isEmpty ? _buildEmptyState() : _buildTripList())),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.arrow_back_ios_new,
              color: Colors.black, size: 18),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Pilih Perjalanan',
        style: TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Route Display
          Row(
            children: [
              // From City
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getFromCity(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Keberangkatan',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              // Swap Button
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.swap_horiz_rounded,
                    color: Color(0xFF3B82F6),
                  ),
                  onPressed: _toggleDirection,
                  tooltip: 'Tukar arah',
                ),
              ),

              // To City
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _getToCity(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.end,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tujuan',
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

          // Date and Trip Count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 14,
                  color: Colors.grey[700],
                ),
                const SizedBox(width: 8),
                Text(
                  _getFormattedDate(),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (trips.isNotEmpty) ...[
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    width: 1,
                    height: 16,
                    color: Colors.grey[400],
                  ),
                  Text(
                    '${trips.length} perjalanan tersedia',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: trips.length,
      itemBuilder: (context, index) {
        final trip = trips[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TripCard(
            trip: trip,
            onTap: () => _handleTripSelection(trip),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.directions_bus_rounded,
                size: 64,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Tidak ada perjalanan tersedia',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Coba pilih tanggal lain atau tukar arah perjalanan',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _toggleDirection,
              icon: const Icon(Icons.swap_horiz_rounded),
              label: const Text('Tukar Arah'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF3B82F6),
                side: const BorderSide(color: Color(0xFF3B82F6)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleTripSelection(TripModel trip) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingDetailPage(trip: trip),
      ),
    ).then((_) {
      // After returning from booking flow, refresh the trip list
      _loadTrips();
    });
  }
}
