import 'package:flutter/material.dart';
import 'withdrawal_processing_page.dart';

class PinVerificationPage extends StatefulWidget {
  final double amount;

  const PinVerificationPage({
    Key? key,
    required this.amount,
  }) : super(key: key);

  @override
  State<PinVerificationPage> createState() => _PinVerificationPageState();
}

class _PinVerificationPageState extends State<PinVerificationPage> {
  String pin = '';
  final int pinLength = 6;
  final String correctPin = '123456'; // Demo PIN

  void _onNumberPressed(String number) {
    if (pin.length < pinLength) {
      setState(() {
        pin += number;
      });

      // Auto verify when PIN is complete
      if (pin.length == pinLength) {
        Future.delayed(const Duration(milliseconds: 300), () {
          _verifyPin();
        });
      }
    }
  }

  void _onDeletePressed() {
    if (pin.isNotEmpty) {
      setState(() {
        pin = pin.substring(0, pin.length - 1);
      });
    }
  }

  void _verifyPin() {
    if (pin == correctPin) {
      // PIN correct - navigate to processing page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => WithdrawalProcessingPage(amount: widget.amount),
        ),
      );
    } else {
      // PIN incorrect - show error
      setState(() {
        pin = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PIN yang Anda masukkan salah'),
          backgroundColor: Color(0xFFEF5350),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF212121)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Tarik Saldo',
          style: TextStyle(
            color: Color(0xFF212121),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Lock Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A8A).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_outline,
                    size: 40,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                const SizedBox(height: 24),
                // Title
                const Text(
                  'Masukkan PIN yang telah Anda buat',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF212121),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                // Subtitle
                const Text(
                  'PIN berupa 6 digit angka',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF757575),
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                // PIN Dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    pinLength,
                    (index) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: pin.length > index
                                ? const Color(0xFF1E3A8A)
                                : const Color(0xFFE0E0E0),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: pin.length > index
                              ? Container(
                                  width: 12,
                                  height: 12,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF1E3A8A),
                                    shape: BoxShape.circle,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Numpad
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Lanjut Button (only enabled when PIN is complete)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: pin.length == pinLength ? _verifyPin : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      disabledBackgroundColor: const Color(0xFFE0E0E0),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Lanjut',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: pin.length == pinLength
                            ? Colors.white
                            : const Color(0xFF9E9E9E),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Number Pad
                Column(
                  children: [
                    // Row 1: 1, 2, 3
                    Row(
                      children: [
                        _buildNumberButton('1', 'ABC'),
                        const SizedBox(width: 8),
                        _buildNumberButton('2', 'ABC'),
                        const SizedBox(width: 8),
                        _buildNumberButton('3', 'DEF'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Row 2: 4, 5, 6
                    Row(
                      children: [
                        _buildNumberButton('4', 'GHI'),
                        const SizedBox(width: 8),
                        _buildNumberButton('5', 'JKL'),
                        const SizedBox(width: 8),
                        _buildNumberButton('6', 'MNO'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Row 3: 7, 8, 9
                    Row(
                      children: [
                        _buildNumberButton('7', 'PQRS'),
                        const SizedBox(width: 8),
                        _buildNumberButton('8', 'TUV'),
                        const SizedBox(width: 8),
                        _buildNumberButton('9', 'WXYZ'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Row 4: 0, Delete
                    Row(
                      children: [
                        const Expanded(child: SizedBox()),
                        const SizedBox(width: 8),
                        _buildNumberButton('0', ''),
                        const SizedBox(width: 8),
                        _buildDeleteButton(),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberButton(String number, String letters) {
    return Expanded(
      child: InkWell(
        onTap: () => _onNumberPressed(number),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                number,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF212121),
                ),
              ),
              if (letters.isNotEmpty)
                Text(
                  letters,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF757575),
                    fontWeight: FontWeight.w400,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return Expanded(
      child: InkWell(
        onTap: _onDeletePressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Icon(
              Icons.backspace_outlined,
              color: Color(0xFF424242),
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}