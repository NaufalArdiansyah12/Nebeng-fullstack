import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../../../services/api_service.dart';
import 'document_success_page.dart';

class EditSimPage extends StatefulWidget {
  final Map<String, dynamic>? existingData;

  const EditSimPage({Key? key, this.existingData}) : super(key: key);

  @override
  State<EditSimPage> createState() => _EditSimPageState();
}

class _EditSimPageState extends State<EditSimPage> {
  final _formKey = GlobalKey<FormState>();
  final _simNumberController = TextEditingController();
  final _expiryDateController = TextEditingController();

  File? _simPhoto;
  DateTime? _selectedDate;
  String? _selectedSimType;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingData != null) {
      _simNumberController.text = widget.existingData?['sim_number'] ?? '';
      _selectedSimType = widget.existingData?['sim_type'] ?? 'C';
      if (widget.existingData?['sim_expiry_date'] != null) {
        try {
          _selectedDate =
              DateTime.parse(widget.existingData!['sim_expiry_date']);
          _expiryDateController.text =
              DateFormat('dd/MM/yyyy').format(_selectedDate!);
        } catch (e) {
          print('Error parsing date: $e');
        }
      }
    }
  }

  @override
  void dispose() {
    _simNumberController.dispose();
    _expiryDateController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Akses Pribadi ke Foto',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF1A43BF)),
              title: const Text('Kamera'),
              onTap: () {
                Navigator.pop(context);
                _getImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.photo_library, color: Color(0xFF1A43BF)),
              title: const Text('Galeri'),
              onTap: () {
                Navigator.pop(context);
                _getImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _getImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        _simPhoto = File(pickedFile.path);
      });
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1A43BF),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _expiryDateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_simPhoto == null && widget.existingData?['sim_photo'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon upload foto SIM')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');

      if (token == null) {
        throw Exception('Token not found');
      }

      final result = widget.existingData != null
          ? await ApiService.updateSim(
              token: token,
              simNumber: _simNumberController.text,
              simType: _selectedSimType ?? 'C',
              expiryDate: DateFormat('yyyy-MM-dd').format(_selectedDate!),
              simPhoto: _simPhoto ?? widget.existingData?['sim_photo'],
            )
          : await ApiService.uploadSim(
              token: token,
              simNumber: _simNumberController.text,
              expiryDate: DateFormat('yyyy-MM-dd').format(_selectedDate!),
              simPhoto: _simPhoto,
            );

      if (!mounted) return;

      if (result['success'] == true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const DocumentSuccessPage(
              documentType: 'SIM',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Gagal menyimpan data')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  String _buildPhotoUrl(String photoPath) {
    if (photoPath.startsWith('http')) {
      return photoPath;
    } else if (photoPath.startsWith('/')) {
      return '${ApiService.baseUrl}$photoPath';
    } else {
      return '${ApiService.baseUrl}/storage/$photoPath';
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
          'SIM',
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
          padding: const EdgeInsets.all(20),
          children: [
            // Info banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: Colors.grey.shade600, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Harap isi sesuai dengan SIM Anda',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Nomor SIM
            TextFormField(
              controller: _simNumberController,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                labelText: 'Nomor SIM',
                hintText: 'Masukkan nomor SIM Anda',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF1A43BF)),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Nomor SIM harus diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Jenis SIM
            DropdownButtonFormField<String>(
              value: _selectedSimType,
              decoration: InputDecoration(
                labelText: 'Jenis SIM',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF1A43BF)),
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'A', child: Text('SIM A')),
                DropdownMenuItem(value: 'B1', child: Text('SIM B1')),
                DropdownMenuItem(value: 'B2', child: Text('SIM B2')),
                DropdownMenuItem(value: 'C', child: Text('SIM C')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedSimType = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Jenis SIM harus dipilih';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _expiryDateController,
              readOnly: true,
              onTap: _selectDate,
              decoration: InputDecoration(
                labelText: 'Tanggal Masa Berlaku',
                hintText: 'Masukkan tanggal masa berlaku SIM Anda',
                suffixIcon: const Icon(Icons.calendar_today),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF1A43BF)),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Tanggal berlaku harus diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Foto SIM',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: _simPhoto != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _simPhoto!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : widget.existingData?['sim_photo'] != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              widget.existingData!['sim_photo']
                                      .startsWith('http')
                                  ? widget.existingData!['sim_photo']
                                  : '${ApiService.baseUrl}${widget.existingData!['sim_photo']}',
                              fit: BoxFit.cover,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate,
                                size: 48,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap untuk upload foto',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A43BF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Simpan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
