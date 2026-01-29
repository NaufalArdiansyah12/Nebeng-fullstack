import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../services/api_service.dart';
import '../../../../widgets/custom_calendar_widget.dart';
import '../../create_tebengan_motor/widgets/time_picker_modal.dart';
import '../../create_tebengan_motor/widgets/service_type_selector.dart';
import '../../create_tebengan_motor/widgets/bagasi_selector_dialog.dart';
import '../../create_tebengan_motor/pages/location_picker_page.dart';
import '../../create_tebengan_motor/pages/detail_ride_page.dart';
import '../widgets/mobil_location_section.dart';
import '../widgets/mobil_selection_card.dart';
import '../widgets/mobil_vehicle_widgets.dart';
import '../utils/mobil_helpers.dart';

class CreateCarRidePage extends StatefulWidget {
  const CreateCarRidePage({Key? key}) : super(key: key);

  @override
  State<CreateCarRidePage> createState() => _CreateCarRidePageState();
}

class _CreateCarRidePageState extends State<CreateCarRidePage> {
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
  final _seatsController = TextEditingController(text: '4');
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
      // Filter to only show mobil vehicles for car ride creation
      vehicles = vehicles.where((v) {
        final vt = (v['vehicle_type'] ?? v['type'] ?? v['vehicleType'])
            ?.toString()
            .toLowerCase();
        return vt == 'mobil' || vt == 'car';
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
      _seatsController.text = (selected['seats'] ?? 4).toString();
      _selectedKendaraanMitraId = selected['id'] as int?;
      setState(() {});
    }
  }

  Future<void> _selectSeats() async {
    final controller = TextEditingController(text: _seatsController.text);
    final result = await showDialog<int?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Jumlah Kursi'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'Masukkan jumlah kursi'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final v = int.tryParse(controller.text) ??
                  int.tryParse(_seatsController.text) ??
                  4;
              Navigator.of(context).pop(v);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      _seatsController.text = result.toString();
      setState(() {});
    }
  }

  Widget _buildSeatsCard() {
    return InkWell(
      onTap: _selectSeats,
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
                color: Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.event_seat, color: Colors.grey, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Jumlah Kursi',
                      style: TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  Text(
                    '${_seatsController.text} kursi',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  int? _selectedBagasiCapacity;
  int? _jumlahBagasi;

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

  Future<void> _selectJumlahBagasi() async {
    final controller =
        TextEditingController(text: _jumlahBagasi?.toString() ?? '');
    final result = await showDialog<int?>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(18.0),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F9FC),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Jumlah Bagasi',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Masukkan jumlah bagasi',
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    style:
                        TextButton.styleFrom(foregroundColor: Colors.grey[700]),
                    onPressed: () => Navigator.of(context).pop(null),
                    child: const Text('Batal'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E40AF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      minimumSize: const Size(92, 40),
                      elevation: 2,
                    ),
                    onPressed: () {
                      final v = int.tryParse(controller.text) ?? 0;
                      Navigator.of(context).pop(v);
                    },
                    child: const Text('Simpan',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() => _jumlahBagasi = result);
    }
  }

  Widget _buildJumlahBagasiCard() {
    return InkWell(
      onTap: _selectJumlahBagasi,
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
                color: Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.backpack, color: Colors.grey, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Jumlah Bagasi',
                      style: TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  Text(
                    _jumlahBagasi != null
                        ? '${_jumlahBagasi.toString()} buah'
                        : 'Belum ditentukan',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
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
          rideType: 'mobil',
          vehicleName: _vehicleNameController.text,
          vehiclePlate: _vehiclePlateController.text,
          vehicleBrand: _vehicleBrandController.text,
          vehicleType: _vehicleTypeController.text,
          vehicleColor: _vehicleColorController.text,
          kendaraanMitraId: _selectedKendaraanMitraId,
          price: double.tryParse(_priceController.text) ?? 0,
          availableSeats: int.tryParse(_seatsController.text) ?? 4,
          bagasiCapacity: _selectedBagasiCapacity,
          jumlahBagasi: _jumlahBagasi,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
            MobilLocationSection(
              originLocationName: _originLocationName,
              destinationLocationName: _destinationLocationName,
              onOriginTap: () => _selectLocation(true),
              onDestinationTap: () => _selectLocation(false),
            ),
            const SizedBox(height: 12),
            MobilSelectionCard(
              icon: Icons.calendar_today,
              iconColor: const Color(0xFF1E40AF),
              title: 'Tanggal Keberangkatan',
              subtitle: _selectedDate != null
                  ? MobilHelpers.formatDate(_selectedDate!)
                  : null,
              onTap: _selectDate,
            ),
            const SizedBox(height: 12),
            MobilSelectionCard(
              icon: Icons.access_time,
              iconColor: const Color(0xFF1E40AF),
              title: 'Jam Keberangkatan',
              subtitle: _selectedTime != null
                  ? MobilHelpers.formatTime(_selectedTime!)
                  : null,
              onTap: _selectTime,
            ),
            const SizedBox(height: 12),
            MobilSelectionCard(
              icon: Icons.airport_shuttle,
              iconColor: const Color(0xFF1E40AF),
              title: 'Pilih Tebengan',
              subtitle: MobilHelpers.getServiceTypeLabel(_serviceType),
              onTap: _selectServiceType,
            ),
            const SizedBox(height: 12),
            if (_serviceType == 'barang' || _serviceType == 'both') ...[
              MobilSelectionCard(
                icon: Icons.luggage,
                iconColor: const Color(0xFF1E40AF),
                title: 'Kapasitas Bagasi',
                subtitle: MobilHelpers.getBagasiLabel(_selectedBagasiCapacity),
                onTap: _selectBagasiCapacity,
              ),
              const SizedBox(height: 12),
              _buildJumlahBagasiCard(),
              const SizedBox(height: 12),
            ],
            if (_serviceType == 'tebengan' || _serviceType == 'both') ...[
              _buildSeatsCard(),
              const SizedBox(height: 12),
            ],
            MobilVehicleCard(
              vehicleName: _vehicleNameController.text,
              vehiclePlate: _vehiclePlateController.text,
              onTap: _showVehicleDetailsDialog,
            ),
            const SizedBox(height: 12),
            MobilPriceField(controller: _priceController),
            const SizedBox(height: 24),
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
