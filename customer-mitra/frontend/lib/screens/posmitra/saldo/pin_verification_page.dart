import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'withdrawal_processing_page.dart';
import '/services/posmitra/posmitra_service.dart';

class PinVerificationPage extends StatefulWidget {
  final double amount;
  final String bankName;
  final String accountNumber;

  const PinVerificationPage({
    Key? key,
    required this.amount,
    required this.bankName,
    required this.accountNumber,
  }) : super(key: key);

  @override
  State<PinVerificationPage> createState() => _PinVerificationPageState();
}

class _PinVerificationPageState extends State<PinVerificationPage> {
  String pin = '';
  final int pinLength = 6;

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

  Future<void> _verifyPin() async {
    // Tampilkan loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');

      if (token == null || token.isEmpty) {
        Navigator.pop(context); // Tutup loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Token tidak ditemukan. Silakan login kembali.'),
            backgroundColor: Color(0xFFEF5350),
          ),
        );
        return;
      }

      // ✅ KIRIM DATA KE API BACKEND
      final response = await PosMitraService.withdrawBalance(
        token: token,
        amount: widget.amount,
        bankName: widget.bankName,
        accountNumber: widget.accountNumber,
        pin: pin,
      );

      Navigator.pop(context); // Tutup loading

      if (response['success'] == true) {
        // ✅ BERHASIL - Navigasi ke halaman processing
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => WithdrawalProcessingPage(
              amount: widget.amount,
              status: 'pending', 
            ),
          ),
        );
      } else {
        // ❌ GAGAL - Tampilkan error dan reset PIN
        setState(() {
          pin = '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Penarikan gagal'),
            backgroundColor: const Color(0xFFEF5350),
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Tutup loading
      setState(() {
        pin = '';
      });
      
      // Cek apakah error dari PIN salah
      String errorMessage = 'Terjadi kesalahan: $e';
      if (e.toString().contains('PIN salah')) {
        errorMessage = 'PIN yang Anda masukkan salah';
      } else if (e.toString().contains('Saldo tidak mencukupi')) {
        errorMessage = 'Saldo tidak mencukupi';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: const Color(0xFFEF5350),
        ),
      );
    }
  }

  String _formatCurrency(double amount) {
    final formatted = amount.toStringAsFixed(0);
    final regex = RegExp(r'\B(?=(\d{3})+(?!\d))');
    return formatted.replaceAllMapped(regex, (match) => '.');
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
          'Verifikasi PIN',
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  
                  // ✅ KONFIRMASI DATA
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Konfirmasi Penarikan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF212121),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow('Jumlah', 'Rp ${_formatCurrency(widget.amount)}'),
                        const SizedBox(height: 8),
                        _buildInfoRow('Bank', widget.bankName),
                        const SizedBox(height: 8),
                        _buildInfoRow('No. Rekening', widget.accountNumber),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
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
                // Lanjut Button
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

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF757575),
            fontWeight: FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF212121),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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