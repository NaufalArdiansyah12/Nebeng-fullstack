import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/trip_model.dart';
import '../../nebeng_motor/utils/theme.dart';
import 'payment_selection_page.dart';
import '../../../../services/api_service.dart';
import '../../../../services/customer/booking_service.dart';
import '../widgets/ukuran_picker.dart';

class BookingDetailPage extends StatefulWidget {
  final TripModel trip;
  final File? photoFile;
  final String? weight;
  final String? description;

  const BookingDetailPage({
    Key? key,
    required this.trip,
    this.photoFile,
    this.weight,
    this.description,
  }) : super(key: key);

  @override
  State<BookingDetailPage> createState() => _BookingDetailPageState();
}

class _BookingDetailPageState extends State<BookingDetailPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String? _selectedWeight;
  final TextEditingController _descriptionController = TextEditingController();
  bool _agreedToTerms = false;
  String bookingNumber = '';
  File? selectedImage;
  final ImagePicker _picker = ImagePicker();
  int displayPrice = 0;

  @override
  void initState() {
    super.initState();
    _generateBookingNumber();
    _loadUserData();
    _nameController.addListener(() => setState(() {}));
    _phoneController.addListener(() => setState(() {}));

    // Set initial values from passed data
    if (widget.weight != null) {
      _selectedWeight = widget.weight;
    }
    if (widget.description != null) {
      _descriptionController.text = widget.description!;
    }
    if (widget.photoFile != null) {
      selectedImage = widget.photoFile;
    }
    if (widget.trip.price > 0) {
      displayPrice = _roundNearest(widget.trip.price);
    } else {
      _fetchCalculatedPriceIfNeeded();
    }
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
                    const SizedBox(height: 12),
                    if (widget.trip.photoUrl != null &&
                        widget.trip.photoUrl!.isNotEmpty)
                      _buildPhotoCard(),
                    const SizedBox(height: 20),
                    _buildPassengerForm(),
                    const SizedBox(height: 20),
                    _buildBarangDetailsForm(),
                    const SizedBox(height: 20),
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
                Text(
                  'Rp ${_formatPrice(displayPrice)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
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
        transportMode: 'barang',
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
        // If backend returned a category_price, trust it and do not round.
        final hasCategoryPrice = calc['category_price'] != null &&
            (calc['category_price'] is num
                ? (calc['category_price'] as num) > 0
                : (double.tryParse(calc['category_price'].toString() ?? '0') ?? 0) > 0);
        setState(() => displayPrice = hasCategoryPrice ? value : _roundNearest(value));
      }
    } catch (e) {
      // ignore
    }
  }

  int _roundNearest(int value, [int nearest = 5000]) {
    if (value == 0) return 0;
    // Use ceiling to avoid rounding 6000 -> 5000; 6000 -> 10000 instead.
    return ((value + nearest - 1) ~/ nearest) * nearest;
  }

  Future<void> _recalculatePriceForSelectedWeight() async {
    if (_selectedWeight == null) return;

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
        transportMode: 'barang',
        weight: numericKg.toDouble(),
        serviceType: widget.trip.serviceType,
        distance: distance,
      );

      // Better extraction: prefer final_price, total, category_price, weight_charge, price, unit_price
      int value = 0;
      try {
        if (calc['final_price'] is num) {
          value = (calc['final_price'] as num).toInt();
        } else if (calc['total'] is num) {
          value = (calc['total'] as num).toInt();
        } else if (calc['category_price'] is num) {
          value = (calc['category_price'] as num).toInt();
        } else if (calc['weight_charge'] is num) {
          value = (calc['weight_charge'] as num).toInt();
        } else if (calc['price'] is num) {
          value = (calc['price'] as num).toInt();
        } else if (calc['unit_price'] is num) {
          value = (calc['unit_price'] as num).toInt();
        }
      } catch (e) {
        // keep value 0
      }

      // Log for debugging in dev builds
      // ignore: avoid_print
      print('Price calc (barang) response: ' + calc.toString());

      if (value > 0) {
        setState(() {
          final hasCategoryPrice = calc['category_price'] != null &&
              (calc['category_price'] is num
                  ? (calc['category_price'] as num) > 0
                  : (double.tryParse(calc['category_price'].toString() ?? '0') ?? 0) > 0);
          displayPrice = hasCategoryPrice ? value : _roundNearest(value);
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal mendapatkan tarif. Silakan coba lagi.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // ignore
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
              children: const [
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

  Widget _buildPhotoCard() {
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
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: NebengMotorTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.shopping_bag_outlined,
                  color: NebengMotorTheme.primaryBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Berat Barang',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              Text(
                widget.trip.weight ?? '2KG',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Foto Barang:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          if (widget.trip.photoUrl != null && widget.trip.photoUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                widget.trip.photoUrl!,
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: double.infinity,
                    height: 180,
                    color: Colors.grey[200],
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: double.infinity,
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Gagal memuat foto',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          if (widget.trip.description != null &&
              widget.trip.description!.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Deskripsi Barang:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.trip.description!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
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
          weight: _selectedWeight ?? '',
          description: _descriptionController.text,
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
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: NebengMotorTheme.primaryBlue),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.photo_camera_outlined,
                      size: 20, color: Colors.grey[600]),
                  const SizedBox(width: 12),
                  const Text(
                    'Foto Barang (Opsional)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickImage,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: double.infinity,
                  height: selectedImage != null ? 150 : 100,
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.grey[300]!,
                      width: 1.5,
                    ),
                  ),
                  child: selectedImage != null
                      ? Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(7),
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
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    shape: BoxShape.circle,
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
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: NebengMotorTheme.primaryBlue
                                    .withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.add_photo_alternate,
                                color: NebengMotorTheme.primaryBlue,
                                size: 20,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap untuk tambah foto',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Format: JPG, PNG (Max 5MB)',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 10,
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

  Widget _buildBarangInput(
    IconData icon,
    String label,
    TextEditingController controller,
    String hint,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: controller,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[400],
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
