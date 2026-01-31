import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../../../services/chat_service.dart';

/// Model class to hold all tracking state variables
class TrackingState {
  // Controllers & Services
  final MapController mapController = MapController();
  final ChatService chatService = ChatService();

  // Timers
  Timer? locationTimer;
  Timer? countdownTimer;
  Timer? pickupTimer;

  // Location & Tracking State
  Position? lastPosition;
  bool isTracking = false;
  bool isMoving = false;

  // Persistent tracking & pickup state
  bool menujuActive = false; // true after pressing "menuju titik jemput"
  bool isAtPickup = false; // true when arrived at pickup
  bool pickedUp = false; // true after passenger picked up
  bool showGoToPrompt =
      false; // show button to go to destination after pressing Lanjutkan
  bool enRouteToDestination =
      false; // true after pressing "menuju titik tujuan"
  bool isLoadingState = true; // true while loading booking status
  Duration pickupWait = const Duration(minutes: 15);
  Duration pickupRemaining = const Duration(minutes: 15);
  bool canCancelPickup = false;

  // Countdown state
  Duration? timeUntilDeparture;
  bool isDepartureReady = false;

  // Route Data
  final List<LatLng> routePoints = [];
  List<LatLng> routeToOrigin = [];
  List<LatLng> mainRoute = [];
  List<LatLng> routeToDestination = [];
  bool avoidTolls = false; // Toggle for avoiding toll roads

  // Location Data
  LatLng? originLatLng;
  LatLng? destinationLatLng;

  // Booking Info
  String bookingType = 'motor';

  // Dispose resources
  void dispose() {
    locationTimer?.cancel();
    countdownTimer?.cancel();
    pickupTimer?.cancel();
    mapController.dispose();
  }
}
