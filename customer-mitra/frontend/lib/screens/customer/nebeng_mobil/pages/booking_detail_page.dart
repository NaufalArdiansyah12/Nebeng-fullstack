import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/trip_model.dart';
import '../utils/theme.dart';
import 'payment_selection_page.dart';
import '../../../../services/api_service.dart';
import '../../../../services/customer/booking_service.dart';
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

class PassengerData {
  String name;
  String phone;

  PassengerData({required this.name, required this.phone});
}

class SavedPassenger {
  int id;
  String name;
  String phone;

  SavedPassenger({required this.id, required this.name, required this.phone});

  factory SavedPassenger.fromJson(Map<String, dynamic> json) {
    return SavedPassenger(
      id: json['id'] as int,
      name: json['name'] as String,
      phone: json['phone'] as String,
    );
  }
}

class _BookingDetailPageState extends State<BookingDetailPage> {
  List<PassengerData> passengers = [];
  bool _agreedToTerms = false;
  String bookingNumber = '';
  final TextEditingController _searchController = TextEditingController();
  String _userName = '';
  String _userPhone = '';
  String? _selectedWeight;
  final TextEditingController _descriptionController = TextEditingController();
  File? selectedImage;
  final ImagePicker _picker = ImagePicker();
  int displayPrice = 0;

  // Saved passengers loaded from database
  List<SavedPassenger> savedPassengers = [];
  bool _isLoadingPassengers = false;

  @override
  void initState() {
    super.initState();
    _generateBookingNumber();
    _loadUserData();
    _descriptionController.addListener(() => setState(() {}));
    // For barang/both service types, prefer Finance-calculated price based on weight
    if (widget.trip.serviceType == 'barang' ||
        widget.trip.serviceType == 'both') {
      displayPrice = 0; // wait until user picks berat
    } else {
      if (widget.trip.price > 0) {
        // For 'barang' service we prefer exact category nominal (no rounding).
        if (widget.trip.serviceType == 'barang') {
          displayPrice = widget.trip.price;
        } else {
          displayPrice = _roundNearest(widget.trip.price);
        }
      } else {
        _fetchCalculatedPriceIfNeeded();
      }
    }
  }

  Future<void> _loadUserData() async {
    // loading indicator removed; just proceed
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('api_token');
    if (token == null) {
      return;
    }

    try {
      final resp = await ApiService.getProfile(token: token);
      if (resp['success'] == true && resp['data'] != null) {
        final user = resp['data']['user'];
        setState(() {
          _userName = user['name'] as String? ?? '';
          _userPhone = user['phone'] as String? ?? '';
        });
      }

      // Load saved passengers
      await _loadSavedPassengers(token);
    } catch (e) {
      // ignore, keep defaults
    }
  }

  Future<void> _loadSavedPassengers(String token) async {
    setState(() => _isLoadingPassengers = true);
    try {
      final List<Map<String, dynamic>> response =
          await ApiService.getSavedPassengers(token: token);
      setState(() {
        savedPassengers =
            response.map((json) => SavedPassenger.fromJson(json)).toList();
      });
    } catch (e) {
      // ignore error, keep empty list
    } finally {
      setState(() => _isLoadingPassengers = false);
    }
  }

  void _generateBookingNumber() {
    final now = DateTime.now();
    bookingNumber = 'FR-${now.millisecondsSinceEpoch}';
  }

