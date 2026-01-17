import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'titip_barang_success_page.dart';

class DetailTitipBarangPage extends StatelessWidget {
  final int originLocationId;
  final String originLocationName;
  final int destinationLocationId;
  final String destinationLocationName;
  final DateTime departureDate;
  final TimeOfDay departureTime;
  final String transportationType;
  final int bagasiCapacity;
  final double price;

  const DetailTitipBarangPage({
    Key? key,
    required this.originLocationId,
    required this.originLocationName,
    required this.destinationLocationId,
    required this.destinationLocationName,
    required this.departureDate,
    required this.departureTime,
    required this.transportationType,
    required this.bagasiCapacity,
    required this.price,
  }) : super(key: key);

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des'
    ];
    return months[month - 1];
  }

  String _getDayName(DateTime date) {
    const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    return days[date.weekday - 1];
  }

  String _getTransportationLabel() {
    switch (transportationType) {
      case 'kereta':
        return 'Kereta';
      case 'pesawat':
        return 'Pesawat';
      case 'bus':
        return 'Bus';
      default:
        return transportationType;
    }
  }

  String _getBagasiLabel() {
    switch (bagasiCapacity) {
      case 5:
        return 'Kecil - Maksimal 5 kg';
      case 10:
        return 'Sedang - Maksimal 10 kg';
      case 20:
        return 'Besar - Maksimal 20 kg';
      default:
        return '$bagasiCapacity kg';
    }
  }

  Future<void> _submitTitipBarang(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');

      print('DEBUG: Token = $token'); // Debug line

      if (token == null || token.isEmpty) {
        throw Exception('Token not found. Please login again.');
      }

      final timeString =
          '${departureTime.hour.toString().padLeft(2, '0')}:${departureTime.minute.toString().padLeft(2, '0')}:00';

      final requestBody = {
        'origin_location_id': originLocationId,
        'destination_location_id': destinationLocationId,
        'departure_date': departureDate.toIso8601String().split('T')[0],
        'departure_time': timeString,
        'transportation_type': transportationType,
        'bagasi_capacity': bagasiCapacity,
        'price': price,
      };

      print('DEBUG: Request body = $requestBody');

      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/api/v1/tebengan-titip-barang'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      print('DEBUG: Response status = ${response.statusCode}');
      print('DEBUG: Response body = ${response.body}');

      if (context.mounted) {
        Navigator.pop(context); // Close loading

        // Check if response is HTML (error page)
        if (response.body.trim().startsWith('<')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Server error. Status: ${response.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        final responseData = jsonDecode(response.body);

        if (response.statusCode == 201 && responseData['success'] == true) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const TitipBarangSuccessPage(),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(responseData['message'] ??
                    'Failed to create titip barang')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E40AF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E40AF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Detail Tebengan',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          // Card putih di atas background biru
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tanggal dan waktu
                  Text(
                    '${_getDayName(departureDate)}, ${departureDate.day} ${_getMonthName(departureDate.month)} ${departureDate.year} - ${departureTime.hour.toString().padLeft(2, '0')}:${departureTime.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Lokasi dengan arrow
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          originLocationName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(
                          Icons.arrow_forward,
                          color: Colors.black87,
                          size: 20,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          destinationLocationName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Subtitle lokasi
                  Text(
                    '$originLocationName (PI) - $destinationLocationName (PI)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Container putih untuk konten di bawah dengan tombol tetap di bawah
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  // Scrollable content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Detail Mitra Section
                          const Text(
                            'Detail Mitra',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),

                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                vertical: 18, horizontal: 18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFE6EEF8),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDetailItem('Jenis Transportasi',
                                    _getTransportationLabel()),
                                const SizedBox(height: 18),
                                _buildDetailItem(
                                    'Kapasitas Bagasi', _getBagasiLabel()),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),

                  // Fixed footer: Tarif + Button
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                    color: Colors.white,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Tarif',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Tarif per Kg',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'Rp ${price.toStringAsFixed(0).replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => '${m[1]}.')}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () => _submitTitipBarang(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E40AF),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Buat tebengan',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF9E9E9E),
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
