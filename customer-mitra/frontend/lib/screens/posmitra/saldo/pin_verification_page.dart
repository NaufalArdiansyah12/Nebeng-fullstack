import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'withdrawal_processing_page.dart';
import '/services/posmitra/posmitra_service.dart';

class PinVerificationPage extends StatefulWidget {
  final double amount;
  final String bankName;
  final String accountNumber;
  final String accountName; // ← Tambahkan parameter

  const PinVerificationPage({
    Key? key,
    required this.amount,
    required this.bankName,
    required this.accountNumber,
    required this.accountName, // ← Tambahkan parameter
  }) : super(key: key);

  @override
  State<PinVerificationPage> createState() => _PinVerificationPageState();
}

class _PinVerificationPageState extends State<PinVerificationPage> {
  String pin = '';
  final int pinLength = 6;
  bool _isLoading = false;
  bool _isLoadingProfile = true;
  
  // Data dari database
  String userName = '-';
  String userBankName = '';
  String userAccountNumber = '';
  String userAccountName = '';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  // ✅ Load data rekening dari database
  Future<void> _loadUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');

      if (token == null || token.isEmpty) {
        setState(() {
          _isLoadingProfile = false;
        });
        return;
      }

      final response = await PosMitraService.getProfile(token);
      
      if (response['success'] == true) {
        final userData = response['data']?['user'] as Map<String, dynamic>?;
        
        setState(() {
          userName = userData?['name'] ?? 'User';
          userBankName = userData?['bank_name'] ?? widget.bankName;
          userAccountNumber = userData?['bank_account_number'] ?? widget.accountNumber;
          userAccountName = userData?['bank_account_name'] ?? widget.accountName;
          _isLoadingProfile = false;
        });
      } else {
        setState(() {
          userName = 'User';
          userBankName = widget.bankName;
          userAccountNumber = widget.accountNumber;
          userAccountName = widget.accountName;
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      print('Error loading profile: $e');
      setState(() {
        userName = 'User';
        userBankName = widget.bankName;
        userAccountNumber = widget.accountNumber;
        userAccountName = widget.accountName;
        _isLoadingProfile = false;
      });
    }
  }

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
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');

      if (token == null || token.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Token tidak ditemukan. Silakan login kembali.'),
            backgroundColor: Color(0xFFEF5350),
          ),
        );
        return;
      }

      // ✅ KIRIM DATA KE API BACKEND (gunakan data dari database)
      final response = await PosMitraService.withdrawBalance(
        token: token,
        amount: widget.amount,
        bankName: userBankName,
        accountNumber: userAccountNumber,
        accountName: userAccountName,
        pin: pin,
      );

      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;

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
      setState(() {
        _isLoading = false;
        pin = '';
      });

      if (!mounted) return;

      // Cek apakah error dari PIN salah
      String errorMessage = 'Terjadi kesalahan';
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
      body: _isLoadingProfile
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1E3A8A),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // ✅ KONFIRMASI DATA (dari database)
                        Container(
                          padding: const EdgeInsets.all(16),
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
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF212121),
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildInfoRow('Jumlah', 'Rp ${_formatCurrency(widget.amount)}'),
                              const SizedBox(height: 6),
                              _buildInfoRow('Bank', userBankName),
                              const SizedBox(height: 6),
                              _buildInfoRow('No. Rekening', userAccountNumber),
                              const SizedBox(height: 6),
                              _buildInfoRow('Atas Nama', userAccountName),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Lock Icon
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E3A8A).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.lock_outline,
                            size: 36,
                            color: Color(0xFF1E3A8A),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Title
                        const Text(
                          'Masukkan PIN yang telah Anda buat',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF212121),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),

                        // Subtitle
                        const Text(
                          'PIN berupa 6 digit angka',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF757575),
                            fontWeight: FontWeight.w400,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),

                        // PIN Dots
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            pinLength,
                            (index) => Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: Container(
                                width: 45,
                                height: 45,
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
                                          width: 10,
                                          height: 10,
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
                        const SizedBox(height: 16),
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
                      // Lanjut Button dengan Loading
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: (pin.length == pinLength && !_isLoading) ? _verifyPin : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A8A),
                            disabledBackgroundColor: const Color(0xFFE0E0E0),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
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
                              : Text(
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
                      const SizedBox(height: 12),

                      // Number Pad
                      Column(
                        children: [
                          Row(
                            children: [
                              _buildNumberButton('1'),
                              const SizedBox(width: 8),
                              _buildNumberButton('2'),
                              const SizedBox(width: 8),
                              _buildNumberButton('3'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildNumberButton('4'),
                              const SizedBox(width: 8),
                              _buildNumberButton('5'),
                              const SizedBox(width: 8),
                              _buildNumberButton('6'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildNumberButton('7'),
                              const SizedBox(width: 8),
                              _buildNumberButton('8'),
                              const SizedBox(width: 8),
                              _buildNumberButton('9'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Expanded(child: SizedBox()),
                              const SizedBox(width: 8),
                              _buildNumberButton('0'),
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
            fontSize: 13,
            color: Color(0xFF757575),
            fontWeight: FontWeight.w400,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF212121),
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildNumberButton(String number) {
    return Expanded(
      child: InkWell(
        onTap: _isLoading ? null : () => _onNumberPressed(number),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: _isLoading ? const Color(0xFFEEEEEE) : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: _isLoading ? const Color(0xFFBDBDBD) : const Color(0xFF212121),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return Expanded(
      child: InkWell(
        onTap: _isLoading ? null : _onDeletePressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: _isLoading ? const Color(0xFFEEEEEE) : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Icon(
              Icons.backspace_outlined,
              color: _isLoading ? const Color(0xFFBDBDBD) : const Color(0xFF424242),
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}