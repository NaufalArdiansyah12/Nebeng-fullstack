import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';

class DriverTrackingPage extends StatefulWidget {
  final int bookingId;
  const DriverTrackingPage({Key? key, required this.bookingId})
      : super(key: key);

  @override
  State<DriverTrackingPage> createState() => _DriverTrackingPageState();
}

class _DriverTrackingPageState extends State<DriverTrackingPage> {
  Timer? _timer;
  ll.LatLng? _driverPos;
  String _status = '';
  DateTime? _lastUpdated;
  bool _loading = false;

  final MapController _mapController = MapController();

  // Default Jakarta (anti blank)
  final ll.LatLng _defaultCenter = ll.LatLng(-6.200000, 106.816666);

  @override
  void initState() {
    super.initState();
    _fetchOnce();
    _timer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _fetchOnce(),
    );
  }

  Future<void> _fetchOnce() async {
    if (_loading) return;

    setState(() => _loading = true);

    try {
      String? token;
      try {
        final prefs = await SharedPreferences.getInstance();
        token = prefs.getString('api_token');
      } catch (_) {
        token = null;
      }

      final data = await ApiService.fetchBookingLocation(
        bookingId: widget.bookingId,
        token: token,
      );

      if (data.isNotEmpty) {
        final lat = _tryParse(data['lat']);
        final lng = _tryParse(data['lng']);

        if (lat != null && lng != null) {
          final pos = ll.LatLng(lat, lng);

          setState(() {
            _driverPos = pos;
            _status = (data['status'] ?? '').toString();

            final ts = data['timestamp'] ??
                data['updated_at'] ??
                data['last_location_at'];

            _lastUpdated = ts is String
                ? DateTime.tryParse(ts)
                : (ts is int ? DateTime.fromMillisecondsSinceEpoch(ts) : null);
          });

          // PENTING: move map setelah frame siap
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _mapController.move(pos, 15);
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Tracking error: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  double? _tryParse(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final center = _driverPos ?? _defaultCenter;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tracking Driver'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: center,
                initialZoom: 13,
              ),
              children: [
                /// === TILE MAP (ANTI BLANK & CORS) ===
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  tileProvider: NetworkTileProvider(),
                  userAgentPackageName: 'com.example.nebeng',
                ),

                /// === DRIVER MARKER ===
                if (_driverPos != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        width: 56,
                        height: 56,
                        point: _driverPos!,
                        child: const Icon(
                          Icons.directions_car,
                          color: Colors.blue,
                          size: 36,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          /// === BOTTOM INFO ===
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _status.isNotEmpty ? _status : 'Status tidak tersedia',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _lastUpdated != null
                            ? 'Terakhir: ${_lastUpdated.toString()}'
                            : 'Belum ada data lokasi',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: _fetchOnce,
                  child: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Refresh'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
