import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/trip_model.dart';
import '../utils/theme.dart';
import '../../../../services/api_service.dart';
import '../../../../services/payment_service.dart';
import 'payment_waiting_page.dart';
import 'payment_success_page.dart';

class PaymentMethodPage extends StatefulWidget {
  final TripModel trip;
  final String bookingNumber;
  final String passengerName;
  final String phoneNumber;
  final String paymentMethod;
  final int totalPassengers;
  final File? photoFile;
  final String? weight;
  final String? description;

  const PaymentMethodPage({
    Key? key,
    required this.trip,
    required this.bookingNumber,
    required this.passengerName,
    required this.phoneNumber,
    required this.paymentMethod,
    this.totalPassengers = 1,
    this.photoFile,
    this.weight,
    this.description,
  }) : super(key: key);

  @override
  State<PaymentMethodPage> createState() => _PaymentMethodPageState();
}

class _PaymentMethodPageState extends State<PaymentMethodPage> {
  bool _isExpanded = false;
  bool _isLoading = false;
  final PaymentService _paymentService = PaymentService();

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
            color: NebengMotorTheme.greenIcon,
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
            color: NebengMotorTheme.greenIcon,
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
    // Calculate admin fee based on payment method
    int adminFee = widget.paymentMethod == 'cash' ? 0 : 15000;
    int totalAmount = widget.trip.price + adminFee;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          // Biaya per penebeng
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Biaya Per Penebeng',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                'Rp ${_formatPrice(widget.trip.price)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          if (adminFee > 0) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Biaya Admin',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                Text(
                  'Rp ${_formatPrice(adminFee)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ],
          Divider(height: 24, color: Colors.grey[300]),
          Row(
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
                'Rp ${_formatPrice(totalAmount)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
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
                      color: NebengMotorTheme.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.credit_card,
                      color: NebengMotorTheme.primaryBlue,
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
              color: NebengMotorTheme.primaryBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: NebengMotorTheme.primaryBlue,
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
          onPressed: _isLoading ? null : _handlePayment,
          style: ElevatedButton.styleFrom(
            backgroundColor: NebengMotorTheme.primaryBlue,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
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

  void _handlePayment() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Calculate amounts - use actual trip price
      double amount = widget.trip.price.toDouble();
      double adminFee = widget.paymentMethod == 'cash' ? 0.0 : 15000.0;

      // Handle cash payment separately (no need for virtual account)
      if (widget.paymentMethod == 'cash') {
        // Get user ID for cash payment
        final prefs = await SharedPreferences.getInstance();
        print('All SharedPreferences keys: ${prefs.getKeys()}');
        final userId = prefs.getInt('user_id');
        print('Retrieved user_id: $userId');

        if (userId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('User ID not found. Please login again.')),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }

        // Create booking first
        int? createdBookingId;
        String createdBookingNumber = widget.bookingNumber;
        try {
          print('Creating booking with number: ${widget.bookingNumber}');
          final booking = await ApiService.createBooking(
            rideId: int.tryParse(widget.trip.id) ?? 1,
            userId: userId,
            seats: widget.totalPassengers,
            bookingNumber: widget.bookingNumber,
            rideType: 'motor',
            photoFilePath: widget.photoFile?.path,
            weight: widget.weight,
            description: widget.description,
          );
          print(
              'Booking created for cash payment: ${booking['id']}, booking_number: ${booking['booking_number']}');

          createdBookingId = booking['id'];
          createdBookingNumber =
              booking['booking_number'] ?? widget.bookingNumber;
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to create booking: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }

        // Create cash payment record
        try {
          print(
              'Creating payment with booking number: ${widget.bookingNumber}');
          final paymentResult = await _paymentService.createPayment(
            rideId: int.tryParse(widget.trip.id) ?? 1,
            userId: userId,
            bookingNumber: createdBookingNumber,
            bookingId: createdBookingId,
            paymentMethod: 'cash',
            amount: amount,
            adminFee: 0,
          );
          print('Cash payment created: $paymentResult');

          if (paymentResult['success'] != true) {
            throw Exception(
                paymentResult['message'] ?? 'Failed to create payment');
          }
        } catch (e) {
          print('Failed to create cash payment record: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to create payment: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }

        // For cash, directly go to success page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentSuccessPage(
              trip: widget.trip,
              bookingNumber: widget.bookingNumber,
              passengerName: widget.passengerName,
              phoneNumber: widget.phoneNumber,
              paymentMethod: widget.paymentMethod,
              totalPassengers: widget.totalPassengers,
              amount: amount,
              adminFee: 0, // No admin fee for cash
            ),
          ),
        );
        return;
      }

      // Get user ID from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      print('All SharedPreferences keys (VA): ${prefs.getKeys()}');
      final userId = prefs.getInt('user_id');
      print('Retrieved user_id (VA): $userId');

      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('User ID not found. Please login again.')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Create booking first
      String createdBookingNumber = widget.bookingNumber;
      int? createdBookingId;
      try {
        final booking = await ApiService.createBooking(
          rideId: int.tryParse(widget.trip.id) ?? 1,
          userId: userId,
          seats: widget.totalPassengers,
          bookingNumber: widget.bookingNumber,
          rideType: 'motor',
          photoFilePath: widget.photoFile?.path,
          weight: widget.weight,
          description: widget.description,
        );
        print('Booking created: ${booking['id']}');
        createdBookingId = booking['id'];
        createdBookingNumber =
            booking['booking_number'] ?? widget.bookingNumber;
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create booking: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // For virtual account payments (BRI, BCA, etc.)
      print(
          'Creating VA payment for ride: ${widget.trip.id}, user: $userId, booking: ${widget.bookingNumber}');
      final result = await _paymentService.createPayment(
        rideId: int.tryParse(widget.trip.id) ?? 1,
        userId: userId,
        bookingNumber: createdBookingNumber,
        bookingId: createdBookingId,
        paymentMethod: widget.paymentMethod,
        amount: amount,
        adminFee: adminFee,
      );
      print('VA payment result: $result');

      if (result['success']) {
        final paymentData = result['data']['payment'];
        final vaNumber = result['data']['virtual_account_number'];
        final bankCode = result['data']['bank_code'];
        final expiresAt = DateTime.parse(result['data']['expires_at']);

        // Navigate to payment waiting page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentWaitingPage(
              trip: widget.trip,
              bookingNumber: widget.bookingNumber,
              passengerName: widget.passengerName,
              phoneNumber: widget.phoneNumber,
              paymentMethod: widget.paymentMethod,
              totalPassengers: widget.totalPassengers,
              virtualAccountNumber: vaNumber,
              bankCode: bankCode,
              expiresAt: expiresAt,
              paymentId: paymentData['id'],
              amount: amount,
              adminFee: adminFee,
            ),
          ),
        );
      } else {
        // Show error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to create payment'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
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
