import 'package:flutter/material.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../../../services/api_service.dart';
import 'payment/reschedule_payment_detail_page.dart';

class SavedPassenger {
  int id;
  String name;
  String phone;

  SavedPassenger({required this.id, required this.name, required this.phone});

  factory SavedPassenger.fromJson(Map<String, dynamic> json) {
    return SavedPassenger(
      id: json['id'] as int,
      name: json['name'] as String,
      phone: json['phone'] as String,
    );
  }
}

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
  List<SavedPassenger> savedPassengers = [];
  bool _isLoadingPassengers = false;
  // Barang-specific fields
  final TextEditingController _barangDescriptionController =
      TextEditingController();
  String? _selectedBarangSize;
  String? _barangImagePath;
  String? _penerimaName;
  String? _penerimaPhone;
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
    _loadSavedPassengersFromApi();
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

  Future<void> _loadSavedPassengersFromApi() async {
    setState(() => _isLoadingPassengers = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');
      if (token != null) {
        final List<Map<String, dynamic>> response =
            await ApiService.getSavedPassengers(token: token);
        setState(() {
          savedPassengers =
              response.map((json) => SavedPassenger.fromJson(json)).toList();
        });
      }
    } catch (e) {
      // ignore error, keep empty list
    } finally {
      setState(() => _isLoadingPassengers = false);
    }
  }

  Future<void> _deleteSavedPassenger(SavedPassenger passenger) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('api_token');
    if (token == null) return;

    try {
      final success = await ApiService.deletePassenger(
        token: token,
        passengerId: passenger.id,
      );

      if (success) {
        await _loadSavedPassengersFromApi();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ ${passenger.name} dihapus dari daftar'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menghapus penumpang'),
          backgroundColor: Colors.red,
        ),
      );
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

      // If backend indicates no payment required, the request is created and
      // will be processed (approved) by admin/automatic flow — inform user
      // that the reschedule request was submitted and do not attempt payment.
      final paymentRequired = (res['payment_required'] ?? true) as bool;
      if (!paymentRequired) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Permintaan ubah jadwal terkirim. Menunggu konfirmasi.')),
          );

          // Show confirmation dialog giving user a choice to stay or go back
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Permintaan Terkirim'),
              content: const Text(
                  'Permintaan ubah jadwal telah dikirim dan menunggu konfirmasi dari pihak terkait.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop(); // close dialog, stay on page
                  },
                  child: const Text('Tutup'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop(); // close dialog
                    if (mounted)
                      Navigator.of(context)
                          .pop(true); // go back and indicate success
                  },
                  child: const Text('Kembali'),
                ),
              ],
            ),
          );
        }
        return;
      }

      // Proceed with payment flow when required
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
      final double rescheduleFee = (res['reschedule_fee'] ?? 0).toDouble();
      final double adminFee = (res['admin_fee'] ?? 0).toDouble();
      final double passengerCharge = priceDiff > 0 ? priceDiff : 0.0;
      // Backend PaymentService expects `amount` to be the nominal charge (excluding admin fee).
      // Pass passengerCharge + rescheduleFee as `amount`, and pass `adminFee` separately.
      final double amountWithoutAdmin = passengerCharge + rescheduleFee;
      final double totalAmount = amountWithoutAdmin + adminFee;

      final payData = await ApiService.createPayment(
        rideId: targetId,
        userId: userId,
        bookingNumber: widget.booking['booking_number']?.toString() ?? '',
        bookingId: widget.booking['id'],
        paymentMethod: 'bri',
        amount: amountWithoutAdmin,
        bookingPrice: passengerCharge,
        rescheduleRequestId: requestId,
        adminFee: adminFee,
      );

      // ApiService.createPayment may return either the inner data map
      // or a wrapper { success: true, data: { ... } } depending on caller.
      // Debug output to inspect API response shape when VA missing
      try {
        print('createPayment raw response: ' + payData.toString());
      } catch (_) {}

      final payload = (payData is Map &&
              payData.containsKey('data') &&
              payData['data'] is Map)
          ? Map<String, dynamic>.from(payData['data'] as Map)
          : (payData is Map
              ? Map<String, dynamic>.from(payData)
              : <String, dynamic>{});
      try {
        print('createPayment payload extracted: ' + payload.toString());
      } catch (_) {}

      final payment = payload['payment'] ?? payload['data'] ?? null;
      final va = payload['virtual_account_number'] ??
          (payment != null
              ? (payment['virtual_account_number'] ??
                  payment['virtualAccount'] ??
                  null)
              : null) ??
          '';

      String paymentId = '';
      if (payment != null && payment is Map) {
        if (payment['id'] != null) {
          paymentId = payment['id'].toString();
        } else if (payment['external_id'] != null) {
          paymentId = payment['external_id'].toString();
        } else if (payment['externalId'] != null) {
          paymentId = payment['externalId'].toString();
        }
      } else if (payload['external_id'] != null) {
        paymentId = payload['external_id'].toString();
      } else if (payload['externalId'] != null) {
        paymentId = payload['externalId'].toString();
      }

      // Get total passengers from booking
      final totalPassengers = passengers.length;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ReschedulePaymentDetailPage(
            requestId: requestId,
            paymentTxnId: paymentId,
            virtualAccount: va ?? '',
            bankCode: payData['bank_code'] ??
                ((payment != null) ? payment['bank_code'] : null) ??
                '',
            amount: payData['payment'] != null
                ? (payData['payment']['total_amount'] ?? totalAmount)
                : totalAmount,
            // Pass the actual payment object (extracted into `payment`) so
            // the detail page can read `admin_fee` and `total_amount` directly.
            serverPayment: payment,
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

  void _showPenerimaBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PenerimaBottomSheet(
        initialName: _penerimaName,
        initialPhone: _penerimaPhone,
        onSave: (name, phone) {
          setState(() {
            _penerimaName = name;
            _penerimaPhone = phone;
          });
        },
      ),
    );
  }

  void _showAddPassengerDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PassengerInfoBottomSheet(
        passengers: passengers,
        savedPassengers: savedPassengers,
        onAddNew: () {
          Navigator.pop(context);
          _showAddNewPassengerDialog();
        },
        onSelectSaved: (saved) {
          setState(() {
            if (!passengers.any(
                (p) => p['name'] == saved.name && p['phone'] == saved.phone)) {
              passengers.add({'name': saved.name, 'phone': saved.phone});
            }
          });
          Navigator.pop(context);
        },
        onDelete: (index) {
          setState(() {
            passengers.removeAt(index);
          });
          Navigator.pop(context);
          _showAddPassengerDialog();
        },
        onDeleteSaved: _deleteSavedPassenger,
      ),
    );
  }

  void _showAddNewPassengerDialog() {
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
        onSaveToList: (name, phone) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('api_token');
          if (token != null) {
            try {
              await ApiService.savePassenger(
                token: token,
                name: name,
                phone: phone,
              );
              await _loadSavedPassengersFromApi();
            } catch (e) {
              // ignore error
            }
          }
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
                            onTap: _showPenerimaBottomSheet,
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
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Data Penerima',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.black87,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (_penerimaName != null) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            _penerimaName!,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                          if (_penerimaPhone != null)
                                            Text(
                                              _penerimaPhone!,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[500],
                                              ),
                                            ),
                                        ],
                                      ],
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

                        // Tambah Penumpang Button (hide for motor bookings)
                        if ((widget.booking['booking_type'] ?? '')
                                .toString()
                                .toLowerCase() !=
                            'motor')
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
  final Function(String name, String phone)? onSaveToList;

  const _AddPassengerBottomSheet({
    required this.onAdd,
    this.onSaveToList,
  });

  @override
  State<_AddPassengerBottomSheet> createState() =>
      _AddPassengerBottomSheetState();
}

