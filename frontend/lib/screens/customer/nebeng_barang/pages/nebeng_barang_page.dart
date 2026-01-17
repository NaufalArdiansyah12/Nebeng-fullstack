import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../nebeng_motor/data/location_data.dart';
import '../../nebeng_motor/widgets/form_section.dart';
import '../../nebeng_motor/widgets/history_section.dart';
import '../../nebeng_motor/pages/location_picker_page.dart';
import '../../../../services/api_service.dart';
import '../../../../widgets/custom_calendar_widget.dart';
import '../../nebeng_motor/utils/theme.dart';
import '../widgets/ukuran_picker.dart';
import 'trip_list_page.dart';

class NebengBarangPage extends StatefulWidget {
  const NebengBarangPage({Key? key}) : super(key: key);

  @override
  State<NebengBarangPage> createState() => _NebengBarangPageState();
}

class _NebengBarangPageState extends State<NebengBarangPage> {
  String? lokasiAwal;
  String? lokasiAwalAddress;
  int? lokasiAwalId;
  String? lokasiTujuan;
  String? lokasiTujuanAddress;
  int? lokasiTujuanId;
  DateTime? tanggalKeberangkatan;

  String? ukuranBarang;
  String? keteranganBarang;
  File? selectedImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          selectedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memilih foto: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

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
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.22),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Color(0xFF3B82F6),
                                          Color(0xFF1E40AF),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF3B82F6)
                                              .withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.inventory_2_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Ukuran Barang',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              // tappable field opens UkuranPicker
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.withOpacity(0.15),
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 4),
                                child: InkWell(
                                  onTap: () => UkuranPicker.show(context,
                                      (v) => setState(() => ukuranBarang = v)),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            ukuranBarang == null
                                                ? 'Pilih ukuran barang anda'
                                                : (ukuranBarang == 'Kecil'
                                                    ? '📦 Kecil - Maksimal 5 Kg'
                                                    : ukuranBarang == 'Sedang'
                                                        ? '📦 Sedang - Maksimal 10 Kg'
                                                        : '📦 Besar - Maksimal 20 Kg'),
                                            style: TextStyle(
                                              color: ukuranBarang == null
                                                  ? Colors.grey[500]
                                                  : Colors.black87,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          color: Colors.grey[400],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              Row(
                                children: [
                                  Icon(Icons.description_rounded,
                                      size: 18, color: Colors.grey[600]),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Keterangan Barang',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.withOpacity(0.15),
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 12),
                                child: TextFormField(
                                  initialValue: keteranganBarang,
                                  onChanged: (v) =>
                                      setState(() => keteranganBarang = v),
                                  minLines: 2,
                                  maxLines: 4,
                                  style: const TextStyle(fontSize: 14),
                                  decoration: InputDecoration(
                                    hintText:
                                        'Contoh: Dokumen penting, kemasan bubble wrap',
                                    hintStyle: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 13,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              Row(
                                children: [
                                  Icon(Icons.photo_camera_rounded,
                                      size: 18, color: Colors.grey[600]),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Foto Barang (Opsional)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              InkWell(
                                onTap: _pickImage,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: double.infinity,
                                  height: selectedImage != null ? 200 : 120,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey.withOpacity(0.2),
                                      width: 1.5,
                                      style: BorderStyle.solid,
                                    ),
                                  ),
                                  child: selectedImage != null
                                      ? Stack(
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(11),
                                              child: Image.file(
                                                selectedImage!,
                                                width: double.infinity,
                                                height: double.infinity,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                            Positioned(
                                              top: 8,
                                              right: 8,
                                              child: GestureDetector(
                                                onTap: () {
                                                  setState(() {
                                                    selectedImage = null;
                                                  });
                                                },
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.all(6),
                                                  decoration: BoxDecoration(
                                                    color: Colors.black
                                                        .withOpacity(0.6),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    Icons.close,
                                                    color: Colors.white,
                                                    size: 18,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        )
                                      : Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              width: 48,
                                              height: 48,
                                              decoration: BoxDecoration(
                                                color: Colors.blue[50],
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Icons
                                                    .add_photo_alternate_rounded,
                                                color: NebengMotorTheme
                                                    .primaryBlue,
                                                size: 24,
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            Text(
                                              'Tap untuk tambah foto',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Format: JPG, PNG (Max 5MB)',
                                              style: TextStyle(
                                                color: Colors.grey[400],
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
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
              'Lanjutkan',
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
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => TripListPage(
            lokasiAwal: lokasiAwal!,
            lokasiTujuan: lokasiTujuan!,
            tanggalKeberangkatan: tanggalKeberangkatan!,
            originLocationId: lokasiAwalId,
            destinationLocationId: lokasiTujuanId,
            photoFile: selectedImage,
            weight: ukuranBarang,
            description: keteranganBarang,
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
            'Nebeng Barang',
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
      Navigator.pop(context);
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
                    lokasiAwalId = 1;
                    lokasiAwal = location['name'];
                    lokasiAwalAddress = location['address'];
                  } else {
                    lokasiTujuanId = 2;
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
