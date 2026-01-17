import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../services/api_service.dart';
import '../../../../widgets/custom_calendar_widget.dart';
import '../widgets/time_picker_modal.dart';
import '../widgets/service_type_selector.dart';
import '../widgets/bagasi_selector_dialog.dart';
import 'location_picker_page.dart';
import 'detail_ride_page.dart';

class CreateRidePage extends StatefulWidget {
  const CreateRidePage({Key? key}) : super(key: key);

  @override
  State<CreateRidePage> createState() => _CreateRidePageState();
}

class _CreateRidePageState extends State<CreateRidePage> {
  int? _originLocationId;
  String _originLocationName = '';
  int? _destinationLocationId;
  String _destinationLocationName = '';
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _serviceType = 'tebengan';

  final _vehicleNameController = TextEditingController();
  final _vehiclePlateController = TextEditingController();
  final _vehicleBrandController = TextEditingController();
  final _vehicleTypeController = TextEditingController();
  final _vehicleColorController = TextEditingController();
  final _priceController = TextEditingController();
  final _seatsController = TextEditingController(text: '1');
  int? _selectedKendaraanMitraId;

  @override
  void dispose() {
    _vehicleNameController.dispose();
    _vehiclePlateController.dispose();
    _vehicleBrandController.dispose();
    _vehicleTypeController.dispose();
    _vehicleColorController.dispose();
    _priceController.dispose();
    _seatsController.dispose();
    super.dispose();
  }