class _AddPassengerBottomSheetState extends State<_AddPassengerBottomSheet> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _saveToList = false;
  String? nameError;
  String? phoneError;

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
                onChanged: (_) => setState(() => nameError = null),
                decoration: InputDecoration(
                  hintText: 'Nama Anda',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  errorText: nameError,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color:
                            nameError != null ? Colors.red : Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color:
                            nameError != null ? Colors.red : Colors.grey[300]!),
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
                onChanged: (_) => setState(() => phoneError = null),
                decoration: InputDecoration(
                  hintText: 'No Telp Anda',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  errorText: phoneError,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: phoneError != null
                            ? Colors.red
                            : Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: phoneError != null
                            ? Colors.red
                            : Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF1E3A8A)),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bookmark_outline,
                        color: Color(0xFF1E3A8A), size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Simpan ke daftar penebeng',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            'Untuk memudahkan booking selanjutnya',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _saveToList,
                      onChanged: (value) {
                        setState(() {
                          _saveToList = value;
                        });
                      },
                      activeColor: const Color(0xFF1E3A8A),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    setState(() {
                      nameError = null;
                      phoneError = null;
                    });

                    if (_nameController.text.trim().isEmpty) {
                      setState(() => nameError = 'Nama harus diisi');
                      return;
                    }

                    if (_phoneController.text.trim().isEmpty) {
                      setState(() => phoneError = 'No telp harus diisi');
                      return;
                    }

                    if (_phoneController.text.trim().length < 10) {
                      setState(() => phoneError = 'No telp minimal 10 digit');
                      return;
                    }

                    final name = _nameController.text.trim();
                    final phone = _phoneController.text.trim();

                    widget.onAdd(name, phone);

                    if (_saveToList && widget.onSaveToList != null) {
                      await widget.onSaveToList!(name, phone);
                    }

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('\u2713 $name ditambahkan'),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 2),
                      ),
                    );
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

