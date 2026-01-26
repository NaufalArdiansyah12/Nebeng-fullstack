import 'package:flutter/material.dart';
import '../widgets/map_placeholder.dart';
import '../widgets/location_card.dart';
import '../utils/booking_formatters.dart';

/// Layout widget for journey statuses (menuju_penjemputan, menuju_tujuan)
/// Displays different routes based on current status
class InProgressLayout extends StatefulWidget {
  final Map<String, dynamic> booking;
  final Map<String, dynamic>? trackingData;
  final int currentDot;
  final bool isDriverMoving;
  final DateTime? lastLocationUpdate;
  final String currentStatus; // NEW: to determine which route to show

  const InProgressLayout({
    Key? key,
    required this.booking,
    this.trackingData,
    required this.currentDot,
    this.isDriverMoving = false,
    this.lastLocationUpdate,
    required this.currentStatus, // NEW
  }) : super(key: key);

  @override
  State<InProgressLayout> createState() => _InProgressLayoutState();
}

class _InProgressLayoutState extends State<InProgressLayout> {
  @override
  Widget build(BuildContext context) {
    final ride = widget.booking['ride'] ?? {};
    final driver = ride['user'] ?? {};
    final driverName = driver['name'] ?? 'Jamal Driver';
    final driverPhoto = driver['photo_url'] ?? '';
    final kendaraan = ride['kendaraan_mitra'] ?? {};
    final vehicle =
        (kendaraan['brand'] ?? 'Bus') + ' ' + (kendaraan['model'] ?? '');
    final origin = ride['origin_location']?['name'] ?? 'Yogyakarta';
    final originAddress = ride['origin_location']?['address'] ??
        'Patehan, Kecamatan Kraton, Kota Yogyakarta...';
    final destination = ride['destination_location']?['name'] ?? 'Purwokerto';
    final destinationAddress =
        ride['destination_location']?['address'] ?? 'Alun-alun Purwokerto';
    final rawDate = (ride['departure_date'] ?? '').toString();
    final rawTime = (ride['departure_time'] ?? '').toString();
    final arrivalTime = (ride['arrival_time'] ?? '18:45').toString();
    final dateOnly = BookingFormatters.formatDateOnly(rawDate);
    final price = ride['price'] ?? widget.booking['total_price'] ?? 20000;

    // Determine status message based on current status
    String statusMessage;
    String statusTitle;
    if (widget.currentStatus == 'menuju_penjemputan') {
      statusMessage = 'DRIVER MENUJU LOKASI PENJEMPUTAN';
      statusTitle = 'Menuju Penjemputan';
    } else if (widget.currentStatus == 'menuju_tujuan') {
      statusMessage = 'PERJALANAN SEDANG BERLANGSUNG';
      statusTitle = 'Menuju Tujuan';
    } else {
      statusMessage = 'PERJALANAN SEDANG BERLANGSUNG';
      statusTitle = 'Perjalanan';
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          statusTitle,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.black87),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          // Maps Section as background (fill entire available area)
          Positioned.fill(
            child: Builder(builder: (_) {
              // trackingData may contain location.{lat,lng}
              final latNum = widget.trackingData?['location']?['lat'];
              final lngNum = widget.trackingData?['location']?['lng'];
              double? mapLat = latNum is num ? latNum.toDouble() : null;
              double? mapLng = lngNum is num ? lngNum.toDouble() : null;

              // If no tracking coordinates, first try booking-level last known coords,
              // then fall back to ride origin location.
              if (mapLat == null || mapLng == null) {
                final bookingLastLat = widget.booking['last_lat'];
                final bookingLastLng = widget.booking['last_lng'];

                mapLat = mapLat ??
                    (bookingLastLat is num
                        ? bookingLastLat.toDouble()
                        : (bookingLastLat is String
                            ? double.tryParse(bookingLastLat)
                            : null));
                mapLng = mapLng ??
                    (bookingLastLng is num
                        ? bookingLastLng.toDouble()
                        : (bookingLastLng is String
                            ? double.tryParse(bookingLastLng)
                            : null));

                if (mapLat == null || mapLng == null) {
                  final rideOriginLat = ride['origin_location']?['lat'];
                  final rideOriginLng = ride['origin_location']?['lng'];
                  mapLat = mapLat ??
                      (rideOriginLat is num
                          ? rideOriginLat.toDouble()
                          : (rideOriginLat is String
                              ? double.tryParse(rideOriginLat)
                              : null));
                  mapLng = mapLng ??
                      (rideOriginLng is num
                          ? rideOriginLng.toDouble()
                          : (rideOriginLng is String
                              ? double.tryParse(rideOriginLng)
                              : null));
                }
              }

              // Extract origin and destination coordinates for route
              double? originLat;
              double? originLng;
              double? destinationLat;
              double? destinationLng;

              // For menuju_penjemputan: route from driver current location to pickup location
              // For menuju_tujuan: route from pickup location to destination location
              if (widget.currentStatus == 'menuju_penjemputan') {
                // Origin: current driver location (already in mapLat/mapLng)
                originLat = mapLat;
                originLng = mapLng;

                // Destination: pickup location (origin_location)
                final pickupLoc = ride['origin_location'];
                if (pickupLoc != null) {
                  final pickupLat = pickupLoc['lat'] ??
                      pickupLoc['latitude'] ??
                      pickupLoc['pickup_lat'];
                  final pickupLng = pickupLoc['lng'] ??
                      pickupLoc['longitude'] ??
                      pickupLoc['pickup_lng'];
                  destinationLat = pickupLat is num
                      ? pickupLat.toDouble()
                      : (pickupLat is String
                          ? double.tryParse(pickupLat)
                          : null);
                  destinationLng = pickupLng is num
                      ? pickupLng.toDouble()
                      : (pickupLng is String
                          ? double.tryParse(pickupLng)
                          : null);
                }
              } else if (widget.currentStatus == 'menuju_tujuan') {
                // Origin: pickup location (origin_location)
                final pickupLoc = ride['origin_location'];
                if (pickupLoc != null) {
                  final pickupLat = pickupLoc['lat'] ??
                      pickupLoc['latitude'] ??
                      pickupLoc['pickup_lat'];
                  final pickupLng = pickupLoc['lng'] ??
                      pickupLoc['longitude'] ??
                      pickupLoc['pickup_lng'];
                  originLat = pickupLat is num
                      ? pickupLat.toDouble()
                      : (pickupLat is String
                          ? double.tryParse(pickupLat)
                          : null);
                  originLng = pickupLng is num
                      ? pickupLng.toDouble()
                      : (pickupLng is String
                          ? double.tryParse(pickupLng)
                          : null);
                }

                // Destination: destination location
                final destLoc = ride['destination_location'];
                if (destLoc != null) {
                  final destLat = destLoc['lat'] ??
                      destLoc['latitude'] ??
                      destLoc['dest_lat'];
                  final destLng = destLoc['lng'] ??
                      destLoc['longitude'] ??
                      destLoc['dest_lng'];
                  destinationLat = destLat is num
                      ? destLat.toDouble()
                      : (destLat is String ? double.tryParse(destLat) : null);
                  destinationLng = destLng is num
                      ? destLng.toDouble()
                      : (destLng is String ? double.tryParse(destLng) : null);
                }
              }

              return MapPlaceholder(
                statusText: widget.currentStatus == 'menuju_penjemputan'
                    ? 'Driver menuju lokasi penjemputan Anda'
                    : 'Driver dalam perjalanan menuju tujuan',
                lat: mapLat,
                lng: mapLng,
                originLat: originLat,
                originLng: originLng,
                destinationLat: destinationLat,
                destinationLng: destinationLng,
              );
            }),
          ),

          // Draggable sheet with booking details
          DraggableScrollableSheet(
            initialChildSize: 0.55,
            minChildSize: 0.25,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Pull handle
                      Center(
                        child: Container(
                          margin: const EdgeInsets.only(top: 8, bottom: 12),
                          width: 60,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                      // Booking Number
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'No Pesanan :',
                            style:
                                TextStyle(fontSize: 14, color: Colors.black87),
                          ),
                          Text(
                            widget.booking['booking_number'] ??
                                'FR-234567899754',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Animated Dots
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(3, (index) {
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: widget.currentDot == index
                                    ? const Color(0xFF1E3A8A)
                                    : Colors.grey[300],
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Status Text
                      Center(
                        child: Column(
                          children: [
                            Text(
                              statusMessage,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Driver movement status
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: widget.isDriverMoving
                                        ? Colors.green
                                        : Colors.orange,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  widget.isDriverMoving
                                      ? 'Driver Bergerak'
                                      : 'Driver Diam',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: widget.isDriverMoving
                                        ? Colors.green
                                        : Colors.orange,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '• Update: ${widget.isDriverMoving ? "5 detik" : "1 menit"}',
                                  style: const TextStyle(
                                      fontSize: 10, color: Colors.grey),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),
                      // Date and Time
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            dateOnly,
                            style: const TextStyle(fontSize: 14),
                          ),
                          Text(
                            '${rawTime.substring(0, 5)} - $arrivalTime',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Vehicle Info
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    vehicle.isNotEmpty ? vehicle.trim() : 'Bus',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Transportasi Umum',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.directions_bus, size: 40),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Driver Info
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 25,
                              backgroundColor: Colors.grey[300],
                              backgroundImage: driverPhoto.isNotEmpty
                                  ? NetworkImage(driverPhoto)
                                  : null,
                              child: driverPhoto.isEmpty
                                  ? const Icon(Icons.person)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                driverName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E3A8A),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.phone, size: 20),
                                color: Colors.white,
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Fitur panggilan akan segera tersedia'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E3A8A),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.chat_bubble, size: 20),
                                color: Colors.white,
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Fitur chat akan segera tersedia'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Origin Location
                      LocationCard(
                        icon: Icons.circle,
                        iconColor: Colors.grey,
                        title: origin,
                        subtitle: originAddress,
                      ),
                      const SizedBox(height: 12),
                      // Destination Location
                      LocationCard(
                        icon: Icons.circle,
                        iconColor: Colors.red,
                        title: destination,
                        subtitle: destinationAddress,
                      ),
                      const SizedBox(height: 24),
                      // Price
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Biaya',
                            style: TextStyle(fontSize: 14),
                          ),
                          Text(
                            BookingFormatters.formatPrice(price),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
