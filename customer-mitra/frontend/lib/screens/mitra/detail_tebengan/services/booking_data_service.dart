import '../../../../services/api_service.dart';

class BookingDataService {
  /// Get motor booking data
  static Future<Map<String, dynamic>?> getMotorBooking(dynamic rideId) async {
    try {
      print('🔍 Fetching motor booking for ride ID: $rideId');

      // Gunakan endpoint passengers untuk mendapatkan booking motor
      final passengers = await ApiService.getRidePassengers(rideId, 'motor');

      if (passengers.isNotEmpty) {
        // Untuk motor, biasanya hanya 1 booking
        final booking = passengers.first;
        print('✅ Motor booking found: ${booking['id']}');
        return booking;
      }

      print('❌ No motor booking found for ride ID: $rideId');
      return null;
    } catch (e) {
      print('❌ Error fetching motor booking: $e');
      return null;
    }
  }

  /// Get all mobil bookings with passengers
  static Future<Map<String, dynamic>> getMobilBookingWithPassengers(
      dynamic rideId) async {
    try {
      // Ambil semua booking mobil beserta penumpangnya
      final bookings = await ApiService.getRidePassengers(rideId, 'mobil');

      // Return all bookings untuk dikelompokkan
      return {
        'bookings': bookings,
      };
    } catch (e) {
      return {
        'bookings': [],
      };
    }
  }

  /// Get barang booking data
  static Future<Map<String, dynamic>?> getBarangBooking(dynamic rideId) async {
    try {
      // Ambil booking barang berdasarkan ride_id
      final rideIdInt = int.tryParse(rideId.toString()) ?? 0;
      if (rideIdInt == 0) return null;
      // First try: endpoint for 'barang'
      final bookings = await ApiService.getRidePassengers(rideIdInt, 'barang');
      if (bookings.isNotEmpty) {
        return bookings.first;
      }

      // Fallback: some mobil bookings store barang fields in booking_mobil.
      // Try fetching mobil bookings and inspect for barang fields.
      final mobilBookings =
          await ApiService.getRidePassengers(rideIdInt, 'mobil');
      for (var b in mobilBookings) {
        final photo = b['photo']?.toString() ?? '';
        final weight = b['weight']?.toString() ?? '';
        final description = b['description']?.toString() ?? '';
        if (photo.isNotEmpty || weight.isNotEmpty || description.isNotEmpty) {
          return b;
        }
      }

      return null;
    } catch (e) {
      print('Error fetching barang booking: $e');
      return null;
    }
  }

  /// Get titip barang booking data
  static Future<Map<String, dynamic>?> getTitipBarangBooking(
      dynamic rideId) async {
    try {
      // Ambil booking titip barang berdasarkan ride_id
      final rideIdInt = int.tryParse(rideId.toString()) ?? 0;
      if (rideIdInt == 0) return null;

      final bookings = await ApiService.getRidePassengers(rideIdInt, 'titip');

      if (bookings.isNotEmpty) {
        return bookings.first;
      }
      return null;
    } catch (e) {
      print('Error fetching titip barang booking: $e');
      return null;
    }
  }

  /// Helper to get booking count label
  static String getBookingCountLabel(
      String serviceType, int passengerCount, bool hasBarangData) {
    if (serviceType == 'barang') {
      // Untuk service type barang only
      return hasBarangData ? '1 barang' : '0 barang';
    } else if (serviceType == 'both') {
      // Untuk service type both (penumpang + barang)
      if (passengerCount > 0 && hasBarangData) {
        return '$passengerCount penumpang + barang';
      } else if (passengerCount > 0) {
        return '$passengerCount penumpang';
      } else if (hasBarangData) {
        return '1 barang';
      } else {
        return '0 penumpang';
      }
    } else {
      // Untuk service type passenger only
      return '$passengerCount penumpang';
    }
  }
}
