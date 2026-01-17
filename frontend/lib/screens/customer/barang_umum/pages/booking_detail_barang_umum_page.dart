import 'dart:io';
import 'package:flutter/material.dart';
import '../../nebeng_motor/utils/theme.dart';
import '../../nebeng_barang/models/trip_model.dart';
import '../../nebeng_barang/pages/payment_selection_page.dart';

class BookingDetailBarangUmumPage extends StatefulWidget {
  final Map<String, dynamic> trip;
  final String lokasiAwal;
  final String lokasiTujuan;
  final String ukuranBarang;
  final String keteranganBarang;
  final File? fotoBarang;
  final String? dataPenerima;
  final String? penerimaPhone;
  final String? penerimaEmail;

  const BookingDetailBarangUmumPage({
    Key? key,
    required this.trip,
    required this.lokasiAwal,
    required this.lokasiTujuan,
    required this.ukuranBarang,
    required this.keteranganBarang,
    this.fotoBarang,
    this.dataPenerima,
    this.penerimaPhone,
    this.penerimaEmail,
  }) : super(key: key);

  @override
  State<BookingDetailBarangUmumPage> createState() =>
      _BookingDetailBarangUmumPageState();
}

class _BookingDetailBarangUmumPageState
    extends State<BookingDetailBarangUmumPage> {
  final TextEditingController _namaPengirimController = TextEditingController();
  final TextEditingController _phonePengirimController =
      TextEditingController();
  String? namaPenerima;
  String? phonePenerima;
  bool _agreedToTerms = false;
  String bookingNumber = '';

  @override
  void initState() {
    super.initState();
    _generateBookingNumber();
    namaPenerima = widget.dataPenerima;
    phonePenerima = widget.penerimaPhone;
  }

  void _generateBookingNumber() {
    final now = DateTime.now();
    bookingNumber = 'FR-${now.millisecondsSinceEpoch}';
  }

  @override
  void dispose() {
    _namaPengirimController.dispose();
    _phonePengirimController.dispose();
    super.dispose();
  }

  String _formatPrice(dynamic price) {
    try {
      final numPrice = double.parse(price.toString());
      return numPrice.toStringAsFixed(0).replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]}.',
          );
    } catch (e) {
      return price.toString();
    }
  }

  int _calculateTotal() {
    final priceValue = widget.trip['price'];
    if (priceValue == null) return 0;
    if (priceValue is num) return priceValue.toInt();
    final raw = priceValue.toString();
    // Remove non-digit characters (dots, commas, currency symbols)
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return 0;
    try {
      return int.parse(digits);
    } catch (e) {
      return 0;
    }
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
                    _buildTripCard(),
                    const SizedBox(height: 12),
                    _buildDateCard(),
                    const SizedBox(height: 20),
                    _buildPengirimSection(),
                    const SizedBox(height: 20),
                    _buildPenerimaSection(),
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

  Widget _buildTripCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.trip['departure_date']} | ${widget.trip['departure_time']}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildLocationInfo(
            title: widget.trip['origin_location']?['name'] ?? widget.lokasiAwal,
            address: widget.trip['origin_location']?['address'] ?? '',
            color: Colors.grey,
          ),
          const SizedBox(height: 12),
          _buildLocationInfo(
            title: widget.trip['destination_location']?['name'] ??
                widget.lokasiTujuan,
            address: widget.trip['destination_location']?['address'] ?? '',
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
                  'Rp ${_formatPrice(widget.trip['price'])}',
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

  Widget _buildDateCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!, width: 1.5),
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
            widget.trip['departure_date'] ?? '',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPengirimSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pengirim',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        (_namaPengirimController.text.isEmpty)
            ? _buildAddButton(
                label: 'Tambah Pengirim',
                onTap: _showAddPengirimDialog,
              )
            : _buildPersonCard(
                name: _namaPengirimController.text,
                phone: _phonePengirimController.text,
                onEdit: _showAddPengirimDialog,
              ),
      ],
    );
  }

  Widget _buildPenerimaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Penerima',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        (namaPenerima == null || namaPenerima!.isEmpty)
            ? _buildAddButton(
                label: 'Tambah Penerima',
                onTap: _showAddPenerimaDialog,
              )
            : _buildPersonCard(
                name: namaPenerima!,
                phone: phonePenerima ?? '',
                onEdit: _showAddPenerimaDialog,
              ),
      ],
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

  Widget _buildAddButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: NebengMotorTheme.primaryBlue,
        side: const BorderSide(
          color: NebengMotorTheme.primaryBlue,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        minimumSize: const Size(double.infinity, 48),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.add_circle_outline,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonCard({
    required String name,
    required String phone,
    required VoidCallback onEdit,
  }) {
    return Container(
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
                    Text(
                      'Nama ${name.contains('Pengirim') ? 'Pengirim' : 'Penerima'}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Flexible(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
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
                      phone,
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
            onPressed: onEdit,
            icon: const Icon(
              Icons.edit_outlined,
              size: 20,
            ),
            color: Colors.grey[600],
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalPayment() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!, width: 1.5),
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
            'Rp ${_formatPrice(widget.trip['price'])}',
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

  Widget _buildPaymentButton() {
    final bool isFormValid = _namaPengirimController.text.isNotEmpty &&
        _phonePengirimController.text.isNotEmpty &&
        namaPenerima != null &&
        namaPenerima!.isNotEmpty &&
        _agreedToTerms;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: isFormValid ? _handlePayment : null,
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

  void _showAddPengirimDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Data Pengirim'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _namaPengirimController,
              decoration: const InputDecoration(
                labelText: 'Nama Pengirim',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phonePengirimController,
              decoration: const InputDecoration(
                labelText: 'No. Telepon',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_namaPengirimController.text.isNotEmpty &&
                  _phonePengirimController.text.isNotEmpty) {
                setState(() {});
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: NebengMotorTheme.primaryBlue,
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showAddPenerimaDialog() {
    final nameController = TextEditingController(text: namaPenerima);
    final phoneController = TextEditingController(text: phonePenerima);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Data Penerima'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Penerima',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'No. Telepon',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  phoneController.text.isNotEmpty) {
                setState(() {
                  namaPenerima = nameController.text;
                  phonePenerima = phoneController.text;
                });
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: NebengMotorTheme.primaryBlue,
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _handlePayment() {
    final bool isFormValid = _namaPengirimController.text.isNotEmpty &&
        _phonePengirimController.text.isNotEmpty &&
        namaPenerima != null &&
        namaPenerima!.isNotEmpty &&
        _agreedToTerms;

    if (!isFormValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lengkapi data pengirim, penerima, dan setujui syarat'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final tripModel = TripModel.fromApi(widget.trip);

    final passengerName = _namaPengirimController.text.isNotEmpty
        ? _namaPengirimController.text
        : (namaPenerima ?? 'Pengirim');
    final phoneNumber = _phonePengirimController.text.isNotEmpty
        ? _phonePengirimController.text
        : (phonePenerima ?? '');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentSelectionPage(
          trip: tripModel,
          bookingNumber: bookingNumber,
          passengerName: passengerName,
          phoneNumber: phoneNumber,
          photoFile: widget.fotoBarang,
          weight: widget.ukuranBarang,
          description: widget.keteranganBarang,
          rideType: 'titip',
        ),
      ),
    );
  }
}
