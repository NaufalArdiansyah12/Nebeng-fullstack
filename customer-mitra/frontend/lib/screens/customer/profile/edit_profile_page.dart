import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../services/api_service.dart';

class CustomerEditProfilePage extends StatefulWidget {
  const CustomerEditProfilePage({Key? key}) : super(key: key);

  @override
  State<CustomerEditProfilePage> createState() =>
      _CustomerEditProfilePageState();
}

class _CustomerEditProfilePageState extends State<CustomerEditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _gender;
  final ImagePicker _picker = ImagePicker();
  XFile? _pickedImage;
  bool _isSaving = false;
  bool _isLoading = true;
  String? _currentProfilePhotoUrl;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');

      if (token == null) {
        setState(() => _isLoading = false);
        return;
      }

      final response = await ApiService.getProfile(token: token);

      if (response['success'] == true && response['data'] != null) {
        final userData = response['data']['user'];

        // Get profile photo URL and ensure it's a full URL
        String? photoUrl = userData['profile_photo'];
        if (photoUrl != null && photoUrl.isNotEmpty) {
          // If it's a relative path, make it absolute
          if (!photoUrl.startsWith('http')) {
            final baseUrl = ApiService.baseUrl;
            photoUrl = photoUrl.startsWith('/')
                ? '$baseUrl$photoUrl'
                : '$baseUrl/$photoUrl';
          }
        }

        setState(() {
          _emailController.text = userData['email'] ?? '';
          _nameController.text = userData['name'] ?? '';
          _addressController.text = userData['address'] ?? '';
          _phoneController.text = userData['phone'] ?? '';
          _gender = userData['gender'];
          _currentProfilePhotoUrl = photoUrl;
          _isLoading = false;
        });

        // Debug: print photo URL
        print('Profile photo URL: $photoUrl');
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error loading profile: $e');
      setState(() => _isLoading = false);
      // Silently fail, user can still fill form manually
    }
  }

  void _save() {
    _submit();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('api_token');
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token tidak ditemukan. Silakan login.')),
      );
      setState(() => _isSaving = false);
      return;
    }

    try {
      final resp = await ApiService.updateProfile(
        token: token,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        address: _addressController.text.trim(),
        phone: _phoneController.text.trim(),
        gender: _gender,
        photoFilePath: _pickedImage?.path,
      );

      if (resp['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil berhasil disimpan')),
        );
        Navigator.pop(context);
      } else {
        final msg = resp['message'] ?? 'Gagal menyimpan profil';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
          source: source, imageQuality: 80, maxWidth: 800);
      if (picked != null) {
        setState(() => _pickedImage = picked);
      }
    } catch (e) {
      // ignore
    }
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      builder: (c) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Pilih dari Galeri'),
              onTap: () {
                Navigator.pop(c);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Ambil Foto'),
              onTap: () {
                Navigator.pop(c);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const SizedBox(height: 8),
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.grey[200],
                          child: _pickedImage != null
                              ? ClipOval(
                                  child: Image.file(
                                    File(_pickedImage!.path),
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : (_currentProfilePhotoUrl != null &&
                                      _currentProfilePhotoUrl!.isNotEmpty)
                                  ? ClipOval(
                                      child: Image.network(
                                        _currentProfilePhotoUrl!,
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          print('Error loading image: $error');
                                          return Icon(
                                            Icons.person,
                                            size: 40,
                                            color: Colors.grey[400],
                                          );
                                        },
                                        loadingBuilder:
                                            (context, child, loadingProgress) {
                                          if (loadingProgress == null)
                                            return child;
                                          return Center(
                                            child: CircularProgressIndicator(
                                              value: loadingProgress
                                                          .expectedTotalBytes !=
                                                      null
                                                  ? loadingProgress
                                                          .cumulativeBytesLoaded /
                                                      loadingProgress
                                                          .expectedTotalBytes!
                                                  : null,
                                            ),
                                          );
                                        },
                                      ),
                                    )
                                  : Icon(
                                      Icons.person,
                                      size: 40,
                                      color: Colors.grey[400],
                                    ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: InkWell(
                            onTap: _showImageOptions,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black.withOpacity(0.12),
                                      blurRadius: 4),
                                ],
                              ),
                              child: const Icon(Icons.camera_alt,
                                  size: 18, color: Colors.black54),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildField(
                    controller: _emailController,
                    hint: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Email harus diisi' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildField(
                    controller: _nameController,
                    hint: 'Nama Lengkap',
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Nama harus diisi' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildField(
                    controller: _addressController,
                    hint: 'Alamat',
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Alamat harus diisi' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildField(
                    controller: _phoneController,
                    hint: 'No Telp',
                    keyboardType: TextInputType.phone,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'No Telp harus diisi' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildGenderField(),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text(
                              'Save',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    String? hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: Color(0xFF1E3A8A)),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildGenderField() {
    return InputDecorator(
      decoration: InputDecoration(
        hintText: 'Jenis Kelamin',
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _gender,
          items: const [
            DropdownMenuItem(value: 'Laki-laki', child: Text('Laki-laki')),
            DropdownMenuItem(value: 'Perempuan', child: Text('Perempuan')),
          ],
          hint: const Text('Jenis Kelamin'),
          onChanged: (val) => setState(() => _gender = val),
          isExpanded: true,
        ),
      ),
    );
  }
}
