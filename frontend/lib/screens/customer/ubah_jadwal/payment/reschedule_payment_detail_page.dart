import 'package:flutter/material.dart';
import 'reschedule_payment_selection_page.dart';

class ReschedulePaymentDetailPage extends StatefulWidget {
  final int requestId;
  final String paymentTxnId;
  final String virtualAccount;
  final String bankCode;
  final dynamic amount;
  final Map<String, dynamic> bookingData;
  final Map<String, dynamic> newRideData;
  final double priceBefore;
  final double priceAfter;
  final double priceDiff;
  final int totalPassengers;
  final List<Map<String, dynamic>> passengers;

  const ReschedulePaymentDetailPage({
    Key? key,
    required this.requestId,
    required this.paymentTxnId,
    required this.virtualAccount,
    required this.bankCode,
    required this.amount,
    required this.bookingData,
    required this.newRideData,
    required this.priceBefore,
    required this.priceAfter,
    required this.priceDiff,
    this.totalPassengers = 1,
    this.passengers = const [],
  }) : super(key: key);

  @override
  State<ReschedulePaymentDetailPage> createState() =>
      _ReschedulePaymentDetailPageState();
}

class _ReschedulePaymentDetailPageState
    extends State<ReschedulePaymentDetailPage> {
  bool agreeToTerms = false;
  bool _isExpanded = false;
  late int currentPassengerCount;
  late List<Map<String, dynamic>> passengers;

  @override
  void initState() {
    super.initState();
    // Use passengers from widget (passed from detail page)
    passengers =
        widget.passengers.isNotEmpty ? List.from(widget.passengers) : [];
    currentPassengerCount = passengers.length;
  }

  double get pricePerSeat {
    // Prefer explicit price information from new ride data if available
    final dynamic ridePrice =
        widget.newRideData['price_per_seat'] ?? widget.newRideData['price'];
    if (ridePrice != null) {
      final p = double.tryParse(ridePrice.toString()) ?? 0;
      if (p > 0) return p;
    }

    // Fallback: if `priceAfter` represents total for the original booking,
    // divide by original passenger count to get per-seat price.
    final pa = widget.priceAfter;
    final origSeats = widget.totalPassengers <= 0 ? 1 : widget.totalPassengers;
    final p = pa / origSeats;
    if (p > 0) return p;

    return 0;
  }

  double get newTotalPrice {
    // Total price for new ride with current passenger count
    return pricePerSeat * currentPassengerCount;
  }

  double get currentTotalPrice {
    // Calculate difference: new price - old price
    return newTotalPrice - widget.priceBefore;
  }

  double get currentTotalAmount {
    // Total payment: absolute difference + admin fee (always positive)
    return currentTotalPrice.abs() + 15000;
  }

  String _formatAmount(dynamic amount) {
    final numAmount = double.tryParse(amount.toString()) ?? 0;
    return 'Rp${numAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  void _continueToPayment() {
    if (!agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon setujui syarat dan ketentuan terlebih dahulu'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReschedulePaymentSelectionPage(
          requestId: widget.requestId,
          paymentTxnId: widget.paymentTxnId,
          virtualAccount: widget.virtualAccount,
          bankCode: widget.bankCode,
          amount: currentTotalAmount,
          bookingData: {
            ...widget.bookingData,
            'seats': currentPassengerCount,
            'penumpang': passengers,
          },
          newRideData: widget.newRideData,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = widget.newRideData['departure_date'] ?? '04 September 2024';
    final timeStr =
        '${widget.newRideData['departure_time'] ?? '09:00'} - ${widget.newRideData['arrival_time'] ?? '13:00'}';
    final fromLocation = widget.newRideData['from_location'] ?? 'Yogyakarta';
    final toLocation = widget.newRideData['to_location'] ?? 'Purwokerto';
    final vehicleName =
        widget.newRideData['vehicle']?['name'] ?? 'Mobil Avanza';
    final vehiclePlate =
        widget.newRideData['vehicle']?['plate_number'] ?? 'R 2424 MJ';

    return Scaffold(
      backgroundColor: const Color(0xFF1E3A8A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton(
            icon: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Color(0xFF1E3A8A),
                size: 18,
              ),
            ),
            onPressed: () => Navigator.pop(context),
          ),
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
                    // Perjalanan Section
                    const Text(
                      'Perjalanan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$dateStr  •  $timeStr',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Text(
                                fromLocation,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.arrow_forward,
                                size: 18,
                                color: Colors.black54,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                toLocation,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Text(
                                vehicleName,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.grey[400],
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                vehiclePlate,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: () {
                              // Show more details if needed
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      _formatAmount(currentTotalPrice +
                                          widget.priceBefore),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.keyboard_arrow_down,
                                      size: 20,
                                      color: Colors.grey[600],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Penumpang Section
                    // Penumpang Section (Read-only)
                    const Text(
                      'Penumpang',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        children: [
                          for (int i = 0; i < passengers.length; i++)
                            Padding(
                              padding: EdgeInsets.only(
                                bottom: i < passengers.length - 1 ? 12 : 0,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E3A8A)
                                          .withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${i + 1}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF1E3A8A),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          passengers[i]['name'] ?? 'Penumpang',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        if (passengers[i]['phone'] != null &&
                                            passengers[i]['phone'].isNotEmpty)
                                          Text(
                                            passengers[i]['phone'],
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Rincian Harga Section
                    const Text(
                      'Rincian Harga',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        children: [
                          _buildPriceRow(
                            'Nebeng Mobil (Baru)',
                            _formatAmount(newTotalPrice),
                            subtitle:
                                '$currentPassengerCount Penumpang × ${_formatAmount(pricePerSeat)}',
                          ),
                          const SizedBox(height: 12),
                          _buildPriceRow(
                            'Harga Sebelumnya',
                            _formatAmount(widget.priceBefore),
                            subtitle: '${widget.totalPassengers} Penumpang',
                          ),
                          const SizedBox(height: 12),
                          _buildPriceRow(
                            'Selisih Harga',
                            _formatAmount(currentTotalPrice.abs()),
                          ),
                          const SizedBox(height: 12),
                          _buildPriceRow(
                            'Biaya Admin',
                            _formatAmount(15000),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  _formatAmount(currentTotalAmount),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1E3A8A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Terms and Conditions
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: () {
                              setState(() {
                                _isExpanded = !_isExpanded;
                              });
                            },
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.description,
                                  size: 20,
                                  color: Color(0xFF1E3A8A),
                                ),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'Syarat dan Ketentuan',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
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
                          if (_isExpanded) ...[
                            const SizedBox(height: 12),
                            Container(
                              height: 1,
                              color: Colors.grey[200],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '1. Biaya ubah jadwal tidak dapat dikembalikan\n'
                              '2. Ubah jadwal hanya dapat dilakukan 1x24 jam sebelum keberangkatan\n'
                              '3. Ketersediaan kursi tergantung pada jadwal yang dipilih\n'
                              '4. Pembayaran harus diselesaikan dalam 24 jam\n'
                              '5. Setelah pembayaran dikonfirmasi, jadwal baru akan berlaku',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                                height: 1.6,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Checkbox(
                                value: agreeToTerms,
                                onChanged: (value) {
                                  setState(() {
                                    agreeToTerms = value ?? false;
                                  });
                                },
                                activeColor: const Color(0xFF1E3A8A),
                              ),
                              Expanded(
                                child: Text(
                                  'Saya telah membaca dan setuju terhadap syarat dan ketentuan pembelian tiket',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: agreeToTerms ? _continueToPayment : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
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
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, String amount, {String? subtitle}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
        ),
        Text(
          amount,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
