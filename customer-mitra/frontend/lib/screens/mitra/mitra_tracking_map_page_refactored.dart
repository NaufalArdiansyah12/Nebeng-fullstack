import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../../utils/chat_helper.dart';
import 'messages/chat_detail_page.dart';
import 'main_page.dart';
import 'mitra_tracking_map/models/tracking_state.dart';
import 'mitra_tracking_map/services/tracking_service.dart';
import 'mitra_tracking_map/utils/tracking_helpers.dart';
import 'mitra_tracking_map/utils/persistence_helper.dart';
import 'mitra_tracking_map/widgets/tracking_map_widget.dart';
import 'mitra_tracking_map/widgets/qr_only_screen.dart';
import 'mitra_tracking_map/widgets/customer_rating_screen.dart';
import 'mitra_tracking_map/widgets/info_card_widgets.dart';
import 'mitra_tracking_map/widgets/overlay_widgets.dart';

class MitraTrackingMapPage extends StatefulWidget {
  final Map<String, dynamic> item;

  const MitraTrackingMapPage({Key? key, required this.item}) : super(key: key);

  @override
  State<MitraTrackingMapPage> createState() => _MitraTrackingMapPageState();
}

class _MitraTrackingMapPageState extends State<MitraTrackingMapPage> {
  late TrackingState _state;
  late TrackingService _trackingService;
  Timer? _statusRefreshTimer;

  @override
  void initState() {
    super.initState();
    _state = TrackingState();
    _trackingService = TrackingService();
    _initializeTracking();
    _startStatusRefreshTimer();
  }

  Future<void> _initializeTracking() async {
    _state.bookingType = BookingTypeHelper.detectBookingType(widget.item);
    _state.avoidTolls = _state.bookingType == 'motor';

    final locations = LocationHelper.extractOriginDestination(widget.item);
    _state.originLatLng = locations['origin'];
    _state.destinationLatLng = locations['destination'];

    await _fetchMainRoute();
    _startCountdownTimer();
    await _loadPersistentState();

    // Force check current status from database to ensure UI is in sync
    // This is called after loadPersistentState to ensure status is fresh
    await _refreshStatusFromServer();
  }

