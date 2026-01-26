import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../nebeng_motor/widgets/form_section.dart';
import '../../nebeng_motor/pages/location_picker_page.dart';
import '../../nebeng_motor/utils/theme.dart';
import '../../nebeng_barang/widgets/ukuran_picker.dart';
import '../../nebeng_barang/widgets/barang_form.dart';
import '../../../../services/api_service.dart';
import '../../../../widgets/custom_calendar_widget.dart';
import 'penerima_picker_page.dart';
import 'trip_list_barang_umum_page.dart';

class BarangUmumPage extends StatefulWidget {
  const BarangUmumPage({Key? key}) : super(key: key);

  @override
  State<BarangUmumPage> createState() => _BarangUmumPageState();
}

class _BarangUmumPageState extends State<BarangUmumPage> {
  String? lokasiAwal;
  String? lokasiAwalAddress;
  int? lokasiAwalId;
  String? lokasiTujuan;
  String? lokasiTujuanAddress;
  int? lokasiTujuanId;
  DateTime? tanggalBerangkat;

  String? ukuranBarang;
  String? keteranganBarang;
  File? fotoBarang;
  String? dataPenerima;
  String? penerimaPhone;
  String? penerimaEmail;

  final ImagePicker _picker = ImagePicker();
  final TextEditingController _keteranganController = TextEditingController();
  final TextEditingController _penerimaController = TextEditingController();

