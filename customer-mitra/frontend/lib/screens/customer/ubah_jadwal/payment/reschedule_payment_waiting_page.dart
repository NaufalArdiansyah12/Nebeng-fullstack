import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../nebeng_motor/models/trip_model.dart';
import '../../nebeng_motor/utils/theme.dart';
import '../../../../services/payment_service.dart';
import '../../../../services/api_service.dart';
import 'reschedule_payment_success_page.dart';

class ReschedulePaymentWaitingPage extends StatefulWidget {
  final int requestId;
  final String paymentTxnId;
  final TripModel trip;
  final String bookingNumber;
  final String passengerName;
  final String phoneNumber;
  final String paymentMethod;
  final int totalPassengers;
  final String virtualAccountNumber;
  final String bankCode;
  final DateTime expiresAt;
  final int paymentId;
  final double amount;
  final double adminFee;
  final List<Map<String, dynamic>>? passengers;

  const ReschedulePaymentWaitingPage({
    Key? key,
    required this.requestId,
    required this.paymentTxnId,
    required this.trip,
    required this.bookingNumber,
    required this.passengerName,
    required this.phoneNumber,
    required this.paymentMethod,
    required this.totalPassengers,
    required this.virtualAccountNumber,
    required this.bankCode,
    required this.expiresAt,
    required this.paymentId,
    required this.amount,
    required this.adminFee,
    this.passengers,
  }) : super(key: key);

  @override
  State<ReschedulePaymentWaitingPage> createState() =>
      _ReschedulePaymentWaitingPageState();
}