  // Add method to refresh status from server
  Future<void> _refreshStatusFromServer() async {
    try {
      // Check current status first - if final, stop refreshing
      final currentStatus = _getCurrentStatus();
      if (_isFinalStatus(currentStatus)) {
        print(
            'DEBUG: Status is final ($currentStatus), stopping refresh timer');
        _statusRefreshTimer?.cancel();
        return;
      }

      final bookingId = await _resolveBookingId();
      if (bookingId == null) {
        print(
            'DEBUG: Could not resolve booking ID, checking ride status from item');
        // If booking ID not found, check ride status from the passed item
        final ride = widget.item['ride'] ?? {};
        if (ride['status'] != null) {
          final rideStatus = ride['status'].toString().toLowerCase();
          print('DEBUG: Using ride status from item: $rideStatus');

          // Only update if status actually changed
          if (rideStatus != currentStatus) {
            if (mounted) {
              setState(() {
                widget.item['ride']['status'] = rideStatus;
              });
            }
            // If new status is final, stop timer
            if (_isFinalStatus(rideStatus)) {
              _statusRefreshTimer?.cancel();
            }
          }
        }
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');
      if (token == null) return;

      try {
        final booking = await _trackingService.fetchBooking(
          bookingId: bookingId,
          token: token,
        );
        final status = (booking['status'] ?? '').toString().toLowerCase();
        print('DEBUG: Status refreshed from server: $status');

        // Only update if status actually changed
        if (status != currentStatus && mounted) {
          setState(() {
            if (widget.item['ride'] is Map) {
              widget.item['ride']['status'] = status;
            }
          });
          // If new status is final, stop timer
          if (_isFinalStatus(status)) {
            _statusRefreshTimer?.cancel();
          }
        }
      } catch (e) {
        // If 404, booking might be completed/archived, check ride status
        if (e.toString().contains('404')) {
          print(
              'DEBUG: Booking not found (404), trying alternative status resolution');
          final ride = widget.item['ride'] ?? {};
          // Try to get status from ride
          if (ride['status'] != null) {
            final rideStatus = ride['status'].toString().toLowerCase();
            print('DEBUG: Using ride status: $rideStatus');
            // Only update if status changed
            if (rideStatus != currentStatus && mounted) {
              setState(() {
                widget.item['ride']['status'] = rideStatus;
              });
              // If final status, stop timer
              if (_isFinalStatus(rideStatus)) {
                _statusRefreshTimer?.cancel();
              }
            }
          } else {
            // If no status available, check booking status history
            print('DEBUG: Checking booking status from booking table');
            // Try to fetch from booking_motor table directly
            final motorBooking = await _trackingService
                .getMotorBooking(widget.item['ride']?['id']);
            if (motorBooking != null && motorBooking['status'] != null) {
              final bookingStatus =
                  motorBooking['status'].toString().toLowerCase();
              print('DEBUG: Found status from motor booking: $bookingStatus');
              // Only update if status changed
              if (bookingStatus != currentStatus && mounted) {
                setState(() {
                  if (widget.item['ride'] is Map) {
                    widget.item['ride']['status'] = bookingStatus;
                  }
                });
                // If final status, stop timer
                if (_isFinalStatus(bookingStatus)) {
                  _statusRefreshTimer?.cancel();
                }
              }
            }
          }
        } else {
          print('Error refreshing status from API: $e');
        }
      }
    } catch (e) {
      print('Error in _refreshStatusFromServer: $e');
    }
  }

  // Start periodic status refresh timer
  void _startStatusRefreshTimer() {
    // Refresh status every 5 seconds to detect status changes
    _statusRefreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _refreshStatusFromServer();
    });
  }

  @override
  void dispose() {
    _statusRefreshTimer?.cancel();
    _state.dispose();
    super.dispose();
  }

  String _getCurrentStatus() {
    final ride = widget.item['ride'] ?? {};
    // Also check top-level status as fallback
    final rideStatus = ride['status'];
    final topLevelStatus = widget.item['status'];
    final status =
        (rideStatus ?? topLevelStatus ?? '').toString().toLowerCase();
    print(
        'DEBUG: Current status - ride: $rideStatus, topLevel: $topLevelStatus, final: $status');
    return status;
  }

  // Check if status is final (no more updates needed)
  bool _isFinalStatus(String status) {
    return status == 'completed' ||
        status == 'selesai' ||
        status == 'sudah_sampai_tujuan' ||
        status == 'cancelled' ||
        status == 'dibatalkan';
  }

  // ==================== COUNTDOWN TIMER ====================

  void _startCountdownTimer() {
    final ride = widget.item['ride'] ?? {};
    final departureDate = ride['departure_date'];
    final departureTime = ride['departure_time'];

    if (departureDate == null || departureTime == null) {
      setState(() {
        _state.isDepartureReady = true;
      });
      return;
    }

    try {
      DateTime departureDateTime;
      String dateStr = departureDate.toString();
      String timeStr = departureTime.toString();

      if (dateStr.contains('T')) {
        DateTime dateOnly = DateTime.parse(dateStr);
        final timeParts = timeStr.split(':');
        if (timeParts.length >= 2) {
          departureDateTime = DateTime(
            dateOnly.year,
            dateOnly.month,
            dateOnly.day,
            int.parse(timeParts[0]),
            int.parse(timeParts[1]),
            timeParts.length >= 3 ? int.parse(timeParts[2].split('.')[0]) : 0,
          );
        } else {
          throw FormatException('Invalid time format');
        }
      } else if (dateStr.contains(' ')) {
        departureDateTime = DateTime.parse(dateStr);
      } else {
        final dateParts = dateStr.split('-');
        final timeParts = timeStr.split(':');
        if (dateParts.length >= 3 && timeParts.length >= 2) {
          departureDateTime = DateTime(
            int.parse(dateParts[0]),
            int.parse(dateParts[1]),
            int.parse(dateParts[2]),
            int.parse(timeParts[0]),
            int.parse(timeParts[1]),
            timeParts.length >= 3 ? int.parse(timeParts[2].split('.')[0]) : 0,
          );
        } else {
          throw FormatException('Invalid date/time parts');
        }
      }

      final initialDifference = departureDateTime.difference(DateTime.now());

      if (initialDifference.isNegative || initialDifference.inSeconds <= 0) {
        setState(() {
          _state.timeUntilDeparture = Duration.zero;
          _state.isDepartureReady = true;
        });
        return;
      } else {
        setState(() {
          _state.timeUntilDeparture = initialDifference;
          _state.isDepartureReady = false;
        });
      }

      _state.countdownTimer =
          Timer.periodic(const Duration(seconds: 1), (timer) {
        final now = DateTime.now();
        final difference = departureDateTime.difference(now);

        if (difference.isNegative || difference.inSeconds <= 0) {
          setState(() {
            _state.timeUntilDeparture = Duration.zero;
            _state.isDepartureReady = true;
          });
          timer.cancel();
        } else {
          setState(() {
            _state.timeUntilDeparture = difference;
            _state.isDepartureReady = false;
          });
        }
      });
    } catch (e) {
      setState(() {
        _state.isDepartureReady = true;
        _state.timeUntilDeparture = null;
      });
    }
  }

  // ==================== ROUTE FETCHING ====================

  Future<void> _fetchMainRoute() async {
    if (_state.originLatLng == null || _state.destinationLatLng == null) return;

    final points = await _trackingService.fetchRoute(
      _state.originLatLng!,
      _state.destinationLatLng!,
    );

    if (mounted) {
      setState(() {
        _state.mainRoute = points;
      });
    }
  }

  Future<void> _fetchRouteToOrigin() async {
    if (_state.lastPosition == null) return;

    if (_state.originLatLng == null) {
      final bookingId = await _resolveBookingId();
      if (bookingId != null) {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('api_token');
        if (token != null) {
          try {
            final booking = await _trackingService.fetchBooking(
              bookingId: bookingId,
              token: token,
            );
            final ride = booking['ride'] ?? booking;
            final origin = ride['origin_location'] ?? ride['origin'];
            final parsed = LocationHelper.parseLatLng(origin);
            if (parsed != null) {
              _state.originLatLng = parsed;
              if (_state.destinationLatLng != null) {
                _fetchMainRoute();
              }
            }
          } catch (e) {
            // Ignore
          }
        }
      }
    }

    if (_state.originLatLng == null) return;

    final currentPos = LatLng(
      _state.lastPosition!.latitude,
      _state.lastPosition!.longitude,
    );

    final points = await _trackingService.fetchRoute(
      currentPos,
      _state.originLatLng!,
    );

    if (mounted) {
      setState(() {
        _state.routeToOrigin = points;
      });
    }
  }

  Future<void> _fetchRouteToDestination() async {
    if (_state.lastPosition == null || _state.destinationLatLng == null) return;

    final currentPos = LatLng(
      _state.lastPosition!.latitude,
      _state.lastPosition!.longitude,
    );

    final points = await _trackingService.fetchRoute(
      currentPos,
      _state.destinationLatLng!,
    );

    if (mounted) {
      setState(() {
        _state.routeToDestination = points;
        _state.routeToOrigin = [];
      });
    }
  }

  // ==================== LOCATION TRACKING ====================

  Future<void> _startLocationTracking() async {
    if (!await _trackingService.checkLocationPermissions()) return;

    setState(() => _state.isTracking = true);

    final bookingId = await _resolveBookingId();
    if (bookingId != null) {
      await PersistenceHelper.savePersistentTracking(bookingId, true);
    }

    _sendLocationUpdate();
    _startPeriodicUpdate();
  }

  void _startPeriodicUpdate() {
    _state.locationTimer?.cancel();
    final interval = _state.isMoving
        ? const Duration(seconds: 5)
        : const Duration(minutes: 1);
    _state.locationTimer = Timer.periodic(
      interval,
      (_) => _sendLocationUpdate(),
    );
  }

  Future<void> _sendLocationUpdate() async {
    try {
      final position = await _trackingService.getCurrentPosition();
      if (position == null) return;

      // Detect movement
      if (_state.lastPosition != null) {
        final distance = Geolocator.distanceBetween(
          _state.lastPosition!.latitude,
          _state.lastPosition!.longitude,
          position.latitude,
          position.longitude,
        );
        final wasMoving = _state.isMoving;
        _state.isMoving = distance >= 0.2;

        if (wasMoving != _state.isMoving) {
          _startPeriodicUpdate();
        }
      }

      final newPoint = LatLng(position.latitude, position.longitude);
      _state.routePoints.add(newPoint);
      _state.mapController.move(newPoint, 15.0);
      _state.lastPosition = position;

      final bookingId = await _resolveBookingId();
      if (bookingId != null) {
        await PersistenceHelper.saveLastPosition(
          bookingId,
          position.latitude,
          position.longitude,
        );
      }

      // Auto-detect arrival
      final status = _getCurrentStatus();
      if (status == 'menuju_penjemputan' && _state.originLatLng != null) {
        final distanceToOrigin = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          _state.originLatLng!.latitude,
          _state.originLatLng!.longitude,
        );
        if (distanceToOrigin <= 50.0) {
          await _markSudahDiPenjemputan();
        }
      }

      if (status == 'menuju_tujuan' && _state.destinationLatLng != null) {
        final distanceToDestination = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          _state.destinationLatLng!.latitude,
          _state.destinationLatLng!.longitude,
        );
        if (distanceToDestination <= 50.0) {
          await _markSudahSampaiTujuan();
        }
      }

      if (mounted) setState(() {});

      // Refresh route
      if (status == 'menuju_penjemputan') {
        _fetchRouteToOrigin();
      } else if (status == 'menuju_tujuan') {
        _fetchRouteToDestination();
      }

      // Update location to server
      if (bookingId != null) {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('api_token');
        if (token != null) {
          await _trackingService.updateBookingLocation(
            bookingId: bookingId,
            token: token,
            lat: position.latitude,
            lng: position.longitude,
            timestamp: DateTime.now(),
            accuracy: position.accuracy,
            speed: position.speed,
            bookingType: _state.bookingType,
          );
        }
      }
    } catch (e) {
      // Ignore
    }
  }

  // ==================== PERSISTENCE ====================

  Future<void> _loadPersistentState() async {
    try {
      final bookingId = await _resolveBookingId();
      if (bookingId == null) {
        setState(() => _state.isLoadingState = false);
        return;
      }

      final persisted = await PersistenceHelper.loadPersistedState(bookingId);

      if (persisted['lat'] != null && persisted['lng'] != null) {
        _state.lastPosition = Position(
          longitude: persisted['lng'],
          latitude: persisted['lat'],
          timestamp: DateTime.now(),
          accuracy: 0.0,
          altitude: 0.0,
          altitudeAccuracy: 0.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        );
      }

      // Fetch current status from API
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');
      if (token != null) {
        try {
          final booking = await _trackingService.fetchBooking(
            bookingId: bookingId,
            token: token,
          );
          final status = (booking['status'] ?? '').toString().toLowerCase();
          print(
              'DEBUG: Status fetched from API in _loadPersistentState: $status');

          if (mounted) {
            setState(() {
              if (widget.item['ride'] is Map) {
                widget.item['ride']['status'] = status;
              }
            });
          }

          if (status == 'menuju_penjemputan') {
            await _startLocationTracking();
            await _fetchRouteToOrigin();
          } else if (status == 'sudah_di_penjemputan') {
            // Restore waiting timer
            final arrivalMillis = persisted['arrivalMillis'];
            if (arrivalMillis != null) {
              _restorePickupTimer(arrivalMillis);
            }
          } else if (status == 'menuju_tujuan') {
            await _startLocationTracking();
            await _fetchRouteToDestination();
          } else if (status == 'sudah_sampai_tujuan' || status == 'completed') {
            // Clear persistent tracking for completed rides
            await PersistenceHelper.clearPersistentTracking(bookingId);
            // Status already updated above, build() will show QR screen
          }
        } catch (e) {
          // Handle 404 or other errors
          print('DEBUG: Error fetching booking in _loadPersistentState: $e');

          if (e.toString().contains('404')) {
            print(
                'DEBUG: Booking not found, trying alternative status resolution');
            // Try to get status from motor booking table
            final rideId = widget.item['ride']?['id'];
            if (rideId != null) {
              final motorBooking =
                  await _trackingService.getMotorBooking(rideId);
              if (motorBooking != null && motorBooking['status'] != null) {
                final bookingStatus =
                    motorBooking['status'].toString().toLowerCase();
                print(
                    'DEBUG: Found status from motor booking table: $bookingStatus');
                if (mounted) {
                  setState(() {
                    if (widget.item['ride'] is Map) {
                      widget.item['ride']['status'] = bookingStatus;
                    }
                  });
                }

                // Handle status actions
                if (bookingStatus == 'sudah_sampai_tujuan' ||
                    bookingStatus == 'completed') {
                  await PersistenceHelper.clearPersistentTracking(bookingId);
                }
              }
            }
          } else {
            // Fallback to persisted flags for other errors
            if (persisted['active'] == true) {
              await _startLocationTracking();
              await _fetchRouteToOrigin();
            } else if (persisted['enRouteToDestination'] == true) {
              await _startLocationTracking();
              await _fetchRouteToDestination();
            }
          }
        }
      }

      if (mounted) {
        setState(() => _state.isLoadingState = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _state.isLoadingState = false);
      }
    }
  }

  void _restorePickupTimer(int arrivalMillis) {
    final arrivedAt = DateTime.fromMillisecondsSinceEpoch(arrivalMillis);
    final elapsed = DateTime.now().difference(arrivedAt);
    final remaining = _state.pickupWait - elapsed;

    if (remaining <= Duration.zero) {
      setState(() {
        _state.isAtPickup = true;
        _state.pickupRemaining = Duration.zero;
        _state.canCancelPickup = true;
      });
    } else {
      setState(() {
        _state.isAtPickup = true;
        _state.pickupRemaining = remaining;
        _state.canCancelPickup = false;
      });
      _startPickupTimerWithRemaining(remaining);
    }
  }

  void _startPickupTimerWithRemaining(Duration remaining) {
    _state.pickupTimer?.cancel();
    setState(() {
      _state.pickupRemaining = remaining;
      _state.canCancelPickup = remaining <= Duration.zero;
    });
    if (remaining <= Duration.zero) return;

    _state.pickupTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        final newSec = _state.pickupRemaining.inSeconds - 1;
        if (newSec <= 0) {
          _state.pickupRemaining = Duration.zero;
          _state.canCancelPickup = true;
          _state.pickupTimer?.cancel();
        } else {
          _state.pickupRemaining = Duration(seconds: newSec);
        }
      });
    });
  }

  // ==================== BOOKING ID RESOLUTION ====================

  Future<int?> _resolveBookingId() async {
    return await _trackingService.resolveBookingId(
      widget.item,
      _state.bookingType,
    );
  }

  // Get booking details including customer_id
  Future<Map<String, dynamic>> _getBookingDetails() async {
    final bookingId = await _resolveBookingId();
    if (bookingId == null) {
      throw Exception('Booking ID tidak ditemukan');
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('api_token');
    if (token == null) {
      throw Exception('Token tidak ditemukan');
    }

    try {
      // Try to fetch from bookings API
      final booking = await _trackingService.fetchBooking(
        bookingId: bookingId,
        token: token,
      );

      // Extract customer_id (user_id is customer_id in booking)
      final customerId = booking['user_id'] as int? ?? 0;
      if (customerId == 0) {
        throw Exception('Customer ID tidak ditemukan di booking');
      }

      return {
        'booking_id': bookingId,
        'customer_id': customerId,
      };
    } catch (e) {
      // If 404, try to get from motor booking
      print('DEBUG: Failed to fetch booking, trying motor booking: $e');
      final motorBooking =
          await _trackingService.getMotorBooking(widget.item['ride']?['id']);
      if (motorBooking != null) {
        final customerId = motorBooking['user_id'] as int? ?? 0;
        if (customerId == 0) {
          throw Exception('Customer ID tidak ditemukan');
        }
        return {
          'booking_id': bookingId,
          'customer_id': customerId,
        };
      }
      throw Exception('Tidak dapat menemukan data booking');
    }
  }

  // ==================== STATUS UPDATES ====================

  Future<void> _markMenujuPenjemputan() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');
      if (token == null) return;

      final bookingId = await _resolveBookingId();
      if (bookingId == null) return;

      await _trackingService.updateBookingStatus(
        bookingId: bookingId,
        status: 'menuju_penjemputan',
        token: token,
      );

      setState(() {
        if (widget.item['ride'] is Map) {
          widget.item['ride']['status'] = 'menuju_penjemputan';
        }
      });

      await _fetchRouteToOrigin();

      if (_state.lastPosition != null && _state.originLatLng != null) {
        final cur = LatLng(
            _state.lastPosition!.latitude, _state.lastPosition!.longitude);
        _state.mapController.move(cur, 14.0);
      } else if (_state.originLatLng != null) {
        _state.mapController.move(_state.originLatLng!, 14.0);
      }

      await _startLocationTracking();
      await PersistenceHelper.savePersistentTracking(bookingId, true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status diupdate: Menuju titik jemput')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal update status: $e')),
        );
      }
    }
  }

  Future<void> _markSudahDiPenjemputan() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');
      if (token == null) return;

      final bookingId = await _resolveBookingId();
      if (bookingId == null) return;

      await _trackingService.updateBookingStatus(
        bookingId: bookingId,
        status: 'sudah_di_penjemputan',
        token: token,
      );

      setState(() {
        if (widget.item['ride'] is Map) {
          widget.item['ride']['status'] = 'sudah_di_penjemputan';
        }
        _state.routeToOrigin = [];
      });

      await PersistenceHelper.savePickupArrival(
        bookingId,
        DateTime.now().millisecondsSinceEpoch,
      );
      _startPickupTimerWithRemaining(const Duration(minutes: 15));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sudah di titik penjemputan')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal update status: $e')),
        );
      }
    }
  }

  Future<void> _markMenujuTujuan() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');
      if (token == null) return;

      final bookingId = await _resolveBookingId();
      if (bookingId == null) return;

      await _trackingService.updateBookingStatus(
        bookingId: bookingId,
        status: 'menuju_tujuan',
        token: token,
      );

      setState(() {
        if (widget.item['ride'] is Map) {
          widget.item['ride']['status'] = 'menuju_tujuan';
        }
      });

      await _startLocationTracking();
      await _fetchRouteToDestination();

      if (_state.lastPosition != null && _state.destinationLatLng != null) {
        final cur = LatLng(
            _state.lastPosition!.latitude, _state.lastPosition!.longitude);
        _state.mapController.move(cur, 14.0);
      } else if (_state.destinationLatLng != null) {
        _state.mapController.move(_state.destinationLatLng!, 14.0);
      }

      await PersistenceHelper.savePersistentTracking(bookingId, false);
      await PersistenceHelper.saveEnRouteToDestination(bookingId, true);
      await PersistenceHelper.clearPickupArrival(bookingId);
      _state.pickupTimer?.cancel();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Menuju titik tujuan')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal update status: $e')),
        );
      }
    }
  }

  Future<void> _markSudahSampaiTujuan() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');
      if (token == null) return;

      final bookingId = await _resolveBookingId();
      if (bookingId == null) return;

      await _trackingService.updateBookingStatus(
        bookingId: bookingId,
        status: 'sudah_sampai_tujuan',
        token: token,
      );

      setState(() {
        if (widget.item['ride'] is Map) {
          widget.item['ride']['status'] = 'sudah_sampai_tujuan';
        }
        _state.routeToDestination = [];
      });

      await PersistenceHelper.clearPersistentTracking(bookingId);
      await PersistenceHelper.saveEnRouteToDestination(bookingId, false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Tebengan selesai! Sudah sampai tujuan')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal update status: $e')),
        );
      }
    }
  }

  Future<void> _cancelPickup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');
      if (token == null) return;

      final bookingId = await _resolveBookingId();
      if (bookingId == null) return;

      await _trackingService.updateBookingStatus(
        bookingId: bookingId,
        status: 'cancelled',
        token: token,
      );

      _state.pickupTimer?.cancel();
      await PersistenceHelper.clearPersistentTracking(bookingId);
      await PersistenceHelper.clearPickupArrival(bookingId);

      setState(() {
        if (widget.item['ride'] is Map) {
          widget.item['ride']['status'] = 'cancelled';
        }
      });

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membatalkan tebengan: $e')),
        );
      }
    }
  }

  // ==================== CHAT ====================

  Future<void> _openChatWithCustomer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mitraId = prefs.getInt('user_id');
      final mitraName =
          prefs.getString('user_name') ?? prefs.getString('name') ?? 'Mitra';

      if (mitraId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User ID tidak ditemukan')),
        );
        return;
      }

      final ride = widget.item['ride'] ?? {};
      final rideId = ride['id'] as int?;
      final customerId = widget.item['user_id'] as int?;

      if (rideId == null || customerId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data booking tidak lengkap')),
        );
        return;
      }

      final existingConv =
          await _state.chatService.getConversationByRideAndUsers(
        rideId: rideId,
        customerId: customerId,
        mitraId: mitraId,
      );

      String conversationId;
      if (existingConv != null) {
        conversationId = existingConv['id'] as String;
      } else {
        final customerName = widget.item['user_name'] as String? ?? 'Customer';
        final customerPhoto = widget.item['user_photo'] as String?;

        final newConvId = await ChatHelper.createConversationAfterBooking(
          rideId: rideId,
          bookingType: _state.bookingType,
          customerData: {
            'id': customerId,
            'name': customerName,
            'photo': customerPhoto,
          },
          mitraData: {
            'id': mitraId,
            'name': mitraName,
            'photo': null,
          },
        );

        if (newConvId == null) {
          throw Exception('Failed to create conversation');
        }

        conversationId = newConvId;
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MitraChatDetailPage(
              conversationId: conversationId,
              otherUserName: widget.item['user_name'] as String? ?? 'Customer',
              otherUserPhoto: widget.item['user_photo'] as String?,
              bookingType: _state.bookingType,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuka chat: $e')),
        );
      }
    }
  }

  // ==================== BUILD UI ====================

  @override
  Widget build(BuildContext context) {
    final status = _getCurrentStatus();
    print('DEBUG: Building UI with status: $status');

    // Show rating screen when completed/selesai
    if (status == 'completed' || status == 'selesai') {
      print('DEBUG: Showing rating screen');
      return FutureBuilder<Map<String, dynamic>>(
        future: _getBookingDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error: ${snapshot.error ?? "Data tidak ditemukan"}'),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Kembali'),
                    ),
                  ],
                ),
              ),
            );
          }

          final bookingData = snapshot.data!;
          final bookingId = bookingData['booking_id'] as int;
          final customerId = bookingData['customer_id'] as int;

          return CustomerRatingScreen(
            bookingNumber: BookingInfoHelper.getBookingNumber(widget.item),
            customerName: BookingInfoHelper.getCustomerName(widget.item),
            totalFare: BookingInfoHelper.getTotalFare(widget.item),
            bookingId: bookingId,
            customerId: customerId,
          );
        },
      );
    }

    // Show QR only screen when sudah_sampai_tujuan
    if (status == 'sudah_sampai_tujuan') {
      print('DEBUG: Showing QR only screen');
      return QROnlyScreen(
        qrCodeData: BookingInfoHelper.getQRCodeData(widget.item),
        bookingNumber: BookingInfoHelper.getBookingNumber(widget.item),
      );
    }

    final originInfo = BookingInfoHelper.getOriginInfo(widget.item);
    final customerName = BookingInfoHelper.getCustomerName(widget.item);
    final bookingNumber = BookingInfoHelper.getBookingNumber(widget.item);

    return Scaffold(
      body: Stack(
        children: [
          TrackingMapWidget(
            mapController: _state.mapController,
            lastPosition: _state.lastPosition,
            originLatLng: _state.originLatLng,
            destinationLatLng: _state.destinationLatLng,
            routePoints: _state.routePoints,
            routeToOrigin: _state.routeToOrigin,
            mainRoute: _state.mainRoute,
            routeToDestination: _state.routeToDestination,
            currentStatus: status,
          ),
          TopMessageButton(onPressed: _openChatWithCustomer),
          BackButtonOverlay(onPressed: () => Navigator.pop(context)),
          if (_state.bookingType == 'mobil')
            TollToggleButton(
              avoidTolls: _state.avoidTolls,
              onToggle: () {
                setState(() => _state.avoidTolls = !_state.avoidTolls);
                if (status == 'menuju_penjemputan') {
                  _fetchRouteToOrigin();
                } else if (status == 'menuju_tujuan') {
                  _fetchRouteToDestination();
                }
              },
            ),
          if (_state.timeUntilDeparture != null)
            CountdownTimerOverlay(
              timeUntilDeparture: _state.timeUntilDeparture,
              isDepartureReady: _state.isDepartureReady,
              formatCountdown: FormatHelper.formatCountdown,
            ),
          BottomInfoCard(
            bookingNumber: bookingNumber,
            customerName: customerName,
            originName: originInfo['name']!,
            originAddress: originInfo['address']!,
            onCallPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Fitur telepon akan segera tersedia')),
              );
            },
            onMessagePressed: _openChatWithCustomer,
            statusUI: _buildStatusUI(status),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusUI(String status) {
    if (_state.isLoadingState) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              const CircularProgressIndicator(color: Color(0xFF1E3A8A)),
              const SizedBox(height: 12),
              Text(
                'Memuat status tebengan...',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    if (status == 'menuju_penjemputan') {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Menuju titik penjemputan...',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (status == 'sudah_di_penjemputan') {
      return PickupWaitingCard(
        pickupRemaining: _state.pickupRemaining,
        canCancelPickup: _state.canCancelPickup,
        onContactCustomer: _openChatWithCustomer,
        onContinue: () async {
          _state.pickupTimer?.cancel();
          final bookingId = await _resolveBookingId();
          if (bookingId != null) {
            await PersistenceHelper.clearPickupArrival(bookingId);
          }
          await _markMenujuTujuan();
        },
        onCancel: _cancelPickup,
      );
    }

    if (status == 'menuju_tujuan') {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Menuju titik tujuan...',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ActionButton(
      isDepartureReady: _state.isDepartureReady,
      onPressed: _markMenujuPenjemputan,
    );
  }
}