  @override
  void dispose() {
    _keteranganController.dispose();
    _penerimaController.dispose();
    super.dispose();
  }

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
          fotoBarang = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih foto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showLocationPicker(bool isOrigin) async {
    final locations = await _fetchLocations();

    if (!mounted) return;

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerPage(
          title: isOrigin ? 'Pilih Lokasi Awal' : 'Pilih Lokasi Tujuan',
          daftarLokasi: locations,
          onLocationSelected: (location) {
            // Don't call Navigator.pop here, LocationPickerPage already handles it
          },
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        if (isOrigin) {
          lokasiAwal = result['name'];
          lokasiAwalAddress = result['address'];
          lokasiAwalId = result['id'];
        } else {
          lokasiTujuan = result['name'];
          lokasiTujuanAddress = result['address'];
          lokasiTujuanId = result['id'];
        }
      });
    }
  }

  Future<List<Map<String, dynamic>>> _fetchLocations() async {
    // Fetch locations from API
    try {
      final locations = await ApiService.fetchLocations();
      return locations;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat lokasi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return [];
    }
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
                initialDate: tanggalBerangkat ?? DateTime.now(),
                selectedDate: tanggalBerangkat,
                disablePast: true,
              ),
            ],
          ),
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        tanggalBerangkat = picked;
      });
    }
  }

  void _handleLanjut() {
    if (lokasiAwalId == null || lokasiTujuanId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon pilih lokasi awal dan tujuan'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (tanggalBerangkat == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon pilih tanggal berangkat'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (ukuranBarang == null || ukuranBarang!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon pilih ukuran barang'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (keteranganBarang == null || keteranganBarang!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon isi keterangan barang'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Navigate to trip list page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TripListBarangUmumPage(
          originLocationId: lokasiAwalId!,
          destinationLocationId: lokasiTujuanId!,
          lokasiAwal: lokasiAwal ?? '',
          lokasiTujuan: lokasiTujuan ?? '',
          tanggalBerangkat: tanggalBerangkat!,
          ukuranBarang: ukuranBarang!,
          keteranganBarang: keteranganBarang ?? '',
          fotoBarang: fotoBarang,
          dataPenerima: dataPenerima,
          penerimaPhone: penerimaPhone,
          penerimaEmail: penerimaEmail,
        ),
      ),
    );
    // ScaffoldMessenger.of(context).showSnackBar(
    //   const SnackBar(
    //     content: Text('Fitur booking barang umum dalam pengembangan'),
    //     backgroundColor: Colors.orange,
    //   ),
    // );
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
                      // Form Section - Lokasi & Tanggal
                      FormSection(
                        lokasiAwal: lokasiAwal,
                        lokasiAwalAddress: lokasiAwalAddress,
                        lokasiTujuan: lokasiTujuan,
                        lokasiTujuanAddress: lokasiTujuanAddress,
                        tanggalKeberangkatan: tanggalBerangkat,
                        onLokasiAwalTap: () => _showLocationPicker(true),
                        onLokasiTujuanTap: () => _showLocationPicker(false),
                        onTanggalTap: _showDatePicker,
                      ),
                      const SizedBox(height: 20),

                      // Detail Barang Section - use shared BarangForm for identical look
                      BarangForm(
                        ukuranBarang: ukuranBarang,
                        keteranganBarang: keteranganBarang,
                        onUkuranTap: _showUkuranPicker,
                        onKeteranganChanged: (v) =>
                            setState(() => keteranganBarang = v),
                        onPhotoTap: _pickImage,
                        fotoFile: fotoBarang,
                        onRemovePhoto: () {
                          setState(() {
                            fotoBarang = null;
                          });
                        },
                      ),

                      const SizedBox(height: 20),

                      // Data Penerima (kept below barang form)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFieldLabel(
                                'Data Penerima', Icons.person_rounded),
                            const SizedBox(height: 10),
                            _buildDataPenerimaField(),
                          ],
                        ),
                      ),

                      const SizedBox(height: 80),
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              color: NebengMotorTheme.primaryBlue,
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nebeng Titip Barang',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // SizedBox(height: 4),
                // Text(
                //   'Siap Melayanimu',
                //   style: TextStyle(
                //     color: Colors.white70,
                //     fontSize: 14,
                //   ),
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
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
                color: const Color(0xFF3B82F6).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildUkuranPicker() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.15),
        ),
      ),
      child: InkWell(
        onTap: () => UkuranPicker.show(
          context,
          (value) => setState(() => ukuranBarang = value),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
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
    );
  }

  Widget _buildKeteranganField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.15),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: TextField(
        controller: _keteranganController,
        minLines: 2,
        maxLines: 4,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'contoh bena dokumen',
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: 13,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildFotoBarangPicker() {
    return InkWell(
      onTap: _pickImage,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        height: fotoBarang != null ? 200 : 120,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: fotoBarang != null
            ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Image.file(
                      fotoBarang!,
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
                          fotoBarang = null;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tambah Foto Barang',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildDataPenerimaField() {
    return InkWell(
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                dataPenerima ?? 'Data Penerima',
                style: TextStyle(
                  fontSize: 14,
                  color:
                      dataPenerima == null ? Colors.grey[400] : Colors.black87,
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
    );
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
            currentPenerima: dataPenerima,
            scrollController: scrollController,
          ),
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        dataPenerima = result['name'];
        penerimaPhone = result['phone'];
        penerimaEmail = result['email'];
        _penerimaController.text = result['name'] ?? '';
      });
    }
  }

  void _showUkuranPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Pilih Kapasitas Bagasi',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                // Options
                Column(
                  children: [
                    InkWell(
                      onTap: () {
                        setState(() => ukuranBarang = 'Kecil');
                        Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: NebengMotorTheme.primaryBlue,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.card_travel,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text('Kecil',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w600)),
                                SizedBox(height: 4),
                                Text('Maksimal 5 Kg',
                                    style: TextStyle(color: Colors.grey)),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        setState(() => ukuranBarang = 'Sedang');
                        Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: NebengMotorTheme.primaryBlue,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.backpack_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text('Sedang',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w600)),
                                SizedBox(height: 4),
                                Text('Maksimal 10 Kg',
                                    style: TextStyle(color: Colors.grey)),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        setState(() => ukuranBarang = 'Besar');
                        Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: NebengMotorTheme.primaryBlue,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.inventory_2_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text('Besar',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w600)),
                                SizedBox(height: 4),
                                Text('Maksimal 20 Kg',
                                    style: TextStyle(color: Colors.grey)),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomButton() {
    return Container(
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
          onPressed: _handleLanjut,
          style: ElevatedButton.styleFrom(
            backgroundColor: NebengMotorTheme.primaryBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: const Text(
            'Lanjutnya',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
