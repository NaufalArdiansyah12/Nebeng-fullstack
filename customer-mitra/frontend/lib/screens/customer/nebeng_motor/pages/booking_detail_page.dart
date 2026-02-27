import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/trip_model.dart';
import '../utils/theme.dart';
import 'payment_selection_page.dart';
import '../../../../services/api_service.dart';
import '../../../../services/customer/booking_service.dart';
import 'dart:io';
import 'dart:math';
import 'package:image_picker/image_picker.dart';
import '../../nebeng_barang/widgets/ukuran_picker.dart';

class BookingDetailPage extends StatefulWidget {
  final TripModel trip;

  const BookingDetailPage({
    Key? key,
    required this.trip,
  }) : super(key: key);

  @override
  State<BookingDetailPage> createState() => _BookingDetailPageState();
}

class _BookingDetailPageState extends State<BookingDetailPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String? _selectedWeight;
  final TextEditingController _descriptionController = TextEditingController();
  File? selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _agreedToTerms = false;
  String bookingNumber = '';
  int displayPrice = 0;

  @override
  void initState() {
    super.initState();
    _generateBookingNumber();
    _loadUserData();
    // For barang/both service types, prefer Finance-calculated price based on weight
    if (widget.trip.serviceType == 'barang' ||
        widget.trip.serviceType == 'both') {
      displayPrice = 0; // wait until user picks berat
    } else {
      if (widget.trip.price > 0) {
        displayPrice = _roundNearest(widget.trip.price);
      } else {
        _fetchCalculatedPriceIfNeeded();
      }
    }

    // Add listeners to update button state when text changes
    _nameController.addListener(() {
      setState(() {});
    });
    _phoneController.addListener(() {
      setState(() {});
    });
    _descriptionController.addListener(() => setState(() {}));
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('api_token');
    if (token == null) return;

    try {
      final resp = await ApiService.getProfile(token: token);
      if (resp['success'] == true && resp['data'] != null) {
        final user = resp['data']['user'];
        setState(() {
          _nameController.text = user['name'] as String? ?? '';
          _phoneController.text = user['phone'] as String? ?? '';
        });
      }
    } catch (e) {
      // ignore, keep defaults
    }
  }

  void _generateBookingNumber() {
    final now = DateTime.now();
    bookingNumber = 'FR-${now.millisecondsSinceEpoch}';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NebengMotorTheme.primaryBlue,
      appBar: AppBar(
        backgroundColor: NebengMotorTheme.primaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Detail Pesanan',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBookingNumber(),
                    const SizedBox(height: 16),
                    _buildTripDetails(),
                    const SizedBox(height: 12),
                    _buildTripDateBox(),
                    const SizedBox(height: 20),
                    _buildPassengerForm(),
                    const SizedBox(height: 20),
                    if (widget.trip.serviceType == 'barang' ||
                        widget.trip.serviceType == 'both') ...[
                      _buildBarangDetailsForm(),
                      const SizedBox(height: 20),
                    ],
                    _buildTotalPayment(),
                    const SizedBox(height: 16),
                    _buildTermsCheckbox(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildPaymentButton(),
    );
  }

  Widget _buildBookingNumber() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'No Pemesanan:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        Text(
          bookingNumber,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildTripDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.trip.date} | ${widget.trip.time}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildLocationInfo(
            title: widget.trip.departureLocation,
            address: widget.trip.departureAddress,
            color: Colors.grey,
          ),
          const SizedBox(height: 12),
          _buildLocationInfo(
            title: widget.trip.arrivalLocation,
            address: widget.trip.arrivalAddress,
            color: Colors.red,
            isDestination: true,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.only(top: 16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Biaya',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      'Rp ${_formatPrice(displayPrice)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationInfo({
    required String title,
    required String address,
    required Color color,
    bool isDestination = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
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
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                address,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPassengerForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Penumpang',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildFormField(
                label: 'Nama Penumpang:',
                controller: _nameController,
                hintText: 'Masukkan nama',
              ),
              // Garis pemisah antar field
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Divider(
                  color: Colors.grey[300],
                  thickness: 1,
                ),
              ),
              const SizedBox(height: 12),
              _buildFormField(
                label: 'No. Tlp:',
                controller: _phoneController,
                hintText: 'Masukkan nomor telepon',
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTripDateBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: NebengMotorTheme.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.calendar_month,
              color: NebengMotorTheme.primaryBlue,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            widget.trip.date,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    TextInputType? keyboardType,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildTotalPayment() {
    return Container(
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
            'Total Pembayaran',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          Text(
            'Rp ${_formatPrice(displayPrice)}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchCalculatedPriceIfNeeded() async {
    try {
      double? distance;
      if (widget.trip.originLat != null &&
          widget.trip.originLon != null &&
          widget.trip.destinationLat != null &&
          widget.trip.destinationLon != null) {
        final lat1 = widget.trip.originLat! * (3.141592653589793 / 180.0);
        final lon1 = widget.trip.originLon! * (3.141592653589793 / 180.0);
        final lat2 = widget.trip.destinationLat! * (3.141592653589793 / 180.0);
        final lon2 = widget.trip.destinationLon! * (3.141592653589793 / 180.0);
        final dlat = lat2 - lat1;
        final dlon = lon2 - lon1;
        final a = ((sin(dlat / 2) * sin(dlat / 2)) +
            cos(lat1) * cos(lat2) * (sin(dlon / 2) * sin(dlon / 2)));
        final c = 2 * atan2(sqrt(a), sqrt(1 - a));
        final earthKm = 6371.0;
        distance = earthKm * c;
      }

      final calc = await BookingService.calculatePrice(
        transportMode: 'motor',
        weight: 0.0,
        serviceType: widget.trip.serviceType,
        distance: distance,
      );
      int value = 0;
      if (calc['final_price'] is num) {
        value = (calc['final_price'] as num).toInt();
      } else if (calc['total'] is num) {
        value = (calc['total'] as num).toInt();
      } else if (calc['price'] is num) {
        value = (calc['price'] as num).toInt();
      }
      if (value > 0) {
        setState(() {
          displayPrice = _roundNearest(value);
        });
      }
    } catch (e) {
      // ignore, keep 0
    }
  }

  Widget _buildTermsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: _agreedToTerms,
            onChanged: (value) {
              setState(() {
                _agreedToTerms = value ?? false;
              });
            },
            activeColor: NebengMotorTheme.primaryBlue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                height: 1.4,
              ),
              children: [
                TextSpan(text: 'Saya telah membaca dan setuju terhadap '),
                TextSpan(
                  text: 'Syarat dan ketentuan pembelian tiket',
                  style: TextStyle(
                    color: NebengMotorTheme.primaryBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentButton() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: _agreedToTerms &&
                  _nameController.text.isNotEmpty &&
                  _phoneController.text.isNotEmpty
              ? _handlePayment
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: NebengMotorTheme.primaryBlue,
            disabledBackgroundColor: Colors.grey[300],
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ),
          child: const Text(
            'Lanjutkan Pembayaran',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  void _handlePayment() {
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon setujui syarat dan ketentuan'),
        ),
      );
      return;
    }

    if (_nameController.text.isEmpty || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon lengkapi data penumpang'),
        ),
      );
      return;
    }

    // Navigate to payment selection page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentSelectionPage(
          trip: TripModel(
            id: widget.trip.id,
            date: widget.trip.date,
            time: widget.trip.time,
            departureLocation: widget.trip.departureLocation,
            departureAddress: widget.trip.departureAddress,
            arrivalLocation: widget.trip.arrivalLocation,
            arrivalAddress: widget.trip.arrivalAddress,
            price: displayPrice,
            vehicleName: widget.trip.vehicleName,
            vehiclePlate: widget.trip.vehiclePlate,
            vehicleBrand: widget.trip.vehicleBrand,
            vehicleType: widget.trip.vehicleType,
            availableSeats: widget.trip.availableSeats,
            bagasiCapacity: widget.trip.bagasiCapacity,
            jumlahBagasi: widget.trip.jumlahBagasi,
            serviceType: widget.trip.serviceType,
            originLat: widget.trip.originLat,
            originLon: widget.trip.originLon,
            destinationLat: widget.trip.destinationLat,
            destinationLon: widget.trip.destinationLon,
          ),
          bookingNumber: bookingNumber,
          passengerName: _nameController.text,
          phoneNumber: _phoneController.text,
          photoFile: selectedImage,
          weight: _selectedWeight,
          description: _descriptionController.text.isNotEmpty
              ? _descriptionController.text
              : null,
        ),
      ),
    );
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  int _roundNearest(int value, [int nearest = 5000]) {
    if (value == 0) return 0;
    // Use ceiling to match mobil behavior: always round up to nearest chunk
    return ((value + nearest - 1) ~/ nearest) * nearest;
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

  Widget _buildBarangDetailsForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detail Barang Anda',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildWeightPicker(),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.description_outlined,
                      size: 20, color: Colors.grey[600]),
                  const SizedBox(width: 12),
                  const Text(
                    'Deskripsi Barang',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: 'Contoh: Dokumen penting, kemasan bubble wrap',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[400],
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Foto Barang (Opsional)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
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
                              borderRadius: BorderRadius.circular(11),
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
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
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
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.add_photo_alternate_rounded,
                                color: Colors.blue[700],
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
        ],
      ),
    );
  }

  Widget _buildWeightPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.scale_outlined, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 12),
            const Text(
              'Berat Barang',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            UkuranPicker.show(context, (selected) async {
              setState(() {
                _selectedWeight = selected;
              });
              // Recalculate price when user picks weight
              await _recalculatePriceForSelectedWeight();
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedWeight ?? 'Pilih berat barang',
                  style: TextStyle(
                    fontSize: 14,
                    color: _selectedWeight != null
                        ? Colors.black87
                        : Colors.grey[400],
                  ),
                ),
                Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _recalculatePriceForSelectedWeight() async {
    if (_selectedWeight == null) return;

    // Map label to numeric kg using same limits as backend enum
    int numericKg = 0;
    switch (_selectedWeight) {
      case 'Kecil':
        numericKg = 5;
        break;
      case 'Sedang':
        numericKg = 10;
        break;
      case 'Besar':
        numericKg = 20;
        break;
      default:
        numericKg = int.tryParse(_selectedWeight ?? '0') ?? 0;
    }

    double? distance;
    if (widget.trip.originLat != null &&
        widget.trip.originLon != null &&
        widget.trip.destinationLat != null &&
        widget.trip.destinationLon != null) {
      final lat1 = widget.trip.originLat! * (3.141592653589793 / 180.0);
      final lon1 = widget.trip.originLon! * (3.141592653589793 / 180.0);
      final lat2 = widget.trip.destinationLat! * (3.141592653589793 / 180.0);
      final lon2 = widget.trip.destinationLon! * (3.141592653589793 / 180.0);
      final dlat = lat2 - lat1;
      final dlon = lon2 - lon1;
      final a = ((sin(dlat / 2) * sin(dlat / 2)) +
          cos(lat1) * cos(lat2) * (sin(dlon / 2) * sin(dlon / 2)));
      final c = 2 * atan2(sqrt(a), sqrt(1 - a));
      final earthKm = 6371.0;
      distance = earthKm * c;
    }

    try {
      final calc = await BookingService.calculatePrice(
        transportMode: 'motor',
        weight: numericKg.toDouble(),
        serviceType: widget.trip.serviceType,
        distance: distance,
      );

      int value = 0;
      if (calc['final_price'] is num) {
        value = (calc['final_price'] as num).toInt();
      } else if (calc['total'] is num) {
        value = (calc['total'] as num).toInt();
      } else if (calc['price'] is num) {
        value = (calc['price'] as num).toInt();
      }

      if (value > 0) {
        setState(() {
          displayPrice = _roundNearest(value);
        });
      }
    } catch (e) {
      // ignore
    }
  }
}