  Future<void> _selectLocation(bool isOrigin) async {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final raw = await ApiService.fetchLocations();
      final daftar = raw
          .map((e) => {
                'id': e['id'],
                'name': e['name']?.toString() ?? '',
                'address': (e['address'] ?? e['city'] ?? '').toString(),
              })
          .toList();

      Navigator.pop(context);

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LocationPickerPage(
            title:
                isOrigin ? 'Pilih Kota atau Pos Awal' : 'Pilih Kota atau Pos',
            daftarLokasi: List<Map<String, dynamic>>.from(daftar),
            onLocationSelected: (selected) {
              setState(() {
                if (isOrigin) {
                  _originLocationId = selected['id'];
                  _originLocationName = selected['name'];
                } else {
                  _destinationLocationId = selected['id'];
                  _destinationLocationName = selected['name'];
                }
              });
            },
          ),
        ),
      );
    } catch (e) {
      Navigator.pop(context);

      if (!mounted) return;

      final retry = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Gagal Memuat Lokasi'),
          content: Text(
              'Terjadi kesalahan: ${e.toString()}\n\nGunakan data sample?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Gunakan Sample'),
            ),
          ],
        ),
      );

      if (retry == true && mounted) {
        final daftar = [
          {
            'id': 1,
            'name': 'Terminal Blok M - Jakarta',
            'address':
                'Jl. Sisingamangaraja, RT.10/RW.1, Melawai, Kec. Kby. Baru, Kota Jakarta Selatan'
          },
          {
            'id': 2,
            'name': 'Stasiun Gambir - Jakarta',
            'address':
                'Jl. Medan Merdeka Tim., Gambir, Kecamatan Gambir, Kota Jakarta Pusat'
          },
          {
            'id': 3,
            'name': 'Stasiun Bandung - Bandung',
            'address':
                'Jl. Kebon Kawung No.43, Babakan Ciamis, Kec. Sumur Bandung, Kota Bandung'
          },
          {
            'id': 4,
            'name': 'PIK 2',
            'address':
                'Lemo, Kec. Kabupaten Tangerang, Kabupaten Tangerang, Banten'
          },
        ];

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LocationPickerPage(
              title:
                  isOrigin ? 'Pilih Kota atau Pos Awal' : 'Pilih Kota atau Pos',
              daftarLokasi: List<Map<String, dynamic>>.from(daftar),
              onLocationSelected: (selected) {
                setState(() {
                  if (isOrigin) {
                    _originLocationId = selected['id'];
                    _originLocationName = selected['name'];
                  } else {
                    _destinationLocationId = selected['id'];
                    _destinationLocationName = selected['name'];
                  }
                });
              },
            ),
          ),
        );
      }
    }
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
                initialDate: _selectedDate ?? DateTime.now(),
                selectedDate: _selectedDate,
                disablePast: true,
              ),
            ],
          ),
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final picked = await showModalBottomSheet<TimeOfDay>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => TimePickerModal(initialTime: _selectedTime),
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _selectServiceType() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) =>
          ServiceTypeSelector(currentServiceType: _serviceType),
    );

    if (selected != null) {
      setState(() {
        _serviceType = selected;
      });
    }
  }

  Future<void> _showVehicleDetailsDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('api_token') ?? '';

    List<Map<String, dynamic>> vehicles = [];
    try {
      vehicles = await ApiService.fetchVehicles(token: token);
      // Filter to only show motor vehicles for motor ride creation
      vehicles = vehicles.where((v) {
        final vt = (v['vehicle_type'] ?? v['type'] ?? v['vehicleType'])
            ?.toString()
            .toLowerCase();
        return vt == 'motor';
      }).toList();
    } catch (_) {
      vehicles = [];
    }

    final selected = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Pilih Kendaraan Mitra',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              if (vehicles.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                      'Belum ada kendaraan. Tambah kendaraan terlebih dahulu.'),
                ),
              if (vehicles.isNotEmpty)
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: vehicles.map((v) {
                        return RadioListTile<int>(
                          title: Text(v['name'] ?? ''),
                          subtitle: Text(v['plate_number'] ?? ''),
                          value: v['id'] as int,
                          groupValue: _selectedKendaraanMitraId,
                          onChanged: (val) {
                            setState(() {
                              _selectedKendaraanMitraId = val;
                            });
                            Navigator.of(context).pop(v);
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop(null);
                          Navigator.pushNamed(context, '/mitra/vehicles/add');
                        },
                        child: const Text('Tambah Kendaraan'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(null);
                      },
                      child: const Text('Batal'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (selected != null) {
      _vehicleNameController.text = selected['name'] ?? '';
      _vehiclePlateController.text = selected['plate_number'] ?? '';
      _vehicleBrandController.text = selected['brand'] ?? '';
      _vehicleTypeController.text = selected['model'] ?? '';
      _vehicleColorController.text = selected['color'] ?? '';
      _seatsController.text = (selected['seats'] ?? 1).toString();
      _selectedKendaraanMitraId = selected['id'] as int?;
      setState(() {});
    }
  }

  String _getServiceTypeLabel() {
    switch (_serviceType) {
      case 'tebengan':
        return 'Hanya Tebengan';
      case 'barang':
        return 'Hanya Titip Barang';
      case 'both':
        return 'Barang dan Tebengan';
      default:
        return 'Pilih Jenis Layanan';
    }
  }

  int? _selectedBagasiCapacity;

  Future<void> _selectBagasiCapacity() async {
    final selected = await showDialog<int?>(
      context: context,
      builder: (context) =>
          BagasiSelectorDialog(currentCapacity: _selectedBagasiCapacity),
    );
    if (selected != null && mounted) {
      setState(() => _selectedBagasiCapacity = selected);
    }
  }

  Future<void> _goToDetailPage() async {
    if (_originLocationId == null ||
        _destinationLocationId == null ||
        _selectedDate == null ||
        _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon lengkapi semua data')),
      );
      return;
    }

    if (_vehicleNameController.text.isEmpty ||
        _vehiclePlateController.text.isEmpty ||
        _vehicleBrandController.text.isEmpty ||
        _vehicleTypeController.text.isEmpty ||
        _vehicleColorController.text.isEmpty ||
        _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Mohon lengkapi detail kendaraan dan tarif')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailRidePage(
          originLocationId: _originLocationId!,
          originLocationName: _originLocationName,
          destinationLocationId: _destinationLocationId!,
          destinationLocationName: _destinationLocationName,
          departureDate: _selectedDate!,
          departureTime: _selectedTime!,
          serviceType: _serviceType,
          rideType: 'motor',
          vehicleName: _vehicleNameController.text,
          vehiclePlate: _vehiclePlateController.text,
          vehicleBrand: _vehicleBrandController.text,
          vehicleType: _vehicleTypeController.text,
          vehicleColor: _vehicleColorController.text,
          kendaraanMitraId: _selectedKendaraanMitraId,
          price: double.tryParse(_priceController.text) ?? 0,
          availableSeats: int.tryParse(_seatsController.text) ?? 1,
          bagasiCapacity: _selectedBagasiCapacity,
        ),
      ),
    );
  }

  Widget _buildLocationItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: iconColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null && subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null && subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleCard() {
    return InkWell(
      onTap: _showVehicleDetailsDialog,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF1E40AF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.directions_bike,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Kendaraan',
                      style: TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(
                    _vehicleNameController.text.isNotEmpty
                        ? '${_vehicleNameController.text} • ${_vehiclePlateController.text}'
                        : 'Belum memilih kendaraan',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _showVehicleDetailsDialog,
              child: const Text('Pilih Kendaraan'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceField() {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 4,
                offset: const Offset(0, 1)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF1E40AF),
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.attach_money, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Nominal (Rp)',
                      style: TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Rp',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          decoration: const InputDecoration(
                            hintText: 'Masukkan nominal',
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 0, vertical: 8),
                          ),
                          style: const TextStyle(fontSize: 14),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E40AF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Tambah Tebengan',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Lokasi Card dengan 2 item
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  _buildLocationItem(
                    icon: Icons.arrow_upward,
                    iconColor: const Color(0xFF4CAF50),
                    title: 'Lokasi Awal',
                    subtitle: _originLocationName.isNotEmpty
                        ? _originLocationName
                        : null,
                    onTap: () => _selectLocation(true),
                  ),
                  // Garis pemisah horizontal dan vertikal
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      children: [
                        const SizedBox(width: 40), // Posisi center dari icon
                        Container(
                          width: 2,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                        const SizedBox(width: 36),
                        Expanded(
                          child: Container(
                            height: 1,
                            color: Colors.grey[300],
                          ),
                        ),
                        const SizedBox(width: 20),
                      ],
                    ),
                  ),
                  _buildLocationItem(
                    icon: Icons.location_on,
                    iconColor: const Color(0xFFFF9800),
                    title: 'Lokasi Tujuan',
                    subtitle: _destinationLocationName.isNotEmpty
                        ? _destinationLocationName
                        : null,
                    onTap: () => _selectLocation(false),
                    isLast: true,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Tanggal Card
            _buildSelectionCard(
              icon: Icons.calendar_today,
              iconColor: const Color(0xFF1E40AF),
              title: 'Tanggal Keberangkatan',
              subtitle: _selectedDate != null
                  ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                  : null,
              onTap: _selectDate,
            ),

            const SizedBox(height: 12),

            // Jam Card
            _buildSelectionCard(
              icon: Icons.access_time,
              iconColor: const Color(0xFF1E40AF),
              title: 'Jam Keberangkatan',
              subtitle: _selectedTime != null
                  ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                  : null,
              onTap: _selectTime,
            ),

            const SizedBox(height: 12),

            // Pilih Tebengan Card
            _buildSelectionCard(
              icon: Icons.airport_shuttle,
              iconColor: const Color(0xFF1E40AF),
              title: 'Pilih Tebengan',
              subtitle:
                  _serviceType != 'tebengan' ? _getServiceTypeLabel() : null,
              onTap: _selectServiceType,
            ),

            const SizedBox(height: 12),

            if (_serviceType == 'barang') ...[
              _buildSelectionCard(
                icon: Icons.luggage,
                iconColor: const Color(0xFF1E40AF),
                title: 'Kapasitas Bagasi',
                subtitle: _selectedBagasiCapacity != null
                    ? (_selectedBagasiCapacity == 5
                        ? 'Kecil - Maksimal 5 kg'
                        : _selectedBagasiCapacity == 10
                            ? 'Sedang - Maksimal 10 kg'
                            : 'Besar - Maksimal 20 kg')
                    : null,
                onTap: _selectBagasiCapacity,
              ),
              const SizedBox(height: 12),
            ],

            const SizedBox(height: 12),
            _buildVehicleCard(),
            const SizedBox(height: 12),
            _buildPriceField(),
            const SizedBox(height: 24),

            // Button Selanjutnya - Fixed at bottom
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
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
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _goToDetailPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E40AF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Selanjutnya',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
