import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/withdrawal_model.dart';
import '../../../services/mitra/withdrawal_service.dart';
import 'withdrawal_progress_page.dart';

class PinVerificationPage extends StatefulWidget {
  final double amount;
  final BalanceInfo balanceInfo;

  const PinVerificationPage({
    super.key,
    required this.amount,
    required this.balanceInfo,
  });

  @override
  State<PinVerificationPage> createState() => _PinVerificationPageState();
}

class _PinVerificationPageState extends State<PinVerificationPage> {
  final List<TextEditingController> _pinControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    for (var controller in _pinControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  String _getPin() {
    return _pinControllers.map((c) => c.text).join();
  }

  bool _isPinComplete() {
    return _getPin().length == 6;
  }

  void _onPinChanged(int index, String value) {
    setState(() {
      _errorMessage = null;
    });

    // Auto submit when complete
    if (_isPinComplete()) {
      _submitWithdrawal();
    }
  }

  void _onPinBackspace(int index) {
    // Not needed anymore with custom keyboard
  }

  Future<void> _submitWithdrawal() async {
    if (!_isPinComplete() || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');

      if (token == null) {
        throw Exception('Token tidak ditemukan');
      }

      final pin = _getPin();
      final result = await WithdrawalService.submitWithdrawal(
        token: token,
        amount: widget.amount,
        pin: pin,
      );

      if (!mounted) return;

      // Navigate to progress page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => WithdrawalProgressPage(
            withdrawalId: result['withdrawal_id'],
            transactionId: result['transaction_id'],
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isSubmitting = false;
      });

      // Clear PIN fields on error
      for (var controller in _pinControllers) {
        controller.clear();
      }
      setState(() {});
    }
  }

  void _onNumberPressed(String number) {
    if (_isSubmitting) return;

    final pin = _getPin();
    if (pin.length < 6) {
      final index = pin.length;
      _pinControllers[index].text = number;
      _onPinChanged(index, number);
    }
  }

  void _onBackspacePressed() {
    if (_isSubmitting) return;

    final pin = _getPin();
    if (pin.isNotEmpty) {
      final index = pin.length - 1;
      _pinControllers[index].clear();
      setState(() {
        _errorMessage = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
        ),
        title: const Text(
          'Tarik Saldo',
          style: TextStyle(
            color: Colors.black,
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
                Icon(
                  Icons.lock_outline,
                  size: 80,
                  color: const Color(0xFF1E3A8A),
                ),
                const SizedBox(height: 32),

                // Title
                const Text(
                  'Masukkan PIN yang telah Anda buat',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle
                const Text(
                  'PIN berupa 6 digit angka',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 48),

                // PIN Dots Display
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(6, (index) {
                    final hasValue = _pinControllers[index].text.isNotEmpty;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: hasValue
                            ? const Color(0xFF1E3A8A)
                            : Colors.transparent,
                        border: Border.all(
                          color: hasValue
                              ? const Color(0xFF1E3A8A)
                              : Colors.grey.shade400,
                          width: 2,
                        ),
                      ),
                    );
                  }),
                ),

                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                      ),
                    ),
                  ),

                if (_isSubmitting)
                  const Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
          ),

          // Custom Numeric Keyboard
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                // Button Lanjut
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isPinComplete() && !_isSubmitting
                        ? _submitWithdrawal
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      disabledBackgroundColor: Colors.grey.shade300,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Lanjut',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Numeric Keyboard
                Column(
                  children: [
                    // Row 1: 1, 2, 3
                    Row(
                      children: [
                        _buildNumberButton('1'),
                        _buildNumberButton('2'),
                        _buildNumberButton('3'),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Row 2: 4, 5, 6
                    Row(
                      children: [
                        _buildNumberButton('4'),
                        _buildNumberButton('5'),
                        _buildNumberButton('6'),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Row 3: 7, 8, 9
                    Row(
                      children: [
                        _buildNumberButton('7'),
                        _buildNumberButton('8'),
                        _buildNumberButton('9'),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Row 4: Empty, 0, Backspace
                    Row(
                      children: [
                        Expanded(child: Container()),
                        _buildNumberButton('0'),
                        _buildBackspaceButton(),
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

  Widget _buildNumberButton(String number) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: _isSubmitting ? null : () => _onNumberPressed(number),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  number,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackspaceButton() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: _isSubmitting ? null : _onBackspacePressed,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Icon(
                  Icons.backspace_outlined,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
