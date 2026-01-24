import 'package:flutter/material.dart';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../../../services/api_service.dart';
import '../../../widgets/custom_calendar_widget.dart';
import '../barang_umum/pages/penerima_picker_page.dart';
import 'ubah_jadwal_list_page.dart';

class UbahJadwalPage extends StatefulWidget {
  final Map<String, dynamic> booking;

  const UbahJadwalPage({Key? key, required this.booking}) : super(key: key);

  @override
  State<UbahJadwalPage> createState() => _UbahJadwalPageState();
}

class _UbahJadwalPageState extends State<UbahJadwalPage> {
  DateTime? selectedDate;
  bool isLoading = false;
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
  final Map<String, String> _barangSizeDescriptions = {
    'Kecil': 'Maksimal 5 Kg',
    'Sedang': 'Maksimal 10 Kg',
    'Besar': 'Maksimal 20 Kg',
  };

  final ImagePicker _picker = ImagePicker();
  // Penerima (recipient) fields for titip/barang
  String? _dataPenerima;
  final TextEditingController _penerimaController = TextEditingController();

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

  void _showPenerimaPicker() async {
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: PenerimaPickerPage(
            currentPenerima: _dataPenerima,
            scrollController: scrollController,
          ),
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _dataPenerima = result['name'];
        _penerimaController.text = result['name'] ?? '';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }

  String _formatDisplayDate(DateTime? date) {
    if (date == null) return '17-01-2026';
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }

  String _formatRideTime(dynamic raw) {
    if (raw == null) return '';
    final s = raw.toString();
    DateTime? dt = DateTime.tryParse(s);
    if (dt != null) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    if (s.contains(':')) {
      final parts = s.split(':');
      if (parts.length >= 2) {
        return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
      }
    }
    return s;
  }

  String _formatRideDate(dynamic raw) {
    if (raw == null) return '';
    final s = raw.toString();
    DateTime? dt = DateTime.tryParse(s);
    if (dt == null) {
      try {
        final dateOnly = s.split('T').first;
        dt = DateTime.tryParse(dateOnly);
      } catch (_) {
        dt = null;
      }
    }
    if (dt == null) return s;
    final monthName = _getMonthName(dt.month);
    return '${dt.day.toString().padLeft(2, '0')} $monthName ${dt.year}';
  }

  String _getDayNameFromRaw(dynamic raw) {
    if (raw == null) return '';
    final s = raw.toString();
    DateTime? dt = DateTime.tryParse(s);
    if (dt == null) {
      try {
        final dateOnly = s.split('T').first;
        dt = DateTime.tryParse(dateOnly);
      } catch (_) {
        dt = null;
      }
    }
    if (dt == null) return '';
    return _getDayName(dt.weekday);
  }

  String _getDayName(int weekday) {
    const days = [
      'Minggu',
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu'
    ];
    if (weekday < 1 || weekday > 7) return '';
    return days[weekday % 7];
  }

  String _getMonthName(int month) {
    const months = [
      '',
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];
    if (month < 1 || month > 12) return '';
    return months[month];
  }