class _ReschedulePaymentWaitingPageState
    extends State<ReschedulePaymentWaitingPage> {
  late Timer _countdownTimer;
  late Timer _statusCheckTimer;
  Duration _remainingTime = Duration.zero;
  final PaymentService _paymentService = PaymentService();

  @override
  void initState() {
    super.initState();
    _startCountdown();
    _startStatusCheck();
  }

  @override
  void dispose() {
    _countdownTimer.cancel();
    _statusCheckTimer.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _remainingTime = widget.expiresAt.difference(DateTime.now());

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remainingTime = widget.expiresAt.difference(DateTime.now());

        if (_remainingTime.isNegative || _remainingTime.inSeconds <= 0) {
          _countdownTimer.cancel();
          _statusCheckTimer.cancel();
          _showPaymentExpired();
        }
      });
    });
  }

  void _startStatusCheck() {
    // Check payment status every 5 seconds
    _statusCheckTimer =
        Timer.periodic(const Duration(seconds: 5), (timer) async {
      final result = await _paymentService.checkPaymentStatus(widget.paymentId);

      if (result['success'] && result['data']['status'] == 'paid') {
        _countdownTimer.cancel();
        _statusCheckTimer.cancel();

        // Confirm reschedule payment to backend and get updated ride data
        try {
          final resp = await ApiService.confirmReschedulePayment(
            requestId: widget.requestId,
            paymentTxnId: widget.paymentTxnId,
            passengers: widget.passengers,
          );

          if (resp['success'] == true && resp['data'] != null) {
            final newRide = resp['data']['new_ride'];
            if (newRide is Map) {
              final depName = newRide['from_location'] ??
                  newRide['origin_location']?['name'] ??
                  widget.trip.departureLocation;
              final arrName = newRide['to_location'] ??
                  newRide['destination_location']?['name'] ??
                  widget.trip.arrivalLocation;
              final depAddr = newRide['from_address'] ??
                  newRide['origin_location']?['address'] ??
                  widget.trip.departureAddress;
              final arrAddr = newRide['to_address'] ??
                  newRide['destination_location']?['address'] ??
                  widget.trip.arrivalAddress;
              final avail = (newRide['available_seats'] is int)
                  ? newRide['available_seats'] as int
                  : (int.tryParse(
                          (newRide['available_seats'] ?? '').toString()) ??
                      widget.trip.availableSeats);

              final updatedTrip = TripModel(
                id: newRide['id']?.toString() ?? widget.trip.id,
                date: newRide['departure_date'] ?? widget.trip.date,
                time: newRide['departure_time'] ?? widget.trip.time,
                departureLocation: depName,
                departureAddress: depAddr ?? widget.trip.departureAddress,
                arrivalLocation: arrName,
                arrivalAddress: arrAddr ?? widget.trip.arrivalAddress,
                price: widget.amount.toInt(),
                availableSeats: avail,
              );

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => ReschedulePaymentSuccessPage(
                    requestId: widget.requestId,
                    trip: updatedTrip,
                    bookingNumber: widget.bookingNumber,
                    passengerName: widget.passengerName,
                    phoneNumber: widget.phoneNumber,
                    paymentMethod: widget.paymentMethod,
                    totalPassengers: widget.totalPassengers,
                    amount: widget.amount,
                    adminFee: widget.adminFee,
                  ),
                ),
              );
              return;
            }
          }
        } catch (e) {
          print('Error confirming reschedule: $e');
        }

        _navigateToSuccessPage();
      }
    });
  }

  void _navigateToSuccessPage() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ReschedulePaymentSuccessPage(
          requestId: widget.requestId,
          trip: widget.trip,
          bookingNumber: widget.bookingNumber,
          passengerName: widget.passengerName,
          phoneNumber: widget.phoneNumber,
          paymentMethod: widget.paymentMethod,
          totalPassengers: widget.totalPassengers,
          amount: widget.amount,
          adminFee: widget.adminFee,
        ),
      ),
    );
  }

  void _showPaymentExpired() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Pembayaran Kedaluwarsa'),
        content: const Text(
            'Waktu pembayaran telah habis. Silakan buat pembayaran baru.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _formatCountdown() {
    final hours = _remainingTime.inHours.toString().padLeft(2, '0');
    final minutes = (_remainingTime.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (_remainingTime.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  String _formatExpiryDate() {
    final date = widget.expiresAt;
    final months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];

    return 'Kamis, ${date.day} ${months[date.month - 1]} ${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
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
          'Selesaikan Pembayaran',
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
                    _buildCountdownSection(),
                    const SizedBox(height: 24),
                    _buildVirtualAccountCard(),
                    const SizedBox(height: 24),
                    _buildTripDetails(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildCheckStatusButton(),
    );
  }

  Widget _buildCountdownSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          const Text(
            'Sisa waktu pembayaran :',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTimeBox(_remainingTime.inHours.toString().padLeft(2, '0')),
              const SizedBox(width: 8),
              _buildTimeBox(
                  (_remainingTime.inMinutes % 60).toString().padLeft(2, '0')),
              const SizedBox(width: 8),
              _buildTimeBox(
                  (_remainingTime.inSeconds % 60).toString().padLeft(2, '0')),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Batas Akhir Pembayaran',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatExpiryDate(),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeBox(String time) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: NebengMotorTheme.primaryBlue,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          time,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildVirtualAccountCard() {
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
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: widget.bankCode == 'BRI'
                      ? const Color(0xFF003D7A)
                      : Colors.blue,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.account_balance,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'BANK ${widget.bankCode}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Nomor Virtual Account',
            style: TextStyle(
              fontSize: 13,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.virtualAccountNumber,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  letterSpacing: 1,
                ),
              ),
              IconButton(
                onPressed: () {
                  Clipboard.setData(
                      ClipboardData(text: widget.virtualAccountNumber));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Nomor VA disalin'),
                      duration: Duration(seconds: 2),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                icon: const Icon(Icons.copy, size: 20),
                color: NebengMotorTheme.primaryBlue,
              ),
            ],
          ),
          const Divider(height: 32),
          const Text(
            'Total Pembayaran',
            style: TextStyle(
              fontSize: 13,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Rp ${_formatPrice((widget.amount + widget.adminFee).toInt())}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
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
          const Text(
            'Detail Perjalanan',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow(Icons.calendar_today, '${widget.trip.date}'),
          const SizedBox(height: 12),
          _buildDetailRow(Icons.access_time, widget.trip.time),
          const SizedBox(height: 12),
          _buildDetailRow(Icons.location_on, widget.trip.departureLocation),
          const SizedBox(height: 12),
          _buildDetailRow(
              Icons.location_on_outlined, widget.trip.arrivalLocation),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckStatusButton() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: () async {
            // Manual check status
            final result =
                await _paymentService.checkPaymentStatus(widget.paymentId);

            if (result['success'] && result['data']['status'] == 'paid') {
              _countdownTimer.cancel();
              _statusCheckTimer.cancel();

              // Confirm reschedule payment and get updated ride data
              try {
                final resp = await ApiService.confirmReschedulePayment(
                  requestId: widget.requestId,
                  paymentTxnId: widget.paymentTxnId,
                  passengers: widget.passengers,
                );

                if (resp['success'] == true && resp['data'] != null) {
                  final newRide = resp['data']['new_ride'];
                  if (newRide is Map) {
                    final depName = newRide['from_location'] ??
                        newRide['origin_location']?['name'] ??
                        widget.trip.departureLocation;
                    final arrName = newRide['to_location'] ??
                        newRide['destination_location']?['name'] ??
                        widget.trip.arrivalLocation;
                    final depAddr = newRide['from_address'] ??
                        newRide['origin_location']?['address'] ??
                        widget.trip.departureAddress;
                    final arrAddr = newRide['to_address'] ??
                        newRide['destination_location']?['address'] ??
                        widget.trip.arrivalAddress;
                    final avail = (newRide['available_seats'] is int)
                        ? newRide['available_seats'] as int
                        : (int.tryParse((newRide['available_seats'] ?? '')
                                .toString()) ??
                            widget.trip.availableSeats);

                    final updatedTrip = TripModel(
                      id: newRide['id']?.toString() ?? widget.trip.id,
                      date: newRide['departure_date'] ?? widget.trip.date,
                      time: newRide['departure_time'] ?? widget.trip.time,
                      departureLocation: depName,
                      departureAddress: depAddr ?? widget.trip.departureAddress,
                      arrivalLocation: arrName,
                      arrivalAddress: arrAddr ?? widget.trip.arrivalAddress,
                      price: widget.amount.toInt(),
                      availableSeats: avail,
                    );

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReschedulePaymentSuccessPage(
                          requestId: widget.requestId,
                          trip: updatedTrip,
                          bookingNumber: widget.bookingNumber,
                          passengerName: widget.passengerName,
                          phoneNumber: widget.phoneNumber,
                          paymentMethod: widget.paymentMethod,
                          totalPassengers: widget.totalPassengers,
                          amount: widget.amount,
                          adminFee: widget.adminFee,
                        ),
                      ),
                    );
                    return;
                  }
                }
              } catch (e) {
                print('Error confirming reschedule: $e');
              }

              _navigateToSuccessPage();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Pembayaran belum diterima'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: NebengMotorTheme.primaryBlue,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ),
          child: const Text(
            'Cek Status Pembayaran',
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

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }
}
