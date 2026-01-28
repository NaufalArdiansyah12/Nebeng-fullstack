import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/api_service.dart';
import 'refund_success_page.dart';

class RefundFormPage extends StatefulWidget {
  final Map<String, dynamic> booking;

  const RefundFormPage({Key? key, required this.booking}) : super(key: key);

  @override
  State<RefundFormPage> createState() => _RefundFormPageState();
}

class _RefundFormPageState extends State<RefundFormPage> {
  int currentStep = 0;
  bool agreedToTerms = false;
  bool isLoading = false;

  // Form controllers
  final TextEditingController bankNameController = TextEditingController();
  final TextEditingController accountNumberController = TextEditingController();
  final TextEditingController accountHolderController = TextEditingController();

  String? selectedReason;
  Map<String, dynamic>? eligibilityData;

  final List<String> refundReasons = [
    'Perubahan Rencana Perjalanan',
    'Gagal Diproses oleh Sistem',
    'Masalah dengan Pengemudi',
    'Salah Jumlah Pembayaran',
    'Layanan Tidak Diterima',
    'Alasan Pribadi',
  ];

  @override
  void initState() {
    super.initState();
    _checkEligibility();
  }

  Future<void> _checkEligibility() async {
    try {
      final bookingType =
          (widget.booking['booking_type'] ?? 'motor').toString().toLowerCase();
      final bookingId = widget.booking['id'];

      final data =
          await ApiService.checkRefundEligibility(bookingId, bookingType);
      setState(() {
        eligibilityData = data;
      });
    } catch (e) {
      print('Error checking eligibility: $e');
    }
  }

