import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../services/api_service.dart';
import 'ride_success_page.dart';

class DetailRidePage extends StatelessWidget {
  final int originLocationId;
  final String originLocationName;
  final int destinationLocationId;
  final String destinationLocationName;
  final DateTime departureDate;
  final TimeOfDay departureTime;
  final String serviceType;
  final String rideType;
  final String vehicleName;
  final String vehiclePlate;
  final String vehicleBrand;
  final String vehicleType;
  final String vehicleColor;
  final double price;
  final int availableSeats;
  final int? kendaraanMitraId;
  final int? bagasiCapacity;
  final int? jumlahBagasi;

  const DetailRidePage({
    Key? key,
    required this.originLocationId,
    required this.originLocationName,
    required this.destinationLocationId,
    required this.destinationLocationName,
    required this.departureDate,
    required this.departureTime,
    required this.serviceType,
    this.rideType = 'motor',
    required this.vehicleName,
    required this.vehiclePlate,
    required this.vehicleBrand,
    required this.vehicleType,
    required this.vehicleColor,
    required this.price,
    required this.availableSeats,
    this.kendaraanMitraId,
    this.bagasiCapacity,
    this.jumlahBagasi,
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

  String _getServiceTypeLabel() {
    switch (serviceType) {
      case 'tebengan':
        return 'Hanya Tebengan';
      case 'barang':
        return 'Hanya Titip Barang';
      case 'both':
        return 'Barang dan Tebengan';
      default:
        return serviceType;
    }
  }

  Future<void> _submitRide(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');

      final timeString =
          '${departureTime.hour.toString().padLeft(2, '0')}:${departureTime.minute.toString().padLeft(2, '0')}:00';

      final response = await ApiService.createRide(
        token: token!,
        originLocationId: originLocationId,
        destinationLocationId: destinationLocationId,
        departureDate: departureDate.toIso8601String().split('T')[0],
        departureTime: timeString,
        rideType: rideType,
        serviceType: serviceType,
        price: price,
        kendaraanMitraId: kendaraanMitraId,
        bagasiCapacity: bagasiCapacity,
        jumlahBagasi: jumlahBagasi,
        vehicleName: vehicleName,
        vehiclePlate: vehiclePlate,
        vehicleBrand: vehicleBrand,
        vehicleType: vehicleType,
        vehicleColor: vehicleColor,
        availableSeats: availableSeats,
      );

      // Extract QR code from response
      final qrCodeData = response['data']?['qr_code_data'] as String?;

      if (context.mounted) {
        Navigator.pop(context); // Close loading
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => RideSuccessPage(qrCodeData: qrCodeData),
          ),
        );
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
                  const SizedBox(height: 12),
                  // Service type and bagasi info as chips
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 6, horizontal: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6EEF8),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getServiceTypeLabel(),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF1E40AF),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (bagasiCapacity != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 6, horizontal: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Kapasitas bagasi: ${bagasiCapacity.toString()} kg',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
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
                                _buildDetailItem('Nama Mitra', vehicleName),
                                const SizedBox(height: 18),
                                _buildDetailItem(
                                    'Nomor Registrasi', vehiclePlate),
                                const SizedBox(height: 18),
                                _buildDetailItem('Merk', vehicleBrand),
                                const SizedBox(height: 18),
                                _buildDetailItem('Tipe', vehicleType),
                                const SizedBox(height: 18),
                                _buildDetailItem('Warna', vehicleColor),
                                const SizedBox(height: 18),
                                _buildDetailItem(
                                    'Kapasitas Bagasi',
                                    bagasiCapacity != null
                                        ? '${bagasiCapacity.toString()} kg'
                                        : '-'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),

                          // (leave space so content can scroll above fixed footer)
                          const SizedBox(height: 12),
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
                                  'Tarif per penumpang',
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
                            onPressed: () => _submitRide(context),
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
