import 'package:flutter/material.dart';
import '../models/trip_model.dart';
import '../utils/theme.dart';
import 'payment_method_page.dart';
import '../../../../widgets/loading_button.dart';

class PaymentSelectionPage extends StatefulWidget {
  final TripModel trip;
  final String bookingNumber;
  final String passengerName;
  final String phoneNumber;
  final int totalPassengers;
  final List<Map<String, dynamic>>? penumpang;

  const PaymentSelectionPage({
    Key? key,
    required this.trip,
    required this.bookingNumber,
    required this.passengerName,
    required this.phoneNumber,
    this.totalPassengers = 1,
    this.penumpang,
  }) : super(key: key);

  @override
  State<PaymentSelectionPage> createState() => _PaymentSelectionPageState();
}

class _PaymentSelectionPageState extends State<PaymentSelectionPage> {
  String? selectedPaymentMethod;

  final List<Map<String, dynamic>> paymentMethods = [
    {
      'id': 'qris',
      'name': 'QRIS',
      'subtitle': 'Pindai QR pengemudi untuk membayar',
      'icon': 'assets/icons/qris.png',
      'useText': true,
    },
    {
      'id': 'cash',
      'name': 'Tunai',
      'subtitle': '',
      'icon': 'assets/icons/cash.png',
      'useIcon': Icons.money,
    },
    {
      'id': 'bri',
      'name': 'BRI Virtual Account',
      'subtitle': '',
      'icon': 'assets/icons/bri.png',
      'useText': true,
    },
    {
      'id': 'bca',
      'name': 'BCA Virtual Account',
      'subtitle': '',
      'icon': 'assets/icons/bca.png',
      'useText': true,
    },
    {
      'id': 'dana',
      'name': 'Dana',
      'subtitle': '',
      'icon': 'assets/icons/dana.png',
      'useText': true,
    },
  ];

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
          'Pilih Pembayaran',
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
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: paymentMethods.length,
                itemBuilder: (context, index) {
                  final method = paymentMethods[index];
                  return _buildPaymentMethodTile(method);
                },
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildContinueButton(),
    );
  }

  Widget _buildPaymentMethodTile(Map<String, dynamic> method) {
    final isSelected = selectedPaymentMethod == method['id'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? NebengMobilTheme.primaryBlue : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            selectedPaymentMethod = method['id'];
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildPaymentIcon(method),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method['name'],
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    if (method['subtitle'] != null &&
                        method['subtitle'].isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          method['subtitle'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Radio<String>(
                value: method['id'],
                groupValue: selectedPaymentMethod,
                onChanged: (value) {
                  setState(() {
                    selectedPaymentMethod = value;
                  });
                },
                activeColor: NebengMobilTheme.primaryBlue,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentIcon(Map<String, dynamic> method) {
    // Cash icon
    if (method['useIcon'] != null) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          method['useIcon'],
          size: 28,
          color: Colors.black87,
        ),
      );
    }

    // Branded payment method icons with colors
    Color bgColor;
    Color textColor;
    String displayText;

    switch (method['id']) {
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
        displayText = method['id'].toString().toUpperCase();
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: method['id'] == 'qris'
            ? Border.all(color: Colors.grey[300]!, width: 1)
            : null,
      ),
      child: Center(
        child: Text(
          displayText,
          style: TextStyle(
            fontSize: method['id'] == 'dana' ? 11 : 12,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: SafeArea(
        child: LoadingButton(
          onPressed: selectedPaymentMethod != null
              ? () async {
                  _handleContinue();
                }
              : null,
          enabled: selectedPaymentMethod != null,
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
            'Pesan Sekarang',
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

  void _handleContinue() {
    if (selectedPaymentMethod == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentMethodPage(
          trip: widget.trip,
          bookingNumber: widget.bookingNumber,
          passengerName: widget.passengerName,
          phoneNumber: widget.phoneNumber,
          paymentMethod: selectedPaymentMethod!,
          totalPassengers: widget.totalPassengers,
          penumpang: widget.penumpang,
        ),
      ),
    );
  }
}
