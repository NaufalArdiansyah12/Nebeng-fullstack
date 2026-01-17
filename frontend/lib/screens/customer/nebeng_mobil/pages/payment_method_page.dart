import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../services/api_service.dart';
import '../../../../services/payment_service.dart';
import '../../nebeng_motor/pages/payment_waiting_page.dart';
import '../../nebeng_motor/pages/payment_success_page.dart';
import '../../nebeng_motor/models/trip_model.dart' as motor_model;
import '../models/trip_model.dart';
import '../utils/theme.dart';

class PaymentMethodPage extends StatefulWidget {
  final TripModel trip;
  final String bookingNumber;
  final String passengerName;
  final String phoneNumber;
  final String paymentMethod;
  final int totalPassengers;
  final List<Map<String, dynamic>>? penumpang;

  const PaymentMethodPage({
    Key? key,
    required this.trip,
    required this.bookingNumber,
    required this.passengerName,
    required this.phoneNumber,
    required this.paymentMethod,
    this.totalPassengers = 1,
    this.penumpang,
  }) : super(key: key);

  @override
  State<PaymentMethodPage> createState() => _PaymentMethodPageState();
}

class _PaymentMethodPageState extends State<PaymentMethodPage> {
  bool _isExpanded = false;

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
          'Metode Pembayaran',
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
                    _buildBookingInfo(),
                    const SizedBox(height: 20),
                    _buildPaymentMethodCard(),
                    const SizedBox(height: 20),
                    _buildTripSummary(),
                    const SizedBox(height: 20),
                    _buildTotalPayment(),
                    const SizedBox(height: 20),
                    _buildPaymentInstructions(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildPayButton(),
    );
  }

  Widget _buildPaymentMethodIcon() {
    // Cash icon
    if (widget.paymentMethod == 'cash') {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.money, size: 28, color: Colors.black87),
      );
    }

    // Branded payment method icons with colors
    Color bgColor;
    Color textColor;
    String displayText;

    switch (widget.paymentMethod) {
      case 'qris':
        bgColor = Colors.white;
        textColor = Colors.black87;
        displayText = 'QRIS';
        break;
      case 'bri':
        bgColor = const Color(0xFF003D79);
        textColor = Colors.white;
        displayText = 'BRI';
        break;
      case 'bca':
        bgColor = const Color(0xFF003D79);
        textColor = Colors.white;
        displayText = 'BCA';
        break;
      case 'dana':
        bgColor = const Color(0xFF118EEA);
        textColor = Colors.white;
        displayText = 'Dana';
        break;
      default:
        bgColor = Colors.grey[100]!;
        textColor = Colors.black87;
        displayText = widget.paymentMethod.toUpperCase();
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: widget.paymentMethod == 'qris'
            ? Border.all(color: Colors.grey[300]!, width: 1)
            : null,
      ),
      child: Center(
        child: Text(
          displayText,
          style: TextStyle(
            fontSize: widget.paymentMethod == 'dana' ? 11 : 12,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
      ),
    );
  }

  Widget _buildBookingInfo() {
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
          widget.bookingNumber,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodCard() {
    String methodName = _getPaymentMethodName();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          _buildPaymentMethodIcon(),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  methodName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                if (widget.paymentMethod == 'qris')
                  Text(
                    'Pindai QR pengemudi untuk membayar',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
          Icon(
            Icons.check_circle,
            color: NebengMobilTheme.greenIcon,
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildTripSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                '04 Januari 2025 | 13:45 - 18:45',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildLocationRow(
            icon: Icons.radio_button_checked,
            color: NebengMobilTheme.greenIcon,
            title: widget.trip.departureLocation,
            subtitle: widget.trip.departureAddress,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 8, bottom: 8),
            child: Container(
              width: 2,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
          _buildLocationRow(
            icon: Icons.location_on,
            color: Colors.red,
            title: widget.trip.arrivalLocation,
            subtitle: widget.trip.arrivalAddress,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
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
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
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

  Widget _buildTotalPayment() {
    final totalPrice = widget.trip.price * widget.totalPassengers;
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

  Widget _buildPaymentInstructions() {
    if (widget.paymentMethod == 'bri') {
      return _buildExpandableInstructions();
    }
    return const SizedBox.shrink();
  }

  Widget _buildExpandableInstructions() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: NebengMobilTheme.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.credit_card,
                      color: NebengMobilTheme.primaryBlue,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Lihat cara pembayaran',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(color: Colors.grey[300], height: 1),
                  const SizedBox(height: 16),
                  Text(
                    'Cara Pembayaran:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInstructionStep('1', 'Buka aplikasi BRI Mobile'),
                  _buildInstructionStep('2', 'Pilih menu Transfer'),
                  _buildInstructionStep('3', 'Pilih Virtual Account'),
                  _buildInstructionStep(
                      '4', 'Masukkan nomor VA: 234567899754323'),
                  _buildInstructionStep('5', 'Konfirmasi dan selesaikan'),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: NebengMobilTheme.primaryBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: NebengMobilTheme.primaryBlue,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayButton() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: _handlePayment,
          style: ElevatedButton.styleFrom(
            backgroundColor: NebengMobilTheme.primaryBlue,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ),
          child: const Text(
            'Bayar',
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
    _processBookingAndPayment();
  }

  Future<void> _processBookingAndPayment() async {
    final prefs = await SharedPreferences.getInstance();
    print('All SharedPreferences keys (Mobil): ${prefs.getKeys()}');
    final userId = prefs.getInt('user_id');
    print('Retrieved user_id (Mobil): $userId');

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User ID not found. Please login again.')),
      );
      return;
    }

    final seats = widget.totalPassengers;
    final bookingNumber = widget.bookingNumber;

    try {
      // 1) Create booking
      print(
          'Creating booking - rideId: ${widget.trip.id}, userId: $userId, seats: $seats');
      final booking = await ApiService.createBooking(
        rideId: int.parse(widget.trip.id),
        userId: userId,
        seats: seats,
        bookingNumber: bookingNumber,
        rideType: 'mobil',
        penumpang: widget.penumpang,
      );
      print('Booking created successfully: ${booking['id']}');

      // Use server-generated values to avoid mismatch
      final createdBookingId = booking['id'];
      final createdBookingNumber = booking['booking_number'] ?? bookingNumber;

      // 2) Create payment
      final paymentSvc = PaymentService();
      final amount = (widget.trip.price * seats).toDouble();
      print(
          'Creating payment - amount: $amount, method: ${widget.paymentMethod}');
      final paymentResult = await paymentSvc.createPayment(
        rideId: int.parse(widget.trip.id),
        userId: userId,
        bookingNumber: createdBookingNumber,
        bookingId: createdBookingId,
        paymentMethod: widget.paymentMethod,
        amount: amount,
        adminFee: 15000,
      );
      print('Payment result: $paymentResult');

      if (paymentResult['success'] == true) {
        // For non-cash payments, navigate to waiting/instruction page similar to motor flow
        final data = paymentResult['data'];
        final paymentData = data['payment'];
        final vaNumber = data['virtual_account_number'];
        final bankCode = data['bank_code'];
        final expiresAtStr = data['expires_at'];
        DateTime? expiresAt;
        try {
          expiresAt = DateTime.parse(expiresAtStr);
        } catch (_) {
          expiresAt = DateTime.now().add(Duration(hours: 1));
        }

        if (widget.paymentMethod == 'cash') {
          final motorTrip = motor_model.TripModel(
            id: widget.trip.id,
            date: widget.trip.date,
            time: widget.trip.time,
            departureLocation: widget.trip.departureLocation,
            departureAddress: widget.trip.departureAddress,
            arrivalLocation: widget.trip.arrivalLocation,
            arrivalAddress: widget.trip.arrivalAddress,
            price: widget.trip.price,
            availableSeats: widget.trip.availableSeats,
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentSuccessPage(
                trip: motorTrip,
                bookingNumber: createdBookingNumber,
                passengerName: widget.passengerName,
                phoneNumber: '',
                paymentMethod: widget.paymentMethod,
                totalPassengers: widget.totalPassengers,
                amount: amount,
                adminFee: 0,
              ),
            ),
          );
        } else {
          final motorTrip = motor_model.TripModel(
            id: widget.trip.id,
            date: widget.trip.date,
            time: widget.trip.time,
            departureLocation: widget.trip.departureLocation,
            departureAddress: widget.trip.departureAddress,
            arrivalLocation: widget.trip.arrivalLocation,
            arrivalAddress: widget.trip.arrivalAddress,
            price: widget.trip.price,
            availableSeats: widget.trip.availableSeats,
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentWaitingPage(
                trip: motorTrip,
                bookingNumber: createdBookingNumber,
                passengerName: widget.passengerName,
                phoneNumber: '',
                paymentMethod: widget.paymentMethod,
                totalPassengers: widget.totalPassengers,
                virtualAccountNumber: vaNumber,
                bankCode: bankCode,
                expiresAt: expiresAt!,
                paymentId: paymentData['id'],
                amount: amount,
                adminFee: 15000,
              ),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Payment failed: ${paymentResult['message']}')),
        );
      }
    } catch (e) {
      print('Error during booking/payment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error during booking/payment: ${e.toString()}')),
      );
    }
  }

  String _getPaymentMethodName() {
    switch (widget.paymentMethod) {
      case 'qris':
        return 'QRIS';
      case 'cash':
        return 'Tunai';
      case 'bri':
        return 'BRI Virtual Account';
      case 'bca':
        return 'BCA Virtual Account';
      case 'dana':
        return 'Dana';
      default:
        return 'Unknown';
    }
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }
}
