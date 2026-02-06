import 'package:latlong2/latlong.dart';

/// Helper class for parsing location data
class LocationHelper {
  /// Parse LatLng from various location formats
  static LatLng? parseLatLng(dynamic loc) {
    if (loc == null || loc is! Map) return null;

    final latCandidates = [loc['lat'], loc['latitude']];
    final lngCandidates = [loc['lng'], loc['longitude'], loc['long']];

    double? lat;
    double? lng;

    for (final v in latCandidates) {
      if (v != null) {
        lat = v is num ? v.toDouble() : double.tryParse(v.toString());
        if (lat != null) break;
      }
    }

    for (final v in lngCandidates) {
      if (v != null) {
        lng = v is num ? v.toDouble() : double.tryParse(v.toString());
        if (lng != null) break;
      }
    }

    if (lat != null && lng != null) return LatLng(lat, lng);
    return null;
  }

  /// Extract origin and destination from booking data
  static Map<String, LatLng?> extractOriginDestination(
      Map<String, dynamic> item) {
    final ride = item['ride'] ?? {};
    final origin = ride['origin_location'];
    final destination = ride['destination_location'];

    return {
      'origin': parseLatLng(origin),
      'destination': parseLatLng(destination),
    };
  }
}

/// Helper class for booking type detection
class BookingTypeHelper {
  /// Detect booking type from item data
  static String detectBookingType(Map<String, dynamic> item) {
    final itemType = (item['type'] ?? '').toString().toLowerCase();
    final ride = item['ride'] ?? {};
    final mitraVehicle = ride['kendaraan_mitra'] ?? {};
    final rawType = (mitraVehicle['type'] ??
            mitraVehicle['vehicle_type'] ??
            mitraVehicle['transportation'] ??
            '')
        .toString()
        .toLowerCase();
    final serviceType = (ride['service_type'] ?? '').toString().toLowerCase();
    final rideType = (ride['ride_type'] ?? '').toString().toLowerCase();

    // Priority 1: Check item type (from mitra history)
    if (itemType.contains('titip')) {
      return 'titip';
    } else if (itemType.contains('barang') && !itemType.contains('titip')) {
      return 'barang';
    } else if (itemType.contains('mobil') || itemType.contains('car')) {
      return 'mobil';
    } else if (itemType.contains('motor')) {
      return 'motor';
    }
    // Priority 2: Check service/ride type
    else if (serviceType.contains('titip') || rideType.contains('titip')) {
      return 'titip';
    } else if (serviceType.contains('barang') || rideType.contains('barang')) {
      return 'barang';
    }
    // Priority 3: Check vehicle type
    else if (rawType.contains('mobil') ||
        rawType.contains('car') ||
        serviceType.contains('mobil') ||
        serviceType.contains('car')) {
      return 'mobil';
    } else {
      return 'motor';
    }
  }
}

/// Helper class for formatting
class FormatHelper {
  /// Format countdown duration
  static String formatCountdown(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Format pickup timer
  static String formatPickupTimer(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

/// Helper class for booking info extraction
class BookingInfoHelper {
  /// Get customer name from booking data
  static String getCustomerName(Map<String, dynamic> item) {
    if (item['customer_name'] != null &&
        item['customer_name'].toString().isNotEmpty) {
      return item['customer_name'];
    } else if (item['customer'] != null && item['customer']['name'] != null) {
      return item['customer']['name'];
    } else if (item['user'] != null && item['user']['name'] != null) {
      return item['user']['name'];
    } else if (item['user_name'] != null) {
      return item['user_name'];
    }
    return 'Customer';
  }

  /// Get booking number from booking data
  static String getBookingNumber(Map<String, dynamic> item) {
    final ride = item['ride'] ?? {};

    if (item['booking_number'] != null &&
        item['booking_number'].toString().isNotEmpty) {
      return item['booking_number'].toString();
    } else if (ride['booking_number'] != null &&
        ride['booking_number'].toString().isNotEmpty) {
      return ride['booking_number'].toString();
    } else if (ride['code'] != null && ride['code'].toString().isNotEmpty) {
      return ride['code'].toString();
    }
    return '-';
  }

  /// Get total fare from booking data
  static String getTotalFare(Map<String, dynamic> item) {
    final ride = item['ride'] ?? {};

    if (item['fare'] != null) {
      return 'Rp ${item['fare']}';
    } else if (ride['fare'] != null) {
      return 'Rp ${ride['fare']}';
    } else if (item['price'] != null) {
      return 'Rp ${item['price']}';
    } else if (ride['price'] != null) {
      return 'Rp ${ride['price']}';
    }
    return 'Rp 0';
  }

  /// Get QR code data from booking
  static String? getQRCodeData(Map<String, dynamic> item) {
    final ride = item['ride'] ?? {};

    String? qrCodeData = item['qr_code_data'] as String?;
    qrCodeData ??= ride['qr_code_data'] as String?;
    qrCodeData ??= item['qr_code'] as String?;
    qrCodeData ??= ride['qr_code'] as String?;

    return qrCodeData;
  }

  /// Get origin info
  static Map<String, String> getOriginInfo(Map<String, dynamic> item) {
    final ride = item['ride'] ?? {};
    final origin = ride['origin_location'] ?? {};

    return {
      'name': origin['name'] ?? 'Lokasi Asal',
      'address': origin['address'] ?? '',
    };
  }

  /// Get destination info
  static Map<String, String> getDestinationInfo(Map<String, dynamic> item) {
    final ride = item['ride'] ?? {};
    final destination = ride['destination_location'] ?? {};

    return {
      'name': destination['name'] ?? 'Lokasi Tujuan',
      'address': destination['address'] ?? '',
    };
  }
}