  Future<void> _submitRefund() async {
    if (selectedReason == null ||
        bankNameController.text.isEmpty ||
        accountNumberController.text.isEmpty ||
        accountHolderController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon lengkapi semua data')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');

      if (userId == null) {
        throw Exception('User not logged in');
      }

      final bookingType =
          (widget.booking['booking_type'] ?? 'motor').toString().toLowerCase();

      await ApiService.submitRefund(
        userId: userId,
        bookingId: widget.booking['id'],
        bookingType: bookingType,
        refundReason: selectedReason!,
        bankName: bankNameController.text,
        accountNumber: accountNumberController.text,
        accountHolderName: accountHolderController.text,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => RefundSuccessPage(
              refundAmount: eligibilityData?['refund_amount'] ?? 0,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengajukan refund: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F4AA3),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Refund',
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
          _buildStepper(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _buildStepContent(),
            ),
          ),
          _buildBottomButton(),
        ],
      ),
    );
  }

  Widget _buildStepper() {
    return Container(
      color: const Color(0xFF0F4AA3),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          _buildStepIndicator(1, 'Syarat dan Ketentuan', currentStep >= 0),
          _buildStepConnector(currentStep >= 1),
          _buildStepIndicator(2, 'Isi Data', currentStep >= 1),
          _buildStepConnector(currentStep >= 2),
          _buildStepIndicator(3, 'Review', currentStep >= 2),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label, bool isActive) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? Colors.white : Colors.white.withOpacity(0.3),
            ),
            child: Center(
              child: Text(
                '$step',
                style: TextStyle(
                  color: isActive
                      ? const Color(0xFF0F4AA3)
                      : Colors.white.withOpacity(0.6),
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white.withOpacity(0.6),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStepConnector(bool isActive) {
    return Container(
      height: 2,
      width: 20,
      margin: const EdgeInsets.only(bottom: 20),
      color: isActive ? Colors.white : Colors.white.withOpacity(0.3),
    );
  }

  Widget _buildStepContent() {
    switch (currentStep) {
      case 0:
        return _buildTermsStep();
      case 1:
        return _buildDataStep();
      case 2:
        return _buildReasonStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildTermsStep() {
    final ride = widget.booking['ride'] ?? {};
    final originName = ride['origin_location']?['name'] ?? 'Unknown';
    final destinationName = ride['destination_location']?['name'] ?? 'Unknown';
    final departureDate = ride['departure_date'] ?? '';
    final bookingType = (widget.booking['booking_type'] ?? 'motor').toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Booking Info Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildBookingTypeIcon(bookingType),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getBookingTypeName(bookingType),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Mohon isi semua data yang diperlukan',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          originName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _formatDate(departureDate),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          destinationName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.right,
                        ),
                        Text(
                          _formatDate(departureDate),
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
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Terms Container
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nebeng',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Syarat dan Ketentuan Refund Nebeng',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              _buildTermItem(
                1,
                'Pembatasan Sesi Pengemudi',
                'a. Jika pengemudi melakukan perubahan secara sepihak setelah penumpang melakukan pembayaran, maka penumpang berhak mendapatkan refund penuh dalam waktu 3-5 hari kerja.\n\n'
                    'b. Jika pengemudi membatalkan perjalanan lebih dari 1 jam sebelum waktu penjemputan tanpa persetujuan, penumpang dapat meminta refund penuh.',
              ),
              _buildTermItem(
                2,
                'Pembatasan Pengemudi Melakukan Perubahan yang Signifikan',
                'a. Jika pengemudi membatalkan perjalanan lebih dari 1 jam sebelum waktu penjemputan, penumpang dapat menghubungi sistem untuk meminta refund 60% dari harga yang dibayarkan sebelum tarif perjalanan dilakukan.\n\n'
                    'b. Jika pengemudi membatalkan perjalanan dalam waktu kurang dari 1 jam sebelum waktu penjemputan, penumpang dapat menghubungi sistem untuk meminta refund 50% dari harga yang dibayarkan sebelum tarif perjalanan dilakukan.',
              ),
              _buildTermItem(
                3,
                'Masalah Layanan Teknis',
                'a. Jika terjadi gangguan pada sistem atau transaksi tidak dapat menyelesaikan pencairan, penumpang dapat menghubungi sistem untuk menyelesaikan issue tersebut.\n\n'
                    'b. Jika ada kesalahan pembayaran yang disebabkan oleh sistem, penumpang dapat meminta refund penuh dalam waktu 48 jam setelah transaksi dilakukan.',
              ),
              _buildTermItem(
                4,
                'Kondisi Khusus',
                'a. Penumpang yang mengalami masalah dengan kendaraan atau pengemudi yang tidak memenuhi standar keamanan atau kebersihan dapat melaporkan kepada tersebut dan meminta refund dalam waktu 24 jam setelah perjalanan selesai berdasarkan rincian perjalanan atau refund penuh (apabah perjalanan belum dimulai).',
              ),
              _buildTermItem(
                5,
                'Proses Pengajuan Refund',
                'a. Penumpang dapat mengajukan permintaan refund melalui menu "Bantuan" di aplikasi Nebeng (contoh: kegagalan sistem atau problem lainnya).\n\n'
                    'b. Permintaan refund akan diproses dalam waktu 7 hari kerja, dan pengembalian dana akan dilakukan melalui metode pembayaran yang digunakan saat transaksi.',
              ),
              const SizedBox(height: 16),

              // Checkbox
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: agreedToTerms,
                    onChanged: (value) {
                      setState(() {
                        agreedToTerms = value ?? false;
                      });
                    },
                    activeColor: const Color(0xFF0F4AA3),
                  ),
                  const Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Text(
                        'Saya menyetujui Syarat dan Ketentuan Refund',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTermItem(int number, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$number. $title',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Refund Info Card
        if (eligibilityData != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Estimasi Refund',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F4AA3),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Refund akan diproses dalam waktu 3-5 hari kerja sebelum jadwal keberangkatan',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
                const Divider(height: 24),
                Text(
                  '28 Agustus 2024 (09:00) - 1 September 2024 (13:00)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Passenger Info
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Penumpang',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _buildPassengerItem('Penumpang 1', 'Alisa Nasywa'),
              if (widget.booking['seats'] != null &&
                  widget.booking['seats'] > 1)
                _buildPassengerItem('Penumpang 2', 'Alisa Nasywa'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Bank Account Form
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Rekening Bank',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Show change option
                    },
                    child: const Text(
                      'Ubah',
                      style: TextStyle(
                        color: Color(0xFF0F4AA3),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Agar proses pengembalian dana (refund) dapat diproses dengan cepat dan akurat, silakan isi detail rekening Bank Anda dengan benar.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),

              // Show bank account card if data exists, otherwise show add button
              if (bankNameController.text.isNotEmpty &&
                  accountNumberController.text.isNotEmpty &&
                  accountHolderController.text.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            bankNameController.text,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              _showAddBankAccountDialog();
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF0F4AA3),
                              padding: EdgeInsets.zero,
                            ),
                            child: const Text(
                              'Ubah',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.account_balance_wallet,
                              size: 18, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Text(
                            accountNumberController.text,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[800],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.person_outline,
                              size: 18, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Text(
                            accountHolderController.text,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              else
                TextButton.icon(
                  onPressed: () {
                    _showAddBankAccountDialog();
                  },
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Tambah Nomor Rekening'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF0F4AA3),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPassengerItem(String label, String name) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          Row(
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                label == 'Penumpang 1' ? 'Penumpang I' : 'Penumpang II',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReasonStep() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pilih alasan melakukan refund :',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...refundReasons.map((reason) {
            return _buildReasonOption(reason);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildReasonOption(String reason) {
    final isSelected = selectedReason == reason;

    return InkWell(
      onTap: () {
        setState(() {
          selectedReason = reason;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? const Color(0xFF0F4AA3) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      isSelected ? const Color(0xFF0F4AA3) : Colors.grey[400]!,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF0F4AA3),
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                reason,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? Colors.black87 : Colors.grey[700],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButton() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _getButtonAction(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F4AA3),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              disabledBackgroundColor: Colors.grey[300],
            ),
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    currentStep == 2 ? 'Lanjutkan' : 'Lanjutkan',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  VoidCallback? _getButtonAction() {
    if (isLoading) return null;

    if (currentStep == 0) {
      return agreedToTerms
          ? () {
              setState(() {
                currentStep = 1;
              });
            }
          : null;
    } else if (currentStep == 1) {
      return bankNameController.text.isNotEmpty &&
              accountNumberController.text.isNotEmpty &&
              accountHolderController.text.isNotEmpty
          ? () {
              setState(() {
                currentStep = 2;
              });
            }
          : null;
    } else if (currentStep == 2) {
      return selectedReason != null ? _submitRefund : null;
    }
    return null;
  }

  void _showAddBankAccountDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top indicator
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Text(
                  'Tambah Nomor Rekening',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Nama Bank',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: bankNameController,
                  decoration: InputDecoration(
                    hintText: 'Contoh: BCA, Mandiri, BNI',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Color(0xFF0F4AA3), width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Nama Rekening',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: accountNumberController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Nomor rekening',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Color(0xFF0F4AA3), width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Nama Pemilik Rekening',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: accountHolderController,
                  decoration: InputDecoration(
                    hintText: 'Nama sesuai rekening',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Color(0xFF0F4AA3), width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      if (bankNameController.text.isEmpty ||
                          accountNumberController.text.isEmpty ||
                          accountHolderController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Mohon lengkapi semua data'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      Navigator.pop(context);
                      setState(() {});
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F4AA3),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Simpan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBookingTypeIcon(String type) {
    IconData icon;
    switch (type.toLowerCase()) {
      case 'motor':
        icon = Icons.two_wheeler;
        break;
      case 'mobil':
        icon = Icons.directions_car;
        break;
      case 'barang':
        icon = Icons.local_shipping;
        break;
      case 'titip':
        icon = Icons.inventory_2;
        break;
      default:
        icon = Icons.directions_car;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F4AA3).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: const Color(0xFF0F4AA3), size: 32),
    );
  }

  String _getBookingTypeName(String type) {
    switch (type.toLowerCase()) {
      case 'motor':
        return 'Nebeng Motor';
      case 'mobil':
        return 'Nebeng Mobil';
      case 'barang':
        return 'Nebeng Barang';
      case 'titip':
        return 'Titip Barang';
      default:
        return 'Booking';
    }
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return '';

    try {
      final dt = DateTime.parse(dateStr);
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agt',
        'Sep',
        'Okt',
        'Nov',
        'Des'
      ];
      return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}';
    } catch (e) {
      return dateStr;
    }
  }

  @override
  void dispose() {
    bankNameController.dispose();
    accountNumberController.dispose();
    accountHolderController.dispose();
    super.dispose();
  }
}