// Bottom Sheet for Passenger Info with Search
class _PassengerInfoBottomSheet extends StatefulWidget {
  final List<Map<String, dynamic>> passengers;
  final List<SavedPassenger> savedPassengers;
  final VoidCallback onAddNew;
  final Function(SavedPassenger) onSelectSaved;
  final Function(int) onDelete;
  final Function(SavedPassenger) onDeleteSaved;

  const _PassengerInfoBottomSheet({
    required this.passengers,
    required this.savedPassengers,
    required this.onAddNew,
    required this.onSelectSaved,
    required this.onDelete,
    required this.onDeleteSaved,
  });

  @override
  State<_PassengerInfoBottomSheet> createState() =>
      _PassengerInfoBottomSheetState();
}

class _PassengerInfoBottomSheetState extends State<_PassengerInfoBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filteredPassengers = widget.savedPassengers.where((p) {
      if (_searchQuery.isEmpty) return true;
      return p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.phone.contains(_searchQuery);
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
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
                const SizedBox(height: 16),
                // Current Passengers
                if (widget.passengers.isNotEmpty) ...[
                  const Text(
                    'Penumpang yang ditambahkan:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...widget.passengers.asMap().entries.map((entry) {
                    final index = entry.key;
                    final p = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: Color(0xFF1E3A8A),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p['name'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  p['phone'] ?? '',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline,
                                color: Colors.red[400], size: 20),
                            onPressed: () => widget.onDelete(index),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                // Add Passenger Button
                OutlinedButton(
                  onPressed: widget.onAddNew,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1E3A8A),
                    side: const BorderSide(color: Color(0xFF1E3A8A)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.add_circle_outline, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Tambah Penebeng Baru',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Search Bar
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Cari penebeng tersimpan',
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Saved Passengers List
          Expanded(
            child: filteredPassengers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline,
                            size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'Belum ada penebeng tersimpan'
                              : 'Tidak ada hasil pencarian',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredPassengers.length,
                    itemBuilder: (context, index) {
                      final passenger = filteredPassengers[index];
                      final isAdded = widget.passengers.any((p) =>
                          p['name'] == passenger.name &&
                          p['phone'] == passenger.phone);

                      return InkWell(
                        onTap: isAdded
                            ? null
                            : () => widget.onSelectSaved(passenger),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isAdded ? Colors.grey[100] : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey[300]!,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      passenger.name,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: isAdded
                                            ? Colors.grey[500]
                                            : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      passenger.phone,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isAdded)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green[50],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Ditambahkan',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.green[700],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                )
                              else
                                const Icon(Icons.add_circle_outline,
                                    color: Color(0xFF1E3A8A), size: 20),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: Icon(Icons.delete_outline,
                                    color: Colors.red[400], size: 20),
                                onPressed: () =>
                                    widget.onDeleteSaved(passenger),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// Bottom Sheet for Passenger List (deprecated, keeping for compatibility)
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
      {'name': 'Ailsa Nasywa', 'phone': '081234567890'},
      {'name': 'Karina', 'phone': '081298765432'},
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Informasi Penebeng',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tambah Penebeng Button
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    // Show add passenger dialog
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF1E40AF),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E40AF).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Color(0xFF1E40AF),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Tambah Penebeng',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Cari Penebeng Section
                const Text(
                  'Cari Penebeng yang sudah terdaftar',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),

                // Search Field
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.2),
                    ),
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Cari Penebeng yang terdaftar',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.grey[400],
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // List Penebeng
                ...existingPassengers.map((passenger) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () {
                        onSelect(passenger);
                        Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E40AF).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  passenger['name']
                                          ?.substring(0, 1)
                                          .toUpperCase() ??
                                      'A',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1E40AF),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    passenger['name'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  if (passenger['phone'] != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      passenger['phone'] ?? '',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.grey[400],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Bottom Sheet untuk Data Penerima
class _PenerimaBottomSheet extends StatefulWidget {
  final String? initialName;
  final String? initialPhone;
  final Function(String name, String phone) onSave;

  const _PenerimaBottomSheet({
    this.initialName,
    this.initialPhone,
    required this.onSave,
  });

  @override
  State<_PenerimaBottomSheet> createState() => _PenerimaBottomSheetState();
}

class _PenerimaBottomSheetState extends State<_PenerimaBottomSheet> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  String? nameError;
  String? phoneError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _phoneController = TextEditingController(text: widget.initialPhone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

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
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Data Penerima',
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
                'Nama Penerima',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                onChanged: (_) => setState(() => nameError = null),
                decoration: InputDecoration(
                  hintText: 'Masukkan nama penerima',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  errorText: nameError,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color:
                            nameError != null ? Colors.red : Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color:
                            nameError != null ? Colors.red : Colors.grey[300]!),
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
                'No. Telepon',
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
                onChanged: (_) => setState(() => phoneError = null),
                decoration: InputDecoration(
                  hintText: 'Masukkan nomor telepon',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  errorText: phoneError,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: phoneError != null
                            ? Colors.red
                            : Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: phoneError != null
                            ? Colors.red
                            : Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF1E3A8A)),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      nameError = null;
                      phoneError = null;
                    });

                    if (_nameController.text.trim().isEmpty) {
                      setState(() => nameError = 'Nama penerima harus diisi');
                      return;
                    }

                    if (_phoneController.text.trim().isEmpty) {
                      setState(() => phoneError = 'No. telepon harus diisi');
                      return;
                    }

                    if (_phoneController.text.trim().length < 10) {
                      setState(
                          () => phoneError = 'No. telepon minimal 10 digit');
                      return;
                    }

                    widget.onSave(
                      _nameController.text.trim(),
                      _phoneController.text.trim(),
                    );
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            '✓ ${_nameController.text.trim()} ditambahkan'),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 2),
                      ),
                    );
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