  void _showPassengerInfoModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildPassengerInfoModal(),
    );
  }

  void _showAddPassengerModal() {
    Navigator.pop(context); // Close passenger info modal first
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildAddPassengerModal(),
    );
  }

  void _addPassengerFromSaved(SavedPassenger saved) {
    if (passengers.length < widget.trip.maxPassengers) {
      setState(() {
        passengers.add(PassengerData(name: saved.name, phone: saved.phone));
      });
      Navigator.pop(context);
    }
  }

  Future<void> _deleteSavedPassenger(SavedPassenger passenger) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('api_token');
    if (token == null) return;

    try {
      final success = await ApiService.deletePassenger(
        token: token,
        passengerId: passenger.id,
      );

      if (success) {
        await _loadSavedPassengers(token);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ ${passenger.name} dihapus dari daftar'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menghapus penumpang'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removePassenger(int index) {
    setState(() {
      passengers.removeAt(index);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _allFieldsFilled {
    // For barang/titip_barang service type, check weight and description instead of passengers
    if (widget.trip.serviceType == 'barang' ||
        widget.trip.serviceType == 'both') {
      return _agreedToTerms &&
          _selectedWeight != null &&
          _descriptionController.text.isNotEmpty;
    }
    // For regular passenger service
    return _agreedToTerms && passengers.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NebengMobilTheme.primaryBlue,
      appBar: AppBar(
        backgroundColor: NebengMobilTheme.primaryBlue,
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
                    _buildPassengerSection(),
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

  Widget _buildPassengerSection() {
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
        ...List.generate(passengers.length, (index) {
          return _buildPassengerCard(index);
        }),
        const SizedBox(height: 8),
        if (widget.trip.serviceType == 'both' ||
            widget.trip.serviceType == 'tebengan')
          OutlinedButton(
            onPressed: passengers.length < widget.trip.maxPassengers
                ? _showPassengerInfoModal
                : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: NebengMobilTheme.primaryBlue,
              side: BorderSide(
                color: passengers.length < widget.trip.maxPassengers
                    ? NebengMobilTheme.primaryBlue
                    : Colors.grey[300]!,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              minimumSize: const Size(double.infinity, 48),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_circle_outline,
                  size: 20,
                  color: passengers.length < widget.trip.maxPassengers
                      ? NebengMobilTheme.primaryBlue
                      : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  'Tambah Penumpang',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: passengers.length < widget.trip.maxPassengers
                        ? NebengMobilTheme.primaryBlue
                        : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPassengerCard(int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Nama Penumpang',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      passengers[index].name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text(
                      'No Telepon',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(width: 36),
                    Text(
                      passengers[index].phone,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: () {
              // Edit functionality
            },
            color: Colors.grey[600],
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
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
              color: NebengMobilTheme.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.calendar_month,
              color: NebengMobilTheme.primaryBlue,
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

  Widget _buildTotalPayment() {
    // For barang service type, use trip price directly (no passenger multiplier)
    // For regular service, multiply by number of passengers
    final totalPrice = (widget.trip.serviceType == 'barang' ||
            widget.trip.serviceType == 'both')
        ? displayPrice
        : displayPrice * (passengers.isEmpty ? 1 : passengers.length);
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
            'Rp ${_formatPrice(totalPrice)}',
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
            activeColor: NebengMobilTheme.primaryBlue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Saya telah membaca dan setuju terhadap ',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 6),
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
    );
  }

  Widget _buildPaymentButton() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: _allFieldsFilled ? _handlePayment : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: NebengMobilTheme.primaryBlue,
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
    // For barang service type, use user's name and phone
    // For regular service, collect all passenger names
    final isBarangService = widget.trip.serviceType == 'barang' ||
        widget.trip.serviceType == 'both';
    final passengerNames =
        isBarangService ? _userName : passengers.map((p) => p.name).join(', ');
    final phoneNumber = isBarangService
        ? _userPhone
        : (passengers.isNotEmpty ? passengers[0].phone : '');

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
            availableSeats: widget.trip.availableSeats,
            maxPassengers: widget.trip.maxPassengers,
            bagasiCapacity: widget.trip.bagasiCapacity,
            jumlahBagasi: widget.trip.jumlahBagasi,
            serviceType: widget.trip.serviceType,
            originLat: widget.trip.originLat,
            originLon: widget.trip.originLon,
            destinationLat: widget.trip.destinationLat,
            destinationLon: widget.trip.destinationLon,
          ),
          bookingNumber: bookingNumber,
          passengerName: passengerNames,
          phoneNumber: phoneNumber,
          totalPassengers: isBarangService ? 1 : passengers.length,
          penumpang: (widget.trip.serviceType == 'barang' || passengers.isEmpty)
              ? null
              : passengers
                  .map((p) => {'nama': p.name, 'no_telepon': p.phone})
                  .toList(),
          photoFile: selectedImage,
          weight: _selectedWeight,
          description: _descriptionController.text.isNotEmpty
              ? _descriptionController.text
              : null,
        ),
      ),
    );
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
        transportMode: 'mobil',
        weight: 0.0,
        serviceType: widget.trip.serviceType,
        distance: distance,
      );

      // Prefer final_price -> total -> price (match motor behavior)
      int value = 0;
      if (calc['final_price'] is num) {
        value = (calc['final_price'] as num).toInt();
      } else if (calc['total'] is num) {
        value = (calc['total'] as num).toInt();
      } else if (calc['price'] is num) {
        value = (calc['price'] as num).toInt();
      }

      if (value > 0) setState(() => displayPrice = _roundNearest(value));
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
        transportMode: 'mobil',
        weight: numericKg.toDouble(),
        serviceType: widget.trip.serviceType,
        distance: distance,
      );

      // Debug: print calc response to help diagnose pricing issues
      print('BookingService.calculatePrice (mobil) response: $calc');

      // Prefer final_price -> total -> price (match motor behavior)
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
          // If backend returned a category_price (barang nominal), trust it
          // and do not apply client-side rounding. This covers both
          // `barang` and combined (`both`) flows when category_price exists.
          final hasCategoryPrice = calc['category_price'] != null &&
              (calc['category_price'] is num
                  ? (calc['category_price'] as num) > 0
                  : (double.tryParse(
                              calc['category_price'].toString() ?? '0') ??
                          0) >
                      0);

          if (hasCategoryPrice) {
            displayPrice = value;
          } else if (widget.trip.serviceType == 'barang') {
            displayPrice = value;
          } else {
            displayPrice = _roundNearest(value);
          }
        });
      } else {
        // Show the raw calc fields so we can see what server returned
        if (mounted) {
          final fp = calc['final_price']?.toString() ?? 'null';
          final tot = calc['total']?.toString() ?? 'null';
          final pr = calc['price']?.toString() ?? 'null';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Harga tidak tersedia - final:$fp total:$tot price:$pr'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        // If no usable price returned, notify user
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

  Widget _buildBarangInput(IconData icon, String label,
      TextEditingController controller, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: const TextStyle(fontSize: 14, color: Colors.black87),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 14, color: Colors.grey[400]),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!)),
          ),
        ),
      ],
    );
  }

  Widget _buildPassengerInfoModal() {
    final filteredPassengers = savedPassengers.where((p) {
      return p.name
          .toLowerCase()
          .contains(_searchController.text.toLowerCase());
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Informasi Penebeng',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        '${passengers.length}/${widget.trip.maxPassengers} penumpang',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Added Passengers Section (if any)
          if (passengers.isNotEmpty)
            Container(
              color: Colors.blue.withOpacity(0.05),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Penumpang Terpilih (${passengers.length})',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      if (passengers.length < widget.trip.maxPassengers)
                        TextButton(
                          onPressed: _showAddPassengerModal,
                          child: const Text('+ Tambah'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...passengers.asMap().entries.map((entry) {
                    final index = entry.key;
                    final p = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: NebengMobilTheme.primaryBlue,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  p.phone,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline,
                                color: Colors.red[400], size: 20),
                            onPressed: () {
                              setState(() {
                                passengers.removeAt(index);
                              });
                              Navigator.pop(context);
                              _showPassengerInfoModal();
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Add Passenger Button
                if (passengers.length < widget.trip.maxPassengers)
                  OutlinedButton(
                    onPressed: _showAddPassengerModal,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: NebengMobilTheme.primaryBlue,
                      side: const BorderSide(
                        color: NebengMobilTheme.primaryBlue,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.add_circle_outline, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Tambah Penebeng Baru',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                // Search Bar
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Cari penebeng tersimpan',
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Saved Passengers List
          Expanded(
            child: filteredPassengers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline,
                            size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          _searchController.text.isEmpty
                              ? 'Belum ada penebeng tersimpan'
                              : 'Tidak ada hasil pencarian',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredPassengers.length,
                    itemBuilder: (context, index) {
                      final passenger = filteredPassengers[index];
                      final isAdded = passengers.any((p) =>
                          p.name == passenger.name &&
                          p.phone == passenger.phone);

                      return InkWell(
                        onTap: isAdded ||
                                passengers.length >= widget.trip.maxPassengers
                            ? null
                            : () => _addPassengerFromSaved(passenger),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isAdded ? Colors.grey[100] : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isAdded
                                  ? Colors.grey[300]!
                                  : Colors.grey[300]!,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      passenger.name,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: isAdded
                                            ? Colors.grey[500]
                                            : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      passenger.phone,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isAdded)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green[50],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Ditambahkan',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.green[700],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                )
                              else if (passengers.length >=
                                  widget.trip.maxPassengers)
                                Icon(Icons.block,
                                    color: Colors.grey[400], size: 20)
                              else
                                Icon(Icons.add_circle_outline,
                                    color: NebengMobilTheme.primaryBlue,
                                    size: 20),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: Icon(Icons.delete_outline,
                                    color: Colors.red[400], size: 20),
                                onPressed: () =>
                                    _deleteSavedPassenger(passenger),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
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
    );
  }

  Widget _buildAddPassengerModal() {
    final TextEditingController nameController =
        TextEditingController(text: _userName);
    final TextEditingController phoneController =
        TextEditingController(text: _userPhone);
    bool saveToList = true;
    String? nameError;
    String? phoneError;

    return StatefulBuilder(
      builder: (context, setModalState) {
        void validateAndSave() async {
          setModalState(() {
            nameError = null;
            phoneError = null;
          });

          // Validation
          if (nameController.text.trim().isEmpty) {
            setModalState(() {
              nameError = 'Nama harus diisi';
            });
            return;
          }

          if (phoneController.text.trim().isEmpty) {
            setModalState(() {
              phoneError = 'No telp harus diisi';
            });
            return;
          }

          if (phoneController.text.trim().length < 10) {
            setModalState(() {
              phoneError = 'No telp minimal 10 digit';
            });
            return;
          }

          if (passengers.length >= widget.trip.maxPassengers) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text('Maksimal ${widget.trip.maxPassengers} penumpang'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }

          // Check duplicate
          final isDuplicate = passengers.any((p) =>
              p.name.toLowerCase() ==
                  nameController.text.trim().toLowerCase() &&
              p.phone == phoneController.text.trim());

          if (isDuplicate) {
            setModalState(() {
              nameError = 'Penumpang sudah ditambahkan';
            });
            return;
          }

          // Add passenger
          setState(() {
            passengers.add(PassengerData(
              name: nameController.text.trim(),
              phone: phoneController.text.trim(),
            ));
          });

          // Save to list if toggle is on
          if (saveToList) {
            final isAlreadySaved = savedPassengers.any((sp) =>
                sp.name.toLowerCase() ==
                    nameController.text.trim().toLowerCase() &&
                sp.phone == phoneController.text.trim());

            if (!isAlreadySaved) {
              // Save to database
              final prefs = await SharedPreferences.getInstance();
              final token = prefs.getString('api_token');
              if (token != null) {
                try {
                  await ApiService.savePassenger(
                    token: token,
                    name: nameController.text.trim(),
                    phone: phoneController.text.trim(),
                  );
                  // Reload saved passengers list
                  await _loadSavedPassengers(token);
                } catch (e) {
                  // ignore error
                }
              }
            }
          }

          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✓ ${nameController.text.trim()} ditambahkan'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );

          // Reopen passenger info modal
          Future.delayed(const Duration(milliseconds: 300), () {
            _showPassengerInfoModal();
          });
        }

        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        Navigator.pop(context);
                        Future.delayed(const Duration(milliseconds: 300), () {
                          _showPassengerInfoModal();
                        });
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Tambah Penebeng',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name Field
                      const Text(
                        'Nama',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: nameController,
                        onChanged: (value) {
                          setModalState(() {
                            nameError = null;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Nama Penumpang',
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF5F5F5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: nameError != null
                                ? const BorderSide(color: Colors.red)
                                : BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: nameError != null
                                ? const BorderSide(color: Colors.red)
                                : BorderSide.none,
                          ),
                          errorText: nameError,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Phone Field
                      const Text(
                        'No Telp',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        onChanged: (value) {
                          setModalState(() {
                            phoneError = null;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: '08xxxxxxxxxx',
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF5F5F5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: phoneError != null
                                ? const BorderSide(color: Colors.red)
                                : BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: phoneError != null
                                ? const BorderSide(color: Colors.red)
                                : BorderSide.none,
                          ),
                          errorText: phoneError,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Save to List Toggle
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.bookmark_outline,
                                color: NebengMobilTheme.primaryBlue, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Simpan ke daftar penebeng',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    'Untuk memudahkan booking selanjutnya',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: saveToList,
                              onChanged: (value) {
                                setModalState(() {
                                  saveToList = value;
                                });
                              },
                              activeColor: NebengMobilTheme.primaryBlue,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Save Button
                      ElevatedButton(
                        onPressed: validateAndSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: NebengMobilTheme.primaryBlue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        child: const Text(
                          'Simpan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }
}
