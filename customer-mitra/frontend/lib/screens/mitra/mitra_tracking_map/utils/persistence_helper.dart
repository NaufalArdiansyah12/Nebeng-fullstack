import 'package:shared_preferences/shared_preferences.dart';

/// Helper class for persisting tracking state
class PersistenceHelper {
  /// Save tracking active state
  static Future<void> savePersistentTracking(int bookingId, bool active) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('mitra_tracking_active_$bookingId', active);
    } catch (e) {
      // Ignore errors
    }
  }

  /// Save last position
  static Future<void> saveLastPosition(
      int bookingId, double lat, double lng) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('mitra_last_lat_$bookingId', lat);
      await prefs.setDouble('mitra_last_lng_$bookingId', lng);
    } catch (e) {
      // Ignore errors
    }
  }

  /// Save pickup arrival time
  static Future<void> savePickupArrival(int bookingId, int millis) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('mitra_pickup_arrival_$bookingId', millis);
    } catch (e) {
      // Ignore errors
    }
  }

  /// Clear pickup arrival
  static Future<void> clearPickupArrival(int bookingId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('mitra_pickup_arrival_$bookingId');
    } catch (e) {
      // Ignore errors
    }
  }

  /// Save en route to destination state
  static Future<void> saveEnRouteToDestination(
      int bookingId, bool active) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('mitra_en_route_destination_$bookingId', active);
    } catch (e) {
      // Ignore errors
    }
  }

  /// Clear all persistent tracking data
  static Future<void> clearPersistentTracking(int bookingId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('mitra_tracking_active_$bookingId');
      await prefs.remove('mitra_last_lat_$bookingId');
      await prefs.remove('mitra_last_lng_$bookingId');
      await prefs.remove('mitra_en_route_destination_$bookingId');
    } catch (e) {
      // Ignore errors
    }
  }

  /// Load persisted state
  static Future<Map<String, dynamic>> loadPersistedState(int bookingId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final active = prefs.getBool('mitra_tracking_active_$bookingId') ?? false;
      final enRouteToDestination =
          prefs.getBool('mitra_en_route_destination_$bookingId') ?? false;
      final lat = prefs.getDouble('mitra_last_lat_$bookingId');
      final lng = prefs.getDouble('mitra_last_lng_$bookingId');
      final arrivalMillis = prefs.getInt('mitra_pickup_arrival_$bookingId');

      return {
        'active': active,
        'enRouteToDestination': enRouteToDestination,
        'lat': lat,
        'lng': lng,
        'arrivalMillis': arrivalMillis,
      };
    } catch (e) {
      return {};
    }
  }
}
