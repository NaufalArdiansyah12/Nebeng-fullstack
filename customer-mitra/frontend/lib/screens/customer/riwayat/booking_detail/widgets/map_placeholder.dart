import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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
class MapPlaceholder extends StatelessWidget {
  final String statusText;
  final double? lat;
  final double? lng;
  final double? height;

  const MapPlaceholder({
    Key? key,
    this.statusText = 'Driver dalam perjalanan',
    this.lat,
    this.lng,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // If coordinates are available, show OSM map via flutter_map
    if (lat != null && lng != null) {
      final center = LatLng(lat!, lng!);
      final map = FlutterMap(
        options: MapOptions(
          initialCenter: center,
          initialZoom: 15.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.nebeng',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: center,
                width: 48,
                height: 48,
                child: const Icon(
                  Icons.location_on,
                  color: Colors.red,
                  size: 36,
                ),
              ),
            ],
          ),
        ],
      );

      if (height != null) {
        return SizedBox(width: double.infinity, height: height, child: map);
      }
      return SizedBox(width: double.infinity, child: map);
    }

    // Fallback placeholder
    return Container(
      height: height ?? 200,
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
                        statusText,
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
