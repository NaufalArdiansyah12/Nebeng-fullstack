import 'package:flutter/material.dart';
import 'nebeng_motor/data/location_data.dart';
import 'nebeng_motor/widgets/form_section.dart';
import 'nebeng_motor/widgets/history_section.dart';
import 'nebeng_motor/pages/location_picker_page.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_calendar_widget.dart';
import 'nebeng_motor/pages/trip_list_page.dart';
import 'nebeng_motor/utils/theme.dart';

class NebengMotorPage extends StatefulWidget {
  const NebengMotorPage({Key? key}) : super(key: key);

  @override
  State<NebengMotorPage> createState() => _NebengMotorPageState();
}

class _NebengMotorPageState extends State<NebengMotorPage> {
  String? lokasiAwal;
  String? lokasiAwalAddress;
  int? lokasiAwalId;
  String? lokasiTujuan;
  String? lokasiTujuanAddress;
  int? lokasiTujuanId;
  DateTime? tanggalKeberangkatan;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NebengMotorTheme.primaryBlue,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: NebengMotorTheme.backgroundColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      FormSection(
                        lokasiAwal: lokasiAwal,
                        lokasiAwalAddress: lokasiAwalAddress,
                        lokasiTujuan: lokasiTujuan,
                        lokasiTujuanAddress: lokasiTujuanAddress,
                        tanggalKeberangkatan: tanggalKeberangkatan,
                        onLokasiAwalTap: () => _showLocationPicker(true),
                        onLokasiTujuanTap: () => _showLocationPicker(false),
                        onTanggalTap: _showDatePicker,
                      ),
                      const SizedBox(height: 24),
                      HistorySection(
                        historiAlamat: LocationData.historiAlamat,
                        onHistoryTap: _showHistorySelectionDialog,
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomButton(),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      color: NebengMotorTheme.backgroundColor,
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _handleNextButton,
            style: ElevatedButton.styleFrom(
              backgroundColor: NebengMotorTheme.primaryBlue,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
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
    );
  }

  void _handleNextButton() {
    if (lokasiAwal != null &&
        lokasiTujuan != null &&
        tanggalKeberangkatan != null) {
      // Navigate to trip list page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TripListPage(
            lokasiAwal: lokasiAwal!,
            lokasiTujuan: lokasiTujuan!,
            tanggalKeberangkatan: tanggalKeberangkatan!,
            originLocationId: lokasiAwalId,
            destinationLocationId: lokasiTujuanId,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon lengkapi semua field'),
        ),
      );
    }
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.black, size: 20),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            'Nebeng Motor',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showLocationPicker(bool isStartLocation) async {
    // show loading while fetching
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final raw = await ApiService.fetchLocations();
      // map to expected format with ID
      final daftar = raw
          .map((e) => {
                'id': e['id'],
                'name': e['name']?.toString() ?? '',
                'address': (e['address'] ?? e['city'] ?? '').toString(),
              })
          .toList();
      Navigator.pop(context); // remove loading

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => LocationPickerPage(
            title: isStartLocation
                ? 'Pilih Kota atau Pos Awal'
                : 'Pilih Kota atau Pos',
            daftarLokasi: List<Map<String, dynamic>>.from(daftar),
            onLocationSelected: (location) {
              setState(() {
                if (isStartLocation) {
                  lokasiAwalId = location['id'] as int?;
                  lokasiAwal = location['name'];
                  lokasiAwalAddress = location['address'];
                } else {
                  lokasiTujuanId = location['id'] as int?;
                  lokasiTujuan = location['name'];
                  lokasiTujuanAddress = location['address'];
                }
              });
            },
          ),
        ),
      );
    } catch (e) {
      Navigator.pop(context); // remove loading
      final useSample = await _showFetchErrorDialog(e.toString());
      if (useSample) {
        final daftar = [
          {
            'id': 1,
            'name': 'Terminal Blok M - Jakarta',
            'address': 'Jl. Blok M No.1'
          },
          {
            'id': 2,
            'name': 'Stasiun Gambir - Jakarta',
            'address': 'Jl. Stasiun Gambir'
          },
          {
            'id': 3,
            'name': 'Stasiun Bandung - Bandung',
            'address': 'Jl. Stasiun Bandung'
          },
        ];
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => LocationPickerPage(
              title: isStartLocation
                  ? 'Pilih Kota atau Pos Awal'
                  : 'Pilih Kota atau Pos',
              daftarLokasi: List<Map<String, String>>.from(daftar),
              onLocationSelected: (location) {
                setState(() {
                  if (isStartLocation) {
                    lokasiAwal = location['name'];
                    lokasiAwalAddress = location['address'];
                  } else {
                    lokasiTujuan = location['name'];
                    lokasiTujuanAddress = location['address'];
                  }
                });
              },
            ),
          ),
        );
      }
    }
  }

  Future<bool> _showFetchErrorDialog(String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Gagal mengambil lokasi'),
            content: Text(
                'Terjadi kesalahan saat mengambil daftar lokasi:\n$message\n\nPastikan backend berjalan di http://localhost:8000 dan CORS diizinkan.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Gunakan contoh'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showHistorySelectionDialog(Map<String, String> alamat) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pilih sebagai'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.arrow_upward,
                  color: NebengMotorTheme.greenIcon,
                ),
                title: const Text('Lokasi Awal'),
                onTap: () {
                  setState(() {
                    lokasiAwal = alamat['name'];
                    lokasiAwalAddress = alamat['address'];
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.location_on,
                  color: NebengMotorTheme.orangeIcon,
                ),
                title: const Text('Lokasi Tujuan'),
                onTap: () {
                  setState(() {
                    lokasiTujuan = alamat['name'];
                    lokasiTujuanAddress = alamat['address'];
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDatePicker() async {
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
                initialDate: tanggalKeberangkatan ?? DateTime.now(),
                selectedDate: tanggalKeberangkatan,
                disablePast: true,
              ),
            ],
          ),
        );
      },
    );
    if (picked != null) {
      setState(() {
        tanggalKeberangkatan = picked;
      });
    }
  }
}
