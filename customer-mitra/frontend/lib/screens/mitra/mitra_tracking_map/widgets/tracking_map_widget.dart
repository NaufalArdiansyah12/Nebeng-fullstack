import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Map widget for tracking page
class TrackingMapWidget extends StatelessWidget {
  final MapController mapController;
  final Position? lastPosition;
  final LatLng? originLatLng;
  final LatLng? destinationLatLng;
  final List<LatLng> routePoints;
  final List<LatLng> routeToOrigin;
  final List<LatLng> mainRoute;
  final List<LatLng> routeToDestination;
  final String currentStatus;

  const TrackingMapWidget({
    Key? key,
    required this.mapController,
    required this.lastPosition,
    required this.originLatLng,
    required this.destinationLatLng,
    required this.routePoints,
    required this.routeToOrigin,
    required this.mainRoute,
    required this.routeToDestination,
    required this.currentStatus,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: lastPosition != null
            ? LatLng(lastPosition!.latitude, lastPosition!.longitude)
            : originLatLng ?? const LatLng(-7.797068, 110.370529),
        initialZoom: 15.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.nebeng',
        ),
        _buildRouteToOriginLine(),
        _buildRouteToDestinationLine(),
        _buildMarkers(),
      ],
    );
  }

  Widget _buildRouteToOriginLine() {
    // Only show route to origin when status is menuju_penjemputan
    if (routeToOrigin.isEmpty || currentStatus != 'menuju_penjemputan') {
      return const SizedBox.shrink();
    }

    return PolylineLayer(
      polylines: [
        Polyline(
          points: routeToOrigin,
          strokeWidth: 5.0,
          color: Colors.blueAccent,
          borderStrokeWidth: 2.0,
          borderColor: Colors.white,
        ),
      ],
    );
  }

  Widget _buildRouteToDestinationLine() {
    // Only show route to destination when status is menuju_tujuan
    if (routeToDestination.isEmpty || currentStatus != 'menuju_tujuan') {
      return const SizedBox.shrink();
    }

    return PolylineLayer(
      polylines: [
        Polyline(
          points: routeToDestination,
          strokeWidth: 5.0,
          color: Colors.blueAccent,
          borderStrokeWidth: 2.0,
          borderColor: Colors.white,
        ),
      ],
    );
  }

  Widget _buildMarkers() {
    return MarkerLayer(
      markers: [
        if (originLatLng != null) _buildOriginMarker(),
        if (destinationLatLng != null) _buildDestinationMarker(),
        if (lastPosition != null) _buildCurrentPositionMarker(),
      ],
    );
  }

  Marker _buildOriginMarker() {
    return Marker(
      point: originLatLng!,
      width: 40,
      height: 40,
      child: const Icon(
        Icons.location_on,
        color: Colors.green,
        size: 36,
      ),
    );
  }

  Marker _buildDestinationMarker() {
    return Marker(
      point: destinationLatLng!,
      width: 40,
      height: 40,
      child: const Icon(
        Icons.flag,
        color: Colors.red,
        size: 36,
      ),
    );
  }

  Marker _buildCurrentPositionMarker() {
    return Marker(
      point: LatLng(lastPosition!.latitude, lastPosition!.longitude),
      width: 50,
      height: 50,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.blue, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.navigation,
            color: Colors.blue,
            size: 24,
          ),
        ),
      ),
    );
  }
}
