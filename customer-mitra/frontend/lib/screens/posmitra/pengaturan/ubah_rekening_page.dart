import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/posmitra/posmitra_service.dart';

class UbahRekeningPage extends StatefulWidget {
  const UbahRekeningPage({Key? key}) : super(key: key);

  @override
  State<UbahRekeningPage> createState() => _UbahRekeningPageState();
}

class _UbahRekeningPageState extends State<UbahRekeningPage> {
  int currentStep = 0;
  final TextEditingController _namaBankController = TextEditingController();
  final TextEditingController _nomorRekeningController = TextEditingController();
  final TextEditingController _atasNamaController = TextEditingController();
  String? errorMessage;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  @override
  void dispose() {
    _namaBankController.dispose();
    _nomorRekeningController.dispose();
    _atasNamaController.dispose();
    super.dispose();
  }

  // Fungsi untuk mengambil data rekening yang sudah ada dari API
// Fungsi untuk mengambil data rekening yang sudah ada dari API
Future<void> _loadExistingData() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('api_token');
    
    if (token == null) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token tidak ditemukan. Silakan login.'))
      );
      return;
    }

    // Ambil data profil dari API dengan mengirim token
    final response = await PosMitraService.getProfile(token);
    
    if (response['success'] == true && response['data'] != null) {
      final userData = response['data']['user'];
      
      setState(() {
        // Isi controller dengan data yang ada
        _namaBankController.text = userData['bank_name'] ?? '';
        _nomorRekeningController.text = userData['bank_account_number'] ?? '';
        _atasNamaController.text = userData['bank_account_name'] ?? '';
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Gagal memuat data'))
        );
      }
    }
  } catch (e) {
    print('Error loading data: $e');
    setState(() {
      isLoading = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'))
      );
    }
  }
}

void _handleSubmit() async {
  if (currentStep == 0) {
    // Validate inputs
    final namaBank = _namaBankController.text.trim();
    final nomorRekening = _nomorRekeningController.text.trim();
    final atasNama = _atasNamaController.text.trim();

    if (namaBank.isEmpty) {
      setState(() {
        errorMessage = 'Nama bank tidak boleh kosong';
      });
      return;
    }

    if (nomorRekening.isEmpty) {
      setState(() {
        errorMessage = 'Nomor rekening tidak boleh kosong';
      });
      return;
    }

    if (nomorRekening.length < 10) {
      setState(() {
        errorMessage = 'Nomor rekening minimal 10 digit';
      });
      return;
    }

    if (atasNama.isEmpty) {
      setState(() {
        errorMessage = 'Nama pemilik rekening tidak boleh kosong';
      });
      return;
    }

    // Move to next step (preview/confirm)
    setState(() {
      errorMessage = null;
      currentStep = 1;
    });
  } else if (currentStep == 1) {
    // Send to backend
    setState(() {
      errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Token tidak ditemukan. Silakan login.')));
        return;
      }

      final namaBank = _namaBankController.text.trim();
      final nomorRekening = _nomorRekeningController.text.trim();
      final atasNama = _atasNamaController.text.trim();

      // Update profile dengan parameter yang benar
      final resp = await PosMitraService.updateProfile(
        bankName: namaBank,
        bankAccountNumber: nomorRekening,
        bankAccountName: atasNama,
      );

      if (resp['success'] == true) {
        setState(() {
          currentStep = 2;
        });
      } else {
        final msg = resp['message'] ?? 'Gagal memperbarui rekening bank';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  } else {
    // Return to settings
    Navigator.pop(context);
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
          icon: const Icon(Icons.arrow_back, color: Color(0xFF212121)),
          onPressed: () {
            if (currentStep > 0 && currentStep < 2) {
              setState(() {
                currentStep--;
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text(
          'Ubah Rekening Bank',
          style: TextStyle(
            color: Color(0xFF212121),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1E3A8A),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: _buildStepContent(),
                  ),
                ),
                // Bottom Button
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
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        currentStep == 2 ? 'Kembali' : 'Kirim',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStepContent() {
    switch (currentStep) {
      case 0:
        return _buildStep1Input();
      case 1:
        return _buildStep2Preview();
      case 2:
        return _buildStep3Success();
      default:
        return _buildStep1Input();
    }
  }

  // Step 1: Input bank account details
  Widget _buildStep1Input() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Masukkan informasi rekening bank',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF212121),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pastikan informasi rekening Anda benar dan aktif. Rekening ini akan digunakan untuk transfer dana.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),

          // Nama Bank
          const Text(
            'Nama Bank',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF212121),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _namaBankController,
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF212121),
            ),
            decoration: InputDecoration(
              hintText: 'Contoh: BCA, Mandiri, BNI',
              hintStyle: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
              ),
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFF1E3A8A),
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            onChanged: (value) {
              if (errorMessage != null) {
                setState(() {
                  errorMessage = null;
                });
              }
            },
          ),
          const SizedBox(height: 16),

          // Nomor Rekening
          const Text(
            'Nomor Rekening',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF212121),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nomorRekeningController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF212121),
            ),
            decoration: InputDecoration(
              hintText: 'Masukkan nomor rekening',
              hintStyle: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
              ),
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFF1E3A8A),
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            onChanged: (value) {
              if (errorMessage != null) {
                setState(() {
                  errorMessage = null;
                });
              }
            },
          ),
          const SizedBox(height: 16),

          // Atas Nama
          const Text(
            'Atas Nama',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF212121),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _atasNamaController,
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF212121),
            ),
            decoration: InputDecoration(
              hintText: 'Nama pemilik rekening',
              hintStyle: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
              ),
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: errorMessage != null
                    ? const BorderSide(color: Color(0xFFEF5350), width: 1)
                    : BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: errorMessage != null
                      ? const Color(0xFFEF5350)
                      : const Color(0xFF1E3A8A),
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            onChanged: (value) {
              if (errorMessage != null) {
                setState(() {
                  errorMessage = null;
                });
              }
            },
          ),

          if (errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              errorMessage!,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFFEF5350),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Step 2: Preview/Confirm bank account
  Widget _buildStep2Preview() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Konfirmasi informasi rekening bank',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF212121),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Periksa kembali informasi rekening Anda sebelum menyimpan.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),

          // Nama Bank Preview
          const Text(
            'Nama Bank',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF212121),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _namaBankController.text.trim(),
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF212121),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Nomor Rekening Preview
          const Text(
            'Nomor Rekening',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF212121),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _nomorRekeningController.text.trim(),
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF212121),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Atas Nama Preview
          const Text(
            'Atas Nama',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF212121),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _atasNamaController.text.trim(),
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF212121),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Step 3: Success
  Widget _buildStep3Success() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          const Text(
            'Rekening Bank Berhasil Diubah',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF212121),
            ),
          ),
          const SizedBox(height: 40),
          // Success icon
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1E3A8A).withOpacity(0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.check,
              size: 70,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Selamat! Anda telah berhasil mengubah informasi rekening bank',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}