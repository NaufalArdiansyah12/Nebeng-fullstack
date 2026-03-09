import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// QR Code only screen - shown when status is sudah_sampai_tujuan
class QROnlyScreen extends StatefulWidget {
  final String? qrCodeData;
  final String bookingNumber;
  final int? destinationLocationId;
  final String bookingType;
  final int bookingId;
  final VoidCallback? onTripCompleted;

  const QROnlyScreen({
    Key? key,
    required this.qrCodeData,
    required this.bookingNumber,
    this.destinationLocationId,
    required this.bookingType,
    required this.bookingId,
    this.onTripCompleted,
  }) : super(key: key);

  @override
  State<QROnlyScreen> createState() => _QROnlyScreenState();
}

class _QROnlyScreenState extends State<QROnlyScreen> {
  bool _isLoadingBypass = true;
  bool _bypassEnabled = false;
  bool _isCompletingTrip = false;

  @override
  void initState() {
    super.initState();
    _checkBypassSetting();
  }

  Future<void> _checkBypassSetting() async {
    if (widget.destinationLocationId == null) {
      print('DEBUG: destinationLocationId is null, bypass disabled');
      setState(() {
        _isLoadingBypass = false;
        _bypassEnabled = false;
      });
      return;
    }

    print(
        'DEBUG: Checking bypass for location ID: ${widget.destinationLocationId}');

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');

      if (token == null) {
        print('DEBUG: No token found');
        setState(() {
          _isLoadingBypass = false;
        });
        return;
      }

      // API endpoint untuk mobile app (shared route)
      final url =
          '${const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:3001')}/api/location-qr-bypass/${widget.destinationLocationId}/check';
      print('DEBUG: Calling API: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('DEBUG: Response status: ${response.statusCode}');
      print('DEBUG: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final bypassEnabled = data['data']['qr_bypass_enabled'] ?? false;
          print('DEBUG: Bypass enabled: $bypassEnabled');
          setState(() {
            _bypassEnabled = bypassEnabled;
          });
        }
      }
    } catch (e) {
      print('Error checking bypass setting: $e');
    } finally {
      setState(() {
        _isLoadingBypass = false;
      });
    }
  }

  Future<void> _completeTrip() async {
    setState(() {
      _isCompletingTrip = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');

      if (token == null) {
        _showError('Token tidak ditemukan');
        return;
      }

      // Use Laravel backend (port 8000) with booking ID
      final laravelBaseUrl = const String.fromEnvironment(
          'LARAVEL_API_BASE_URL',
          defaultValue: 'http://10.0.2.2:8000');
      final url =
          '$laravelBaseUrl/api/v1/booking/${widget.bookingType}/${widget.bookingId}/complete-by-driver';

      print('DEBUG Complete Trip: URL = $url');
      print('DEBUG Complete Trip: bookingType = ${widget.bookingType}');
      print('DEBUG Complete Trip: bookingId = ${widget.bookingId}');

      // Complete the trip via Laravel API
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('DEBUG Complete Trip: Status = ${response.statusCode}');
      print('DEBUG Complete Trip: Response = ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Tebengan berhasil diselesaikan! Silakan beri rating customer'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
            // Trigger callback to parent to refresh and show rating
            if (widget.onTripCompleted != null) {
              widget.onTripCompleted!();
            } else {
              // Fallback if no callback provided
              Navigator.of(context).pop(true);
            }
          }
        } else {
          _showError(data['message'] ?? 'Gagal menyelesaikan tebengan');
        }
      } else {
        final errorBody = response.body;
        print('DEBUG Complete Trip: Error body = $errorBody');
        _showError('Gagal menyelesaikan tebengan (${response.statusCode})');
      }
    } catch (e) {
      print('Error completing trip: $e');
      _showError('Terjadi kesalahan: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isCompletingTrip = false;
        });
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _bypassEnabled ? 'Selesaikan Tebengan' : 'Scan QR Code',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoadingBypass
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _bypassEnabled
              ? _buildBypassView()
              : _buildQRView(),
    );
  }

  Widget _buildBypassView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_outline,
                size: 80,
                color: Colors.green.shade600,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Anda sudah sampai di tujuan',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1a1a1a),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Kode Booking: ${widget.bookingNumber}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 48),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade700,
                    size: 32,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Wilayah ini tidak memiliki PosMitra',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue.shade900,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Anda bisa menyelesaikan tebengan langsung tanpa scan QR',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isCompletingTrip ? null : _completeTrip,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isCompletingTrip
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Selesaikan Tebengan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQRView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Tunjukkan QR Code ini kepada customer',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1a1a1a),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          if (widget.qrCodeData != null && widget.qrCodeData!.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: QrImageView(
                data: widget.qrCodeData!,
                version: QrVersions.auto,
                size: 280.0,
                backgroundColor: Colors.white,
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(48),
              child: Column(
                children: [
                  Icon(
                    Icons.qr_code,
                    size: 120,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'QR Code tidak tersedia',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          Text(
            'Kode Booking: ${widget.bookingNumber}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 48),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Customer akan scan QR code ini untuk menyelesaikan tebengan',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
