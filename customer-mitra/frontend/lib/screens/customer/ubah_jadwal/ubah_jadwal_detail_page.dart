import 'package:flutter/material.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../../../services/api_service.dart';
import 'payment/reschedule_payment_detail_page.dart';

class UbahJadwalDetailPage extends StatefulWidget {
  final Map<String, dynamic> booking;
  final Map<String, dynamic> selectedRide;
  final DateTime selectedDate;
  final String? barangImagePath;

  const UbahJadwalDetailPage({
    Key? key,
    required this.booking,
    required this.selectedRide,
    required this.selectedDate,
    this.barangImagePath,
  }) : super(key: key);

  @override
  State<UbahJadwalDetailPage> createState() => _UbahJadwalDetailPageState();
}

class _UbahJadwalDetailPageState extends State<UbahJadwalDetailPage> {
  bool isLoading = false;
  List<Map<String, dynamic>> passengers = [];
  // Barang-specific fields
  final TextEditingController _barangDescriptionController =
      TextEditingController();
  String? _selectedBarangSize;
  String? _barangImagePath;
  final List<String> _barangSizes = [
    'Kecil',
    'Sedang',
    'Besar',
  ];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadPassengers();
    // Try to fetch latest booking details (including penumpang) from API
    _fetchBookingDetails();
    // initialize barang image from incoming param if any
    _barangImagePath = widget.barangImagePath;
  }

  Future<void> _pickImage() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 80,
      );
      if (picked != null) {
        setState(() {
          _barangImagePath = picked.path;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memilih gambar: $e')),
      );
    }
  }

  Future<void> _fetchBookingDetails() async {
    try {
      final bookingId = widget.booking['id'];
      if (bookingId == null) return;
      final fresh = await ApiService.fetchBooking(bookingId: bookingId);
      if (fresh.isNotEmpty) {
        final penumpang = fresh['penumpang'];
        if (penumpang is List && penumpang.isNotEmpty) {
          setState(() {
            passengers = List<Map<String, dynamic>>.from(
              penumpang.map((p) => {
                    'name': p['nama'] ?? p['name'] ?? '',
                    'phone': p['no_telepon'] ?? p['phone'] ?? '',
                  }),
            );
          });
          return;
        }
      }
    } catch (e) {
      // ignore errors, keep existing passengers
    }
  }

  void _loadPassengers() {
    final penumpang = widget.booking['penumpang'];
    if (penumpang != null) {
      if (penumpang is List) {
        passengers = List<Map<String, dynamic>>.from(
          penumpang.map((p) => {
                'name': p['nama'] ?? p['name'] ?? '',
                'phone': p['no_telepon'] ?? p['phone'] ?? '',
              }),
        );
      } else if (penumpang is String && penumpang.isNotEmpty) {
        try {
          final decoded = penumpang;
          passengers = [
            {'name': decoded, 'phone': ''}
          ];
        } catch (e) {
          passengers = [];
        }
      }
    }

    if (passengers.isEmpty) {
      final user = widget.booking['user'];
      if (user != null) {
        passengers = [
          {
            'name': user['name'] ?? 'Penumpang',
            'phone': user['phone'] ?? '',
          }
        ];
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')} ${_getMonthName(date.month)} ${date.year}';
  }

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

  String _formatTime(String time) {
    try {
      final parts = time.split(':');
      return '${parts[0]}.${parts[1]}';
    } catch (e) {
      return time;
    }
  }

  Future<void> _confirmReschedule() async {
    setState(() {
      isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');

      if (token == null || token.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Silakan login untuk melanjutkan')),
        );
        return;
      }

      final bookingId = widget.booking['id'];
      final bookingType =
          (widget.booking['booking_type'] ?? 'mobil').toString();
      final targetId =
          widget.selectedRide['ride_id'] ?? widget.selectedRide['id'];

      final res = await ApiService.createReschedule(
        token: token,
        bookingId: bookingId,
        bookingType: bookingType,
        requestedTargetType: bookingType == 'motor' ? 'motor' : 'car',
        requestedTargetId: targetId,
        barangImagePath: _barangImagePath ?? widget.barangImagePath,
      );

      setState(() {
        isLoading = false;
      });

      final requestId = res['request_id'];

      // Always go through payment flow, even if payment not required
      final profile = await ApiService.getProfile(token: token);
      int userId = 0;
      if (profile['success'] == true && profile['data'] != null) {
        final u = profile['data']['user'] ?? profile['data'];
        userId = u['id'] ?? 0;
      }

      if (userId == 0) {
        throw Exception('User ID not found');
      }

      final priceDiff = (res['price_diff'] ?? 0).toDouble();
      final priceBefore = (res['price_before'] ?? 0).toDouble();
      final priceAfter = (res['price_after'] ?? 0).toDouble();

      // Calculate reschedule fee
      // Use absolute value of price diff + admin fee
      // Or minimum reschedule fee if price goes down
      final rescheduleAmount = priceDiff.abs(); // Always positive
      final adminFee = 15000.0; // Always charge admin fee for reschedule

      final payData = await ApiService.createPayment(
        rideId: targetId,
        userId: userId,
        bookingNumber: widget.booking['booking_number']?.toString() ?? '',
        bookingId: widget.booking['id'],
        paymentMethod: 'bri',
        amount: rescheduleAmount,
        adminFee: adminFee,
      );

      final payment = payData['payment'] ?? {};
      final va = payData['virtual_account_number'] ??
          payment['virtual_account_number'];
      final paymentId =
          payment['id']?.toString() ?? payData['payment']['external_id'] ?? '';

      // Get total passengers from booking
      final totalPassengers = passengers.length;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ReschedulePaymentDetailPage(
            requestId: requestId,
            paymentTxnId: paymentId,
            virtualAccount: va ?? '',
            bankCode: payData['bank_code'] ?? payment['bank_code'] ?? '',
            amount: payData['payment'] != null
                ? (payData['payment']['total_amount'] ??
                    (rescheduleAmount + adminFee))
                : (rescheduleAmount + adminFee),
            bookingData: widget.booking,
            newRideData: widget.selectedRide,
            priceBefore: priceBefore,
            priceAfter: priceAfter,
            priceDiff: priceDiff,
            totalPassengers: totalPassengers,
            passengers: passengers,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      final msg = e.toString();
      if (msg.toLowerCase().contains('unauthorized')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sesi Anda telah berakhir. Silakan login ulang.'),
            duration: Duration(seconds: 4),
          ),
        );
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('api_token');
        } catch (_) {}
        // Go back to home screen instead of forcing login redirect
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan: $e')),
        );
      }
    }
  }

  void _showAddPassengerDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddPassengerBottomSheet(
        onAdd: (name, phone) {
          setState(() {
            passengers.add({'name': name, 'phone': phone});
          });
        },
      ),
    );
  }

  void _showPassengerListDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PassengerListBottomSheet(
        passengers: passengers,
        onSelect: (passenger) {
          setState(() {
            if (!passengers.any((p) => p['name'] == passenger['name'])) {
              passengers.add(passenger);
            }
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ride = widget.selectedRide;
    final bookingNumber =
        widget.booking['booking_number']?.toString() ?? 'FR-2345678997543234';
    final bookingType =
        (widget.booking['booking_type'] ?? '').toString().toLowerCase();
    final isBarang = bookingType == 'barang' || bookingType == 'titip';

    String origin = 'Yogyakarta';
    String destination = 'Purwokerto';
    String originAddress =
        'Pos 1, Kecamatan Kraton, Kota Yogyakarta Daerah Istimewa Yogyakarta 55133';
    String destinationAddress =
        'Jl Prof. Dr. Suharso No.8, Mangunjaya, Purwokerto Lor Kec. Purwokerto Tim. Kabupaten Banyumas, Jawa Tengah 53112';

    if (ride['origin_location'] is Map && ride['origin_location'] != null) {
      origin = ride['origin_location']['name'] ?? origin;
      originAddress = ride['origin_location']['address'] ?? originAddress;
    }
    if (ride['destination_location'] is Map &&
        ride['destination_location'] != null) {
      destination = ride['destination_location']['name'] ?? destination;
      destinationAddress =
          ride['destination_location']['address'] ?? destinationAddress;
    }

    final departureTime = ride['departure_time'] ?? '09:00';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton(
            icon: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Color(0xFF1E3A8A),
                size: 18,
              ),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: const Text(
          'Pesan',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Booking Number Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'No Pemesanan:',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    bookingNumber,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Route Section
                  const Text(
                    'Rute:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Route Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      children: [
                        // Origin
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              margin: const EdgeInsets.only(top: 2),
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    origin,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    originAddress,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Line connector
                        Padding(
                          padding:
                              const EdgeInsets.only(left: 9, top: 4, bottom: 4),
                          child: Column(
                            children: List.generate(
                              3,
                              (index) => Container(
                                margin: const EdgeInsets.only(top: 3),
                                width: 2,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Destination
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              margin: const EdgeInsets.only(top: 2),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF97316),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    destination,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    destinationAddress,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Date and Time Info
                  _buildInfoRow(
                      'Tanggal Berangkat:', _formatDate(widget.selectedDate)),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                      'Jam Berangkat:', '${_formatTime(departureTime)} WIB'),
                  const SizedBox(height: 12),
                  _buildInfoRow('Tanggal Pesan:', _formatDate(DateTime.now())),

                  const SizedBox(height: 24),

                  // If booking is for barang, show barang-specific inputs
                  Builder(builder: (ctx) {
                    final bookingType = (widget.booking['booking_type'] ?? '')
                        .toString()
                        .toLowerCase();
                    final isBarang = bookingType.contains('barang');

                    if (isBarang) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Cari tanggal untuk mengubah jadwal',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 14, horizontal: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!),
                              color: Colors.white,
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today,
                                    color: Colors.grey),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _formatDate(widget.selectedDate),
                                    style: TextStyle(
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Ukuran Barang',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedBarangSize,
                            decoration: InputDecoration(
                              hintText: 'Pilih ukuran barang anda',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.grey[300]!),
                              ),
                              contentPadding: const EdgeInsets.all(16),
                            ),
                            items: _barangSizes
                                .map((s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(s),
                                    ))
                                .toList(),
                            onChanged: (v) {
                              setState(() {
                                _selectedBarangSize = v;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Keterangan Barang',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _barangDescriptionController,
                            decoration: InputDecoration(
                              hintText: 'contoh: berisi dokumen',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.grey[300]!),
                              ),
                              contentPadding: const EdgeInsets.all(16),
                            ),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Foto Barang',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: _pickImage,
                            child: Container(
                              height: 140,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Center(
                                child: _barangImagePath != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.file(
                                          File(_barangImagePath!),
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: double.infinity,
                                        ),
                                      )
                                    : Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.add_photo_alternate,
                                              size: 36,
                                              color: Colors.grey[500]),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Tambah Foto Barang',
                                            style: TextStyle(
                                                color: Colors.grey[600]),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: () {},
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Data Penerima',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Icon(
                                    Icons.edit,
                                    size: 20,
                                    color: Colors.grey[600],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      );
                    }

                    // default: show penumpang UI
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Penumpang',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),

                        ...passengers.asMap().entries.map((entry) {
                          final passenger = entry.value;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F9FA),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Nama Penumpang:',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      passenger['name'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                if (passenger['phone']?.isNotEmpty == true) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'No Telepon:',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        passenger['phone'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          );
                        }).toList(),

                        const SizedBox(height: 24),

                        // Detail Penebeng Section
                        const Text(
                          'Detail Penebeng',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Tambah Penumpang Button
                        InkWell(
                          onTap: _showAddPassengerDialog,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Tambah Penumpang',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Icon(
                                  Icons.edit,
                                  size: 20,
                                  color: Colors.grey[600],
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 100),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: isLoading ? null : _confirmReschedule,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    isBarang ? 'Ubah Jadwal' : 'lanjut',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black87,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}

// Bottom Sheet for Adding Passenger
class _AddPassengerBottomSheet extends StatefulWidget {
  final Function(String name, String phone) onAdd;

  const _AddPassengerBottomSheet({required this.onAdd});

  @override
  State<_AddPassengerBottomSheet> createState() =>
      _AddPassengerBottomSheetState();
}

class _AddPassengerBottomSheetState extends State<_AddPassengerBottomSheet> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _saveToList = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Tambah Penebeng',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Nama',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Nama Anda',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF1E3A8A)),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF1E3A8A)),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'No Telp',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: 'No Telp Anda',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF1E3A8A)),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Switch(
                    value: _saveToList,
                    onChanged: (value) {
                      setState(() {
                        _saveToList = value;
                      });
                    },
                    activeColor: const Color(0xFF1E3A8A),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Simpan ke daftar penebeng',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_nameController.text.isNotEmpty) {
                      widget.onAdd(_nameController.text, _phoneController.text);
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Simpan',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Bottom Sheet for Passenger List
class _PassengerListBottomSheet extends StatelessWidget {
  final List<Map<String, dynamic>> passengers;
  final Function(Map<String, dynamic>) onSelect;

  const _PassengerListBottomSheet({
    required this.passengers,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final existingPassengers = [
      {'name': 'Ailsa Nasywa'},
      {'name': 'Karina'},
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informasi Penebeng',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              // Show add passenger dialog
            },
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Tambah Penebeng'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1E3A8A),
              side: const BorderSide(color: Color(0xFF1E3A8A)),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Cari Penebeng yang sudah terdaftar',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              hintText: 'Cari Penebeng yang terdaftar',
              hintStyle: TextStyle(color: Colors.grey[400]),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 24),
          ...existingPassengers.map((passenger) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: OutlinedButton(
                onPressed: () {
                  onSelect(passenger);
                  Navigator.pop(context);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black87,
                  side: BorderSide(color: Colors.grey[300]!),
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.centerLeft,
                ),
                child: Text(
                  passenger['name'] ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
