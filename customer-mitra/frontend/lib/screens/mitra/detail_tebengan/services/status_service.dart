import 'package:shared_preferences/shared_preferences.dart';
import '../../mitra_tracking_map/services/tracking_service.dart';
import '../../mitra_tracking_map/utils/persistence_helper.dart';

class StatusService {
  final TrackingService _trackingService;

  StatusService(this._trackingService);

  Future<void> markMenujuPenjemputan({
    required int? bookingId,
    required Function(String) onStatusUpdate,
    required Function() onStartTracking,
    required Function() onFetchRouteToOrigin,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('api_token');
    if (token == null || bookingId == null) return;

    await _trackingService.updateBookingStatus(
      bookingId: bookingId,
      status: 'menuju_penjemputan',
      token: token,
    );

    onStatusUpdate('menuju_penjemputan');
    await onFetchRouteToOrigin();
    await onStartTracking();
    await PersistenceHelper.savePersistentTracking(bookingId, true);
  }

  Future<void> markSudahDiPenjemputan({
    required int? bookingId,
    required Function(String) onStatusUpdate,
    required Function() onStartPickupTimer,
    required Function() onClearRouteToOrigin,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('api_token');
    if (token == null || bookingId == null) return;

    await _trackingService.updateBookingStatus(
      bookingId: bookingId,
      status: 'sudah_di_penjemputan',
      token: token,
    );

    onStatusUpdate('sudah_di_penjemputan');
    onClearRouteToOrigin();
    await PersistenceHelper.savePickupArrival(
      bookingId,
      DateTime.now().millisecondsSinceEpoch,
    );
    onStartPickupTimer();
  }

  Future<void> markMenujuTujuan({
    required int? bookingId,
    required Function(String) onStatusUpdate,
    required Function() onStartTracking,
    required Function() onFetchRouteToDestination,
    required Function() onCancelPickupTimer,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('api_token');
    if (token == null || bookingId == null) return;

    await _trackingService.updateBookingStatus(
      bookingId: bookingId,
      status: 'menuju_tujuan',
      token: token,
    );

    onStatusUpdate('menuju_tujuan');
    await onStartTracking();
    await onFetchRouteToDestination();
    await PersistenceHelper.savePersistentTracking(bookingId, false);
    await PersistenceHelper.saveEnRouteToDestination(bookingId, true);
    await PersistenceHelper.clearPickupArrival(bookingId);
    onCancelPickupTimer();
  }

  Future<void> markSudahSampaiTujuan({
    required int? bookingId,
    required Function(String) onStatusUpdate,
    required Function() onClearRouteToDestination,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('api_token');
    if (token == null || bookingId == null) return;

    await _trackingService.updateBookingStatus(
      bookingId: bookingId,
      status: 'sudah_sampai_tujuan',
      token: token,
    );

    onStatusUpdate('sudah_sampai_tujuan');
    onClearRouteToDestination();
    await PersistenceHelper.clearPersistentTracking(bookingId);
    await PersistenceHelper.saveEnRouteToDestination(bookingId, false);
  }

  Future<void> cancelPickup({
    required int? bookingId,
    required Function(String) onStatusUpdate,
    required Function() onCancelPickupTimer,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('api_token');
    if (token == null || bookingId == null) return;

    await _trackingService.updateBookingStatus(
      bookingId: bookingId,
      status: 'cancelled',
      token: token,
    );

    onCancelPickupTimer();
    await PersistenceHelper.clearPersistentTracking(bookingId);
    await PersistenceHelper.clearPickupArrival(bookingId);
    onStatusUpdate('cancelled');
  }

  static String getCurrentStatus(Map<String, dynamic> item) {
    final ride = Map<String, dynamic>.from(item['ride'] ?? {});
    final rideStatus = ride['status'];
    final topLevelStatus = item['status'];
    return (rideStatus ?? topLevelStatus ?? '').toString().toLowerCase();
  }

  static bool isFinalStatus(String status) {
    return status == 'completed' ||
        status == 'selesai' ||
        status == 'sudah_sampai_tujuan' ||
        status == 'cancelled' ||
        status == 'dibatalkan';
  }
}