  Future<void> _selectDate() async {
    final picked = await showModalBottomSheet<DateTime?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Wrap(
            children: [
              CustomCalendarWidget(
                initialDate: selectedDate ?? DateTime.now(),
                selectedDate: selectedDate,
                disablePast: true,
              ),
            ],
          ),
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _searchAvailableRides() async {
    if (selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon pilih tanggal terlebih dahulu')),
      );
      return;
    }

    // If booking is barang or titip, validate barang fields
    final bookingType =
        (widget.booking['booking_type'] ?? '').toString().toLowerCase();
    if (bookingType == 'barang' || bookingType == 'titip') {
      if ((_selectedBarangSize ?? '').isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih ukuran barang terlebih dahulu')),
        );
        return;
      }
      if (_barangDescriptionController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Isi keterangan barang terlebih dahulu')),
        );
        return;
      }
    }

    setState(() {
      isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');

      if (token == null || token.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Silakan login untuk mengubah jadwal')),
        );
        return;
      }

      final bookingId = widget.booking['id'];
      final bookingType =
          (widget.booking['booking_type'] ?? 'mobil').toString();

      final available = await ApiService.fetchAvailableRides(
          bookingId, bookingType,
          date:
              '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}');

      setState(() {
        isLoading = false;
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => UbahJadwalListPage(
            booking: widget.booking,
            availableRides: available,
            selectedDate: selectedDate!,
            barangImagePath: _barangImagePath,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ride = widget.booking['ride'] ?? {};
    final bookingType =
        (widget.booking['booking_type'] ?? '').toString().toLowerCase();

    String origin = '';
    String destination = '';
    String departureTime = _formatRideTime(ride['departure_time'] ??
        ride['departure_datetime'] ??
        ride['departure_date']);
    String arrivalTime = _formatRideTime(ride['arrival_time'] ??
        ride['arrival_datetime'] ??
        ride['arrival_date']);
    String departureDate =
        _formatRideDate(ride['departure_date'] ?? ride['departure_datetime']);
    String arrivalDate =
        _formatRideDate(ride['arrival_date'] ?? ride['arrival_datetime']);

    if (ride['origin_location'] is Map && ride['origin_location'] != null) {
      origin = ride['origin_location']['name'] ?? '';
    }
    if (ride['destination_location'] is Map &&
        ride['destination_location'] != null) {
      destination = ride['destination_location']['name'] ?? '';
    }

    String vehicle = '';
    String plate = '';
    if (ride['kendaraan_mitra'] is Map && ride['kendaraan_mitra'] != null) {
      final kendaraan = ride['kendaraan_mitra'];
      vehicle = (kendaraan['brand'] ?? '') + ' ' + (kendaraan['model'] ?? '');
      vehicle = vehicle.trim();
      if (vehicle.isEmpty) {
        vehicle = kendaraan['name'] ??
            (bookingType == 'motor' ? 'Yamaha NMAX' : 'Mobil Avanza');
      }
      plate = kendaraan['plate_number'] ?? 'B 5678 ABC';
    } else {
      vehicle = bookingType == 'motor' ? 'Yamaha NMAX' : 'Mobil Avanza';
      plate = 'B 5678 ABC';
    }

    String title = 'Nebeng Mobil';
    if (bookingType == 'motor') {
      title = 'Nebeng Motor';
    } else if (bookingType == 'barang') {
      title = 'Nebeng Barang';
    } else if (bookingType == 'titip') {
      title = 'Titip Barang';
    }

    final bookingNumber =
        widget.booking['booking_number']?.toString() ?? 'FR-1768365708-295';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Ubah Jadwal',
          style: TextStyle(
            color: Colors.black,
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
            // Header Section dengan background putih
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'NEBENG',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E3A8A),
                      letterSpacing: 0.5,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Kode Pemesanan',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        bookingNumber,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Label Jadwal Saat Ini
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Jadwal Saat Ini',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Informasi perjalanan yang sedang aktif',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Card Jadwal Saat Ini
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: const BoxDecoration(
                              color: Color(0xFF1E40AF),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              bookingType == 'motor'
                                  ? Icons.two_wheeler
                                  : Icons.directions_car,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$vehicle  •  $plate',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Route Information
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // Info Box - Durasi & Jarak
                          // Container(
                          //   padding: const EdgeInsets.all(12),
                          //   margin: const EdgeInsets.only(bottom: 16),
                          //   decoration: BoxDecoration(
                          //     color: const Color(0xFFF0F9FF),
                          //     borderRadius: BorderRadius.circular(8),
                          //     border: Border.all(
                          //       color: const Color(0xFFBAE6FD),
                          //       width: 1,
                          //     ),
                          //   ),
                          // child: Row(
                          //   children: [
                          //     Icon(
                          //       Icons.info_outline,
                          //       size: 18,
                          //       color: const Color(0xFF0284C7),
                          //     ),
                          //     const SizedBox(width: 8),
                          //     Expanded(
                          //       child: Text(
                          //         'Perjalanan ini akan memakan waktu sekitar 3-4 jam',
                          //         style: TextStyle(
                          //           fontSize: 12,
                          //           color: const Color(0xFF0C4A6E),
                          //           fontWeight: FontWeight.w500,
                          //         ),
                          //       ),
                          //     ),
                          //   ],
                          // ),
                          // ),

                          // Departure
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(top: 6),
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
                                    Row(
                                      children: [
                                        Text(
                                          departureTime,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.black,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            origin.isNotEmpty
                                                ? origin
                                                : 'Jakarta Pos 1',
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${_getDayNameFromRaw(ride['departure_date'] ?? ride['departure_datetime'])}, $departureDate',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFD1FAE5),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'Titik Keberangkatan',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF059669),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          // Connecting Line
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 3.5, top: 8, bottom: 8),
                            child: Container(
                              width: 1,
                              height: 32,
                              color: Colors.grey[300],
                            ),
                          ),

                          // Arrival
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(top: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          arrivalTime,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.black,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            destination.isNotEmpty
                                                ? destination
                                                : 'Bandung Pos 1',
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${_getDayNameFromRaw(ride['arrival_date'] ?? ride['arrival_datetime'])}, $arrivalDate',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEE2E2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'Titik Tujuan',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFFDC2626),
                                        ),
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
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Section Pilih Tanggal Baru
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pilih Tanggal Baru',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Cari jadwal yang tersedia untuk tanggal yang Anda pilih',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _selectDate,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFF1E40AF), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1E40AF).withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            color: Color(0xFF1E40AF),
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _formatDisplayDate(selectedDate),
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.black,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Colors.grey[400],
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // If booking is barang or titip, show barang-specific form (wrapped with horizontal padding)
            if (bookingType == 'barang' || bookingType == 'titip') ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    const Text(
                      'Ukuran Barang',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final picked = await showModalBottomSheet<String>(
                          context: context,
                          backgroundColor: Colors.transparent,
                          isScrollControlled: true,
                          builder: (ctx) {
                            return DraggableScrollableSheet(
                              initialChildSize: 0.5,
                              minChildSize: 0.3,
                              maxChildSize: 0.9,
                              builder: (_, controller) {
                                return Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(16)),
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Center(
                                        child: Container(
                                          width: 40,
                                          height: 4,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[300],
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'Pilih Kapasitas Bagasi',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Expanded(
                                        child: ListView.separated(
                                          controller: controller,
                                          itemCount: _barangSizes.length,
                                          separatorBuilder: (_, __) =>
                                              const SizedBox(height: 12),
                                          itemBuilder: (context, idx) {
                                            final key = _barangSizes[idx];
                                            final desc =
                                                _barangSizeDescriptions[key] ??
                                                    '';
                                            return InkWell(
                                              onTap: () =>
                                                  Navigator.of(ctx).pop(key),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 14),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[50],
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      width: 40,
                                                      height: 40,
                                                      decoration: BoxDecoration(
                                                        color: const Color(
                                                            0xFF1E40AF),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                      ),
                                                      child: const Icon(
                                                          Icons.card_travel,
                                                          color: Colors.white),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Text(
                                                        '$key - $desc',
                                                        style: const TextStyle(
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w600),
                                                      ),
                                                    ),
                                                    if (_selectedBarangSize ==
                                                        key)
                                                      const Icon(Icons.check,
                                                          color: Color(
                                                              0xFF1E40AF)),
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
                              },
                            );
                          },
                        );

                        if (picked != null) {
                          setState(() {
                            _selectedBarangSize = picked;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _selectedBarangSize == null
                                    ? 'Pilih ukuran barang anda'
                                    : '$_selectedBarangSize - ${_barangSizeDescriptions[_selectedBarangSize] ?? ''}',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: _selectedBarangSize == null
                                      ? Colors.grey[600]
                                      : Colors.black,
                                  fontWeight: _selectedBarangSize == null
                                      ? FontWeight.w400
                                      : FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_drop_down,
                                color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Keterangan Barang',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: TextField(
                        controller: _barangDescriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'contoh: berisi dokumen',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Foto Barang',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _pickImage,
                      child: Container(
                        height: 120,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: _barangImagePath == null
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.image,
                                        size: 36, color: Colors.grey),
                                    SizedBox(height: 8),
                                    Text('Unggah foto barang',
                                        style: TextStyle(color: Colors.grey)),
                                  ],
                                ),
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  File(_barangImagePath!),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: 120,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Data Penerima section (only for barang/titip)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.person_rounded,
                                  color: Color(0xFF1E40AF)),
                              const SizedBox(width: 8),
                              const Text(
                                'Data Penerima',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          InkWell(
                            onTap: _showPenerimaPicker,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey.withOpacity(0.15),
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 16),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _dataPenerima ?? 'Data Penerima',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: _dataPenerima == null
                                            ? Colors.grey[400]
                                            : Colors.black87,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.edit_outlined,
                                    color: Colors.grey[400],
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: isLoading ? null : _searchAvailableRides,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E40AF),
              disabledBackgroundColor: const Color(0xFF1E40AF).withOpacity(0.5),
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
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    (bookingType == 'barang' || bookingType == 'titip')
                        ? 'Ubah Jadwal'
                        : 'Cari Jadwal Tersedia',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _barangDescriptionController.dispose();
    _penerimaController.dispose();
    super.dispose();
  }
}
