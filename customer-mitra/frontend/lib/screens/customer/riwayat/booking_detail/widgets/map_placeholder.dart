import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Custom painter for map-like pattern placeholder
class MapPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Draw grid lines
    const gridSize = 30.0;
    for (double i = 0; i < size.width; i += gridSize) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i, size.height),
        paint,
      );
    }
    for (double i = 0; i < size.height; i += gridSize) {
      canvas.drawLine(
        Offset(0, i),
        Offset(size.width, i),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Widget to display map placeholder for in_progress status
class MapPlaceholder extends StatefulWidget {
  final String statusText;
  final double? lat;
  final double? lng;
  final double? height;
  final double? originLat; // NEW: For route drawing
  final double? originLng; // NEW: For route drawing
  final double? destinationLat; // NEW: For route drawing
  final double? destinationLng; // NEW: For route drawing

  const MapPlaceholder({
    Key? key,
    this.statusText = 'Driver dalam perjalanan',
    this.lat,
    this.lng,
    this.height,
    this.originLat,
    this.originLng,
    this.destinationLat,
    this.destinationLng,
  }) : super(key: key);

  @override
  State<MapPlaceholder> createState() => _MapPlaceholderState();
}

class _MapPlaceholderState extends State<MapPlaceholder> {
  List<LatLng>? _routePoints;

  @override
  void initState() {
    super.initState();
    _fetchRoute();
  }

  @override
  void didUpdateWidget(MapPlaceholder oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-fetch route if coordinates changed
    if (oldWidget.originLat != widget.originLat ||
        oldWidget.originLng != widget.originLng ||
        oldWidget.destinationLat != widget.destinationLat ||
        oldWidget.destinationLng != widget.destinationLng) {
      _fetchRoute();
    }
  }

  /// Fetch route from OSRM API
  Future<void> _fetchRoute() async {
    if (widget.originLat == null ||
        widget.originLng == null ||
        widget.destinationLat == null ||
        widget.destinationLng == null) {
      return;
    }

    try {
      // OSRM API format: lng,lat (note: longitude first!)
      final url =
          'https://router.project-osrm.org/route/v1/driving/${widget.originLng},${widget.originLat};${widget.destinationLng},${widget.destinationLat}?overview=full&geometries=geojson';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 'Ok' &&
            data['routes'] != null &&
            data['routes'].isNotEmpty) {
          final coordinates =
              data['routes'][0]['geometry']['coordinates'] as List;

          final routePoints = coordinates.map((coord) {
            // OSRM returns [lng, lat]
            return LatLng(coord[1] as double, coord[0] as double);
          }).toList();

          setState(() {
            _routePoints = routePoints;
          });
        } else {
          _useFallbackRoute();
        }
      } else {
        _useFallbackRoute();
      }
    } catch (e) {
      _useFallbackRoute();
    }
  }

  /// Use simple straight line as fallback
  void _useFallbackRoute() {
    if (widget.originLat != null &&
        widget.originLng != null &&
        widget.destinationLat != null &&
        widget.destinationLng != null) {
      setState(() {
        _routePoints = _generateSimpleRoute(
          LatLng(widget.originLat!, widget.originLng!),
          LatLng(widget.destinationLat!, widget.destinationLng!),
        );
      });
    }
  }

  /// Generate simple interpolated route (fallback)
  List<LatLng> _generateSimpleRoute(LatLng origin, LatLng destination) {
    final List<LatLng> points = [];
    points.add(origin);

    const int segments = 10;
    for (int i = 1; i < segments; i++) {
      final t = i / segments;
      final lat =
          origin.latitude + (destination.latitude - origin.latitude) * t;
      final lng =
          origin.longitude + (destination.longitude - origin.longitude) * t;
      points.add(LatLng(lat, lng));
    }

    points.add(destination);
    return points;
  }

  @override
  Widget build(BuildContext context) {
    // If coordinates are available, show OSM map via flutter_map
    if (widget.lat != null && widget.lng != null) {
      final center = LatLng(widget.lat!, widget.lng!);

      // Build list of markers
      final markers = <Marker>[
        Marker(
          point: center,
          width: 48,
          height: 48,
          child: const Icon(
            Icons.directions_car,
            color: Colors.blue,
            size: 36,
          ),
        ),
      ];

      // Add origin marker if provided
      if (widget.originLat != null && widget.originLng != null) {
        markers.add(
          Marker(
            point: LatLng(widget.originLat!, widget.originLng!),
            width: 48,
            height: 48,
            child: const Icon(
              Icons.trip_origin,
              color: Colors.green,
              size: 36,
            ),
          ),
        );
      }

      // Add destination marker if provided
      if (widget.destinationLat != null && widget.destinationLng != null) {
        markers.add(
          Marker(
            point: LatLng(widget.destinationLat!, widget.destinationLng!),
            width: 48,
            height: 48,
            child: const Icon(
              Icons.location_on,
              color: Colors.red,
              size: 36,
            ),
          ),
        );
      }

      // Build polyline for route using fetched route points
      final polylines = <Polyline>[];
      if (_routePoints != null && _routePoints!.isNotEmpty) {
        polylines.add(
          Polyline(
            points: _routePoints!,
            strokeWidth: 4.0,
            color: const Color(0xFF2563EB), // Blue color
          ),
        );
      }

      // Calculate map bounds to fit all markers and route
      LatLngBounds? bounds;
      if (widget.originLat != null &&
          widget.originLng != null &&
          widget.destinationLat != null &&
          widget.destinationLng != null) {
        final points = [
          LatLng(widget.lat!, widget.lng!),
          LatLng(widget.originLat!, widget.originLng!),
          LatLng(widget.destinationLat!, widget.destinationLng!),
        ];
        bounds = LatLngBounds.fromPoints(points);
      }

      final map = FlutterMap(
        options: MapOptions(
          initialCenter: center,
          initialZoom: bounds != null ? 12.0 : 15.0,
          initialCameraFit: bounds != null
              ? CameraFit.bounds(
                  bounds: bounds,
                  padding: const EdgeInsets.all(50),
                )
              : null,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.nebeng',
          ),
          PolylineLayer(
            polylines: polylines,
          ),
          MarkerLayer(
            markers: markers,
          ),
        ],
      );

      if (widget.height != null) {
        return SizedBox(
            width: double.infinity, height: widget.height, child: map);
      }
      return SizedBox(width: double.infinity, child: map);
    }

    // Fallback placeholder
    return Container(
      height: widget.height ?? 200,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.blue[100]!,
            Colors.blue[200]!,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Map placeholder pattern
          Positioned.fill(
            child: CustomPaint(
              painter: MapPatternPainter(),
            ),
          ),
          // Driver marker
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.local_shipping,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.statusText,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
