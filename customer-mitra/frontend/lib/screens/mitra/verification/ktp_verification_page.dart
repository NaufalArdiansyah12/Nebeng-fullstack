import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:convert';

class KtpVerificationPage extends StatefulWidget {
  const KtpVerificationPage({Key? key}) : super(key: key);

  @override
  State<KtpVerificationPage> createState() => _KtpVerificationPageState();
}

class _KtpVerificationPageState extends State<KtpVerificationPage> {
  final _formKey = GlobalKey<FormState>();
  final _ktpNumberController = TextEditingController();
  final _ktpNameController = TextEditingController();
  final _birthDateController = TextEditingController();

  File? _ktpPhoto;
  DateTime? _selectedDate;

  @override
  void dispose() {
    _ktpNumberController.dispose();
    _ktpNameController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _ktpPhoto = File(pickedFile.path);
      });
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _birthDateController.text =
            "${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}";
      });
    }
  }

  Future<void> _submitVerification() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_ktpPhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap upload foto KTP'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Format date to YYYY-MM-DD
      final formattedDate = _selectedDate != null
          ? '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}'
          : '';

      // Save to SharedPreferences temporarily
      final prefs = await SharedPreferences.getInstance();
      final ktpData = {
        'ktp_number': _ktpNumberController.text,
        'ktp_name': _ktpNameController.text,
        'ktp_birth_date': formattedDate,
        'ktp_photo': _ktpPhoto!.path,
      };

      await prefs.setString('temp_ktp_data', jsonEncode(ktpData));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data KTP berhasil disimpan'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan data: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
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
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Verifikasi KTP',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildTextField(
              controller: _ktpNumberController,
              label: 'Nomor KTP',
              hint: 'Masukkan 16 digit nomor KTP',
              keyboardType: TextInputType.number,
              maxLength: 16,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Nomor KTP harus diisi';
                }
                if (value.length != 16) {
                  return 'Nomor KTP harus 16 digit';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _ktpNameController,
              label: 'Nama Lengkap',
              hint: 'Sesuai KTP',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Nama lengkap harus diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _birthDateController,
              label: 'Tanggal Lahir',
              hint: 'DD-MM-YYYY',
              readOnly: true,
              onTap: _selectDate,
              suffixIcon: Icons.calendar_today,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Tanggal lahir harus diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            _buildPhotoUpload(),
            const SizedBox(height: 24),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    int? maxLength,
    bool readOnly = false,
    VoidCallback? onTap,
    IconData? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLength: maxLength,
          readOnly: readOnly,
          onTap: onTap,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.black38),
            suffixIcon: suffixIcon != null ? Icon(suffixIcon, size: 20) : null,
            counterText: '',
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.black26, width: 1.2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.black26, width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFF1E40AF), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoUpload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Foto KTP',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickImage,
          child: Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border.all(color: Colors.black26, width: 1.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: _ktpPhoto != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _ktpPhoto!,
                      fit: BoxFit.cover,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap untuk upload foto KTP',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _submitVerification,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E40AF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: const Text(
          'Simpan',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
