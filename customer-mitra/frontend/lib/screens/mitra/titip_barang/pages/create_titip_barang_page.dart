import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../services/api_service.dart';
import '../../create_tebengan_motor/widgets/time_picker_modal.dart';
import '../../create_tebengan_motor/widgets/bagasi_selector_dialog.dart';
import '../../../../widgets/custom_calendar_widget.dart';
import '../../create_tebengan_motor/pages/location_picker_page.dart';
import '../widgets/location_section.dart';
import '../widgets/selection_card.dart';
import '../widgets/transportation_dialog.dart';
import '../utils/helpers.dart';
import 'detail_titip_barang_page.dart';

class CreateTitipBarangPage extends StatefulWidget {
  const CreateTitipBarangPage({Key? key}) : super(key: key);

  @override
  State<CreateTitipBarangPage> createState() => _CreateTitipBarangPageState();
}

class _CreateTitipBarangPageState extends State<CreateTitipBarangPage> {
  int? _originLocationId;
  String _originLocationName = '';
  int? _destinationLocationId;
  String _destinationLocationName = '';
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  int? _selectedBagasiCapacity;
  String _selectedTransportation = '';
  int? _jumlahBagasi;
  final _priceController = TextEditingController();

  @override
  void dispose() {
    _priceController.dispose();
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
      _showLocationErrorDialog(e);
    }
  }

  Future<void> _showLocationErrorDialog(Object error) async {
    final retry = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gagal Memuat Lokasi'),
        content: Text(
            'Terjadi kesalahan: ${error.toString()}\n\nGunakan data sample?'),
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
      _useSampleLocations();
    }
  }

  Future<void> _useSampleLocations() async {
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
        'address': 'Lemo, Kec. Kabupaten Tangerang, Kabupaten Tangerang, Banten'
      },
    ];

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerPage(
          title: 'Pilih Kota atau Pos',
          daftarLokasi: List<Map<String, dynamic>>.from(daftar),
          onLocationSelected: (selected) {
            setState(() {
              _originLocationId = selected['id'];
              _originLocationName = selected['name'];
            });
          },
        ),
      ),
    );
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
      setState(() => _selectedTime = picked);
    }
  }

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
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                      textStyle: const TextStyle(fontSize: 14),
                    ),
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

  Future<void> _selectTransportation() async {
    final selected = await TransportationDialog.show(
      context,
      currentSelection: _selectedTransportation,
    );

    if (selected != null && mounted) {
      setState(() => _selectedTransportation = selected);
    }
  }

  Future<void> _handleSubmit() async {
    if (_originLocationId == null ||
        _destinationLocationId == null ||
        _selectedDate == null ||
        _selectedTime == null ||
        _selectedBagasiCapacity == null ||
        _selectedTransportation.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon lengkapi semua data')),
      );
      return;
    }

    if (_priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon masukkan harga')),
      );
      return;
    }

    final price = double.tryParse(_priceController.text);
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harga tidak valid')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailTitipBarangPage(
          originLocationId: _originLocationId!,
          originLocationName: _originLocationName,
          destinationLocationId: _destinationLocationId!,
          destinationLocationName: _destinationLocationName,
          departureDate: _selectedDate!,
          departureTime: _selectedTime!,
          transportationType: _selectedTransportation,
          bagasiCapacity: _selectedBagasiCapacity!,
          jumlahBagasi: _jumlahBagasi,
          price: price,
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
            // Location Section
            LocationSection(
              originLocationName: _originLocationName,
              destinationLocationName: _destinationLocationName,
              onOriginTap: () => _selectLocation(true),
              onDestinationTap: () => _selectLocation(false),
            ),

            const SizedBox(height: 12),

            // Date Card
            TitipBarangSelectionCard(
              icon: Icons.calendar_today,
              iconColor: const Color(0xFF1E40AF),
              title: 'Tanggal keberangkatan',
              subtitle: _selectedDate != null
                  ? TitipBarangHelpers.formatDate(_selectedDate!)
                  : null,
              onTap: _selectDate,
            ),

            const SizedBox(height: 12),

            // Time Card
            TitipBarangSelectionCard(
              icon: Icons.access_time,
              iconColor: const Color(0xFF1E40AF),
              title: 'Jam keberangkatan',
              subtitle: _selectedTime != null
                  ? TitipBarangHelpers.formatTime(_selectedTime!)
                  : null,
              onTap: _selectTime,
            ),

            const SizedBox(height: 12),

            // Bagasi Card
            TitipBarangSelectionCard(
              icon: Icons.luggage,
              iconColor: const Color(0xFF1E40AF),
              title: 'Kapasitas Bagasi',
              subtitle:
                  TitipBarangHelpers.getBagasiLabel(_selectedBagasiCapacity),
              onTap: _selectBagasiCapacity,
            ),

            const SizedBox(height: 12),

            // Transportation Card
            TitipBarangSelectionCard(
              icon: Icons.directions_bus,
              iconColor: const Color(0xFF1E40AF),
              title: 'Transportasi',
              subtitle: TitipBarangHelpers.getTransportationLabel(
                  _selectedTransportation),
              onTap: _selectTransportation,
            ),

            const SizedBox(height: 12),

            // Jumlah Bagasi Card
            InkWell(
              onTap: _selectJumlahBagasi,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                      child: const Icon(Icons.backpack,
                          color: Colors.grey, size: 20),
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
                                : 'Belum ditentukan',
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Price Field
            Container(
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
                    decoration: const BoxDecoration(
                      color: Color(0xFF1E40AF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.attach_money,
                        color: Colors.white, size: 20),
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
              onPressed: _handleSubmit,
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
