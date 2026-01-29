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
        // If mitra chooses cargo-only or cargo+tebengan, jumlah bagasi is fixed to 1
        if (_serviceType == 'barang' || _serviceType == 'both') {
          _jumlahBagasi = 1;
        } else {
          // reset to null for pure tebengan so mitra can choose
          _jumlahBagasi = null;
        }
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

    final selected = await showModalBottomSheet<Map<String, dynamic>?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: SafeArea(
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
              // Title
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Pilih Kendaraan Mitra',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.black54),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Content
              if (vehicles.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Icon(Icons.directions_bike_outlined,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Belum ada kendaraan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tambah kendaraan terlebih dahulu',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              if (vehicles.isNotEmpty)
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: vehicles.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final v = vehicles[index];
                      final isSelected = _selectedKendaraanMitraId == v['id'];
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedKendaraanMitraId = v['id'];
                          });
                          Navigator.of(context).pop(v);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFF1E40AF).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.motorcycle,
                                  color: Color(0xFF1E40AF),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      v['name'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      v['plate_number'] ?? '',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle,
                                  color: Color(0xFF1E40AF),
                                  size: 24,
                                )
                              else
                                Icon(
                                  Icons.circle_outlined,
                                  color: Colors.grey[400],
                                  size: 24,
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
    final isEditable = _serviceType == 'tebengan';

    return InkWell(
      onTap: isEditable ? _selectJumlahBagasi : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.black26,
            width: 1.2,
          ),
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
                          fontSize: 15,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(
                    _jumlahBagasi != null
                        ? '${_jumlahBagasi.toString()} buah'
                        : (isEditable
                            ? 'Belum ditentukan'
                            : '1 buah (otomatis)'),
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isEditable)
              const Icon(Icons.chevron_right, color: Colors.grey)
            else
              const SizedBox.shrink(),
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
          jumlahBagasi: _jumlahBagasi,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon == Icons.arrow_upward
                        ? Icons.trip_origin
                        : Icons.location_on,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (subtitle != null && subtitle.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const SizedBox(width: 56),
                Expanded(
                  child: Container(
                    height: 1,
                    color: Colors.grey[300],
                  ),
                ),
              ],
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
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.black26,
            width: 1.2,
          ),
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
              child: Text(
                subtitle != null && subtitle.isNotEmpty ? subtitle : title,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                  fontWeight: FontWeight.w400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.black26,
            width: 1.2,
          ),
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
                          fontSize: 15,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(
                    _vehicleNameController.text.isNotEmpty
                        ? '${_vehicleNameController.text} • ${_vehiclePlateController.text}'
                        : 'Belum memilih kendaraan',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
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

  Widget _buildDisabledInfoCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor.withOpacity(0.8), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500),
                ),
                if (subtitle != null && subtitle.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Seats selection removed for motor: seats fixed to 1

  Widget _buildPriceField() {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.black26,
            width: 1.2,
          ),
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
                          fontSize: 15,
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
            // Lokasi Card dengan 2 item
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.black26,
                  width: 1.2,
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildLocationItem(
                    icon: Icons.trip_origin,
                    iconColor: const Color(0xFF4CAF50),
                    title: 'Lokasi Awal',
                    subtitle: _originLocationName.isNotEmpty
                        ? _originLocationName
                        : null,
                    onTap: () => _selectLocation(true),
                  ),
                  const SizedBox(height: 16),
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
                  const SizedBox(height: 20),
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
              subtitle: _getServiceTypeLabel(),
              onTap: _selectServiceType,
            ),

            const SizedBox(height: 12),

            // Render service-specific rows
            if (_serviceType == 'tebengan') ...[
              // For Hanya Tebengan we only show the seats form (no extra label card)
              _buildSeatsCard(),
              const SizedBox(height: 12),
            ],

            if (_serviceType == 'both') ...[
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
              _buildSeatsCard(),
              const SizedBox(height: 12),
            ],

            if (_serviceType == 'barang') ...[
              // For 'barang' we only show bagasi selection (no repeated label)
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

  // Non-interactive seats card: seats fixed to 1 for motor rides
  Widget _buildSeatsCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.black26,
          width: 1.2,
        ),
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
              children: const [
                Text('Jumlah Kursi',
                    style: TextStyle(
                        fontSize: 15,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500)),
                SizedBox(height: 4),
                Text(
                  '1 kursi',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}
