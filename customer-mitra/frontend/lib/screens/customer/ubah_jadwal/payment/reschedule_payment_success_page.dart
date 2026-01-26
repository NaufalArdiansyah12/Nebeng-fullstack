import 'package:flutter/material.dart';
import '../../nebeng_motor/models/trip_model.dart';
import '../../nebeng_motor/utils/theme.dart';

class ReschedulePaymentSuccessPage extends StatefulWidget {
  final int requestId;
  final TripModel trip;
  final String bookingNumber;
  final String passengerName;
  final String phoneNumber;
  final String paymentMethod;
  final int totalPassengers;
  final double amount;
  final double adminFee;
  final Map<String, dynamic>? updatedRides;

  const ReschedulePaymentSuccessPage({
    Key? key,
    required this.requestId,
    required this.trip,
    required this.bookingNumber,
    required this.passengerName,
    required this.phoneNumber,
    required this.paymentMethod,
    required this.totalPassengers,
    required this.amount,
    required this.adminFee,
    this.updatedRides,
  }) : super(key: key);

  @override
  State<ReschedulePaymentSuccessPage> createState() =>
      _ReschedulePaymentSuccessPageState();
}

class _ReschedulePaymentSuccessPageState
    extends State<ReschedulePaymentSuccessPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NebengMotorTheme.primaryBlue,
      appBar: AppBar(
        backgroundColor: NebengMotorTheme.primaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
        title: const Text(
          'Pembayaran',
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
                    _buildSuccessIcon(),
                    const SizedBox(height: 24),
                    _buildPaymentDetailsCard(),
                    const SizedBox(height: 20),
                    _buildTripDetails(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildContinueButton(context),
    );
  }

  Widget _buildSuccessIcon() {
    return Center(
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.receipt_long,
                  size: 50,
                  color: Colors.green.shade400,
                ),
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Pembayaran Berhasil!',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ubah jadwal telah diterapkan',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentDetailsCard() {
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
            'Detail Pembayaran',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildPaymentRow('No. Pemesanan', widget.bookingNumber),
          const SizedBox(height: 12),
          _buildPaymentRow('Metode Pembayaran', _getPaymentMethodName()),
          const SizedBox(height: 12),
          _buildPaymentRow(
              'Biaya Ubah Jadwal', 'Rp ${_formatPrice(widget.amount.toInt())}'),
          if (widget.adminFee > 0) ...[
            const SizedBox(height: 12),
            _buildPaymentRow(
                'Biaya Admin', 'Rp ${_formatPrice(widget.adminFee.toInt())}'),
          ],
          const Divider(height: 24),
          _buildPaymentRow(
            'Total',
            'Rp ${_formatPrice((widget.amount + widget.adminFee).toInt())}',
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: Colors.black87,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
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
          const Text(
            'Detail Perjalanan Baru',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildTripRow(Icons.calendar_today, 'Tanggal', widget.trip.date),
          const SizedBox(height: 12),
          _buildTripRow(Icons.access_time, 'Waktu', widget.trip.time),
          const SizedBox(height: 12),
          _buildTripRow(
              Icons.location_on, 'Dari', widget.trip.departureLocation),
          const SizedBox(height: 12),
          _buildTripRow(
              Icons.location_on_outlined, 'Ke', widget.trip.arrivalLocation),
          const SizedBox(height: 12),
          _buildTripRow(
              Icons.people, 'Penumpang', '${widget.totalPassengers} orang'),
        ],
      ),
    );
  }

  Widget _buildTripRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: NebengMotorTheme.primaryBlue),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContinueButton(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
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
            'Kembali ke Beranda',
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
        return widget.paymentMethod;
    }
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }
}
