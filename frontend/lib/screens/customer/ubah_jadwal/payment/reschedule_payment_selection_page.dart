import 'package:flutter/material.dart';
import 'reschedule_payment_waiting_page.dart';
import 'reschedule_payment_success_page.dart';
import '../../nebeng_motor/models/trip_model.dart' as motor_model;
import '../../../../services/api_service.dart';

class ReschedulePaymentSelectionPage extends StatefulWidget {
  final int requestId;
  final String paymentTxnId;
  final String virtualAccount;
  final String bankCode;
  final dynamic amount;
  final Map<String, dynamic> bookingData;
  final Map<String, dynamic> newRideData;

  const ReschedulePaymentSelectionPage({
    Key? key,
    required this.requestId,
    required this.paymentTxnId,
    required this.virtualAccount,
    required this.bankCode,
    required this.amount,
    required this.bookingData,
    required this.newRideData,
  }) : super(key: key);

  @override
  State<ReschedulePaymentSelectionPage> createState() =>
      _ReschedulePaymentSelectionPageState();
}

class _ReschedulePaymentSelectionPageState
    extends State<ReschedulePaymentSelectionPage> {
  String? selectedPaymentMethod;

  final List<Map<String, dynamic>> paymentMethods = [
    {
      'id': 'qris',
      'name': 'QRIS',
      'subtitle': '',
      'useIcon': Icons.qr_code,
      'useText': false,
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
          color: isSelected ? const Color(0xFF1E3A8A) : Colors.grey[300]!,
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
                activeColor: const Color(0xFF1E3A8A),
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
        child: ElevatedButton(
          onPressed: selectedPaymentMethod != null ? _handleContinue : null,
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
            'Lanjutkan',
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

  void _handleContinue() async {
    if (selectedPaymentMethod == null) return;

    // Helper to extract location name/address from possible structures
    String extractLocationName(Map<String, dynamic> data,
        {required String mapKey, required String strKey}) {
      try {
        final mapVal = data[mapKey];
        if (mapVal is Map) {
          return (mapVal['name'] ?? mapVal['title'] ?? '').toString();
        }
      } catch (_) {}
      if (data[strKey] != null) return data[strKey].toString();
      return '';
    }

    String extractLocationAddress(Map<String, dynamic> data,
        {required String mapKey, required String addrKey}) {
      try {
        final mapVal = data[mapKey];
        if (mapVal is Map) {
          return (mapVal['address'] ?? mapVal['alamat'] ?? '').toString();
        }
      } catch (_) {}
      if (data[addrKey] != null) return data[addrKey].toString();
      return '';
    }

    final departureLocation = extractLocationName(widget.newRideData,
        mapKey: 'origin_location', strKey: 'from_location');
    final departureAddress = extractLocationAddress(widget.newRideData,
        mapKey: 'origin_location', addrKey: 'from_address');
    final arrivalLocation = extractLocationName(widget.newRideData,
        mapKey: 'destination_location', strKey: 'to_location');
    final arrivalAddress = extractLocationAddress(widget.newRideData,
        mapKey: 'destination_location', addrKey: 'to_address');

    // Convert reschedule data to TripModel format
    final motorTrip = motor_model.TripModel(
      id: widget.newRideData['id']?.toString() ?? '0',
      date: widget.newRideData['departure_date'] ?? '',
      time: widget.newRideData['departure_time'] ?? '',
      departureLocation: departureLocation.isNotEmpty
          ? departureLocation
          : 'Lokasi Keberangkatan',
      departureAddress: departureAddress,
      arrivalLocation:
          arrivalLocation.isNotEmpty ? arrivalLocation : 'Lokasi Tujuan',
      arrivalAddress: arrivalAddress,
      price: (double.tryParse(widget.amount.toString()) ?? 0).toInt(),
      availableSeats: widget.newRideData['available_seats'] ?? 0,
    );

    final bookingNumber = widget.bookingData['booking_number']?.toString() ??
        'RSCH-${widget.requestId}';
    final passengerName = widget.bookingData['user']?['name'] ?? 'Penumpang';
    final totalPassengers = widget.bookingData['seats'] ?? 1;
    final passengers =
        widget.bookingData['penumpang'] as List<Map<String, dynamic>>?;

    if (selectedPaymentMethod == 'cash') {
      // For cash, confirm payment first, then navigate to success page
      motor_model.TripModel updatedTrip = motorTrip;
      try {
        final resp = await ApiService.confirmReschedulePayment(
          requestId: widget.requestId,
          paymentTxnId: widget.paymentTxnId,
          passengers: passengers,
        );

        // If backend returned updated ride data, build a new TripModel
        if (resp['success'] == true && resp['data'] != null) {
          final newRide = resp['data']['new_ride'];
          if (newRide is Map) {
            final depName = newRide['from_location'] ??
                newRide['origin_location']?['name'] ??
                motorTrip.departureLocation;
            final arrName = newRide['to_location'] ??
                newRide['destination_location']?['name'] ??
                motorTrip.arrivalLocation;
            final depAddr = newRide['from_address'] ??
                newRide['origin_location']?['address'] ??
                motorTrip.departureAddress;
            final arrAddr = newRide['to_address'] ??
                newRide['destination_location']?['address'] ??
                motorTrip.arrivalAddress;
            final avail = (newRide['available_seats'] is int)
                ? newRide['available_seats'] as int
                : (int.tryParse(
                        (newRide['available_seats'] ?? '').toString()) ??
                    motorTrip.availableSeats);

            updatedTrip = motor_model.TripModel(
              id: newRide['id']?.toString() ?? motorTrip.id,
              date: newRide['departure_date'] ?? motorTrip.date,
              time: newRide['departure_time'] ?? motorTrip.time,
              departureLocation: depName,
              departureAddress: depAddr ?? motorTrip.departureAddress,
              arrivalLocation: arrName,
              arrivalAddress: arrAddr ?? motorTrip.arrivalAddress,
              price: (double.tryParse(widget.amount.toString()) ?? 0).toInt(),
              availableSeats: avail,
            );
          }
        }
      } catch (e) {
        print('Error confirming reschedule: $e');
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ReschedulePaymentSuccessPage(
            requestId: widget.requestId,
            trip: updatedTrip,
            bookingNumber: bookingNumber,
            passengerName: passengerName,
            phoneNumber: '',
            paymentMethod: selectedPaymentMethod!,
            totalPassengers: totalPassengers,
            amount: double.tryParse(widget.amount.toString()) ?? 0,
            adminFee: 0,
          ),
        ),
      );
    } else {
      // For other payment methods, navigate to waiting page
      DateTime expiresAt = DateTime.now().add(const Duration(hours: 1));

      // Try to parse paymentTxnId as int
      int paymentId = int.tryParse(widget.paymentTxnId) ?? 0;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ReschedulePaymentWaitingPage(
            requestId: widget.requestId,
            paymentTxnId: widget.paymentTxnId,
            trip: motorTrip,
            bookingNumber: bookingNumber,
            passengerName: passengerName,
            phoneNumber: '',
            paymentMethod: selectedPaymentMethod!,
            totalPassengers: totalPassengers,
            virtualAccountNumber: widget.virtualAccount,
            bankCode: widget.bankCode,
            expiresAt: expiresAt,
            paymentId: paymentId,
            amount: double.tryParse(widget.amount.toString()) ?? 0,
            adminFee: 0,
            passengers: passengers,
          ),
        ),
      );
    }
  }
}
