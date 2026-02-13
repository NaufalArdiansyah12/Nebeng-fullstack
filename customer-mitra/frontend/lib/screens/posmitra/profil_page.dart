import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/login_screen.dart';
import '../auth/splash_screen.dart';
import 'pengaturan/pengaturan_page.dart';
import '/services/api_service.dart';
import '/services/posmitra/posmitra_service.dart';
import 'pengaturan/bantuan_page.dart';

class ProfilPage extends StatefulWidget {
  const ProfilPage({Key? key}) : super(key: key);

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  Map<String, dynamic>? userProfile;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token') ?? '';

      if (token.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Token tidak ditemukan, silakan login.'),
            action: SnackBarAction(
              label: 'Login',
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
            ),
          ),
        );
        setState(() {
          isLoading = false;
          errorMessage = 'Token tidak ditemukan. Silakan login.';
        });
        return;
      }

      final response = await PosMitraService.getProfile(token);

      if (response['success'] == true) {
        final userData = response['data']?['user'] as Map<String, dynamic>?;

        setState(() {
          userProfile = userData;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = response['message'] ?? 'Gagal mengambil profil.';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Gagal mengambil profil: $e';
        isLoading = false;
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
  icon: const Icon(Icons.arrow_back, color: Color(0xFF212121)),
  onPressed: () {
    // ✅ SIMPLE: POP AJA, FLUTTER OTOMATIS ATUR
    Navigator.pop(context);
  },
),
        title: const Text(
          'Akun',
          style: TextStyle(
            color: Color(0xFF212121),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),

            /// ================= PROFILE CARD =================
            if (isLoading)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Center(child: CircularProgressIndicator()),
              )
            else if (errorMessage != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        errorMessage!,
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// 🔥 FOTO PROFIL - FIX UNTUK DOUBLE STORAGE
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFE0E0E0),
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: Builder(
                          builder: (context) {
                            final raw = userProfile?['profile_photo'];
                            
                            debugPrint('📸 Raw photo: $raw');
                            
                            // Kalau ada foto
                            if (raw != null && raw.isNotEmpty) {
                              String imageUrl = raw;
                              
                              // 🔥 CASE 1: Sudah full URL tapi double storage
                              if (raw.contains('/storage/storage/')) {
                                imageUrl = raw.replaceFirst('/storage/storage/', '/storage/');
                              }
                              // 🔥 CASE 2: Sudah full URL
                              else if (raw.startsWith('http')) {
                                imageUrl = raw;
                              }
                              // 🔥 CASE 3: Masih path
                              else {
                                final cleanPath = raw.replaceFirst('/storage/', '');
                                final baseUrl = ApiService.baseUrl.replaceFirst('/api', '');
                                imageUrl = '$baseUrl/storage/$cleanPath';
                              }
                              
                              debugPrint('✅ Final URL: $imageUrl');
                              
                              return Image.network(
                                imageUrl,
                                width: 70,
                                height: 70,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return const Center(
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  debugPrint('❌ Error: $error');
                                  return _buildDefaultAvatar();
                                },
                              );
                            }
                            
                            // Kalau ga ada foto
                            return _buildDefaultAvatar();
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    /// INFO PROFIL
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userProfile?['name'] ?? '-',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF212121),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            userProfile?['phone'] ?? '-',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            userProfile?['email'] ?? '-',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 2),
                          _buildLocationInfo(),
                        ],
                      ),
                    ),
                    
                    /// ICON EDIT
                    InkWell(
                      onTap: _showEditNameDialog,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.edit_outlined,
                          color: Color(0xFF424242),
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            /// ================= MENU =================
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildMenuItem(
                    icon: Icons.settings_outlined,
                    title: 'Pengaturan',
                    onTap: () async {
                      final res = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PengaturanPage(),
                        ),
                      );
                      if (res == true) {
                        _loadProfile();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Foto profil diperbarui'),
                          ),
                        );
                      }
                    },
                  ),
                  Divider(height: 1, color: Colors.grey[200], indent: 60),
                  _buildMenuItem(
                    icon: Icons.card_giftcard_outlined,
                    title: 'Kode Referral',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Fitur akan segera tersedia')),
                      );
                    },
                  ),
                  Divider(height: 1, color: Colors.grey[200], indent: 60),
                  _buildMenuItem(
                    icon: Icons.help_outline,
                    title: 'Bantuan',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BantuanPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            /// ================= LOGOUT =================
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: InkWell(
                onTap: () => _showLogoutDialog(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFEF5350)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout, color: Color(0xFFEF5350)),
                      SizedBox(width: 8),
                      Text(
                        'Keluar',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFEF5350),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// 🔥 BUILD DEFAULT AVATAR
  Widget _buildDefaultAvatar() {
    return Container(
      color: const Color(0xFF1E3A8A),
      child: Center(
        child: Text(
          userProfile?['name']?.isNotEmpty == true
              ? userProfile!['name'][0].toUpperCase()
              : 'U',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// 🔥 BUILD LOCATION INFO
  Widget _buildLocationInfo() {
    final locationName = userProfile?['location']?['name'];
    final locationCity = userProfile?['location']?['city'];
    final locationAddress = userProfile?['location']?['address'];
    
    String locationText = 'Lokasi tidak tersedia';
    
    if (locationName != null) {
      locationText = locationName;
      if (locationCity != null) {
        locationText += ' - $locationCity';
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          locationText,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        if (locationAddress != null && locationAddress.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              locationAddress,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }

  /// ================= MENU ITEM =================
  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: const Color(0xFF424242)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF9E9E9E)),
          ],
        ),
      ),
    );
  }

  /// ================= EDIT NAMA =================
  void _showEditNameDialog() {
    final controller = TextEditingController(text: userProfile?['name'] ?? '');
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Ubah Nama'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Nama',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      final newName = controller.text.trim();
                      if (newName.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Nama tidak boleh kosong'),
                          ),
                        );
                        return;
                      }

                      setStateDialog(() {
                        isSaving = true;
                      });

                      try {
                        final prefs = await SharedPreferences.getInstance();
                        final token = prefs.getString('api_token');
                        if (token == null || token.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Token tidak ditemukan. Silakan login.'),
                            ),
                          );
                          Navigator.pop(context);
                          return;
                        }

                        final resp = await PosMitraService.updateProfile(
                          name: newName,
                        );

                        if (resp['success'] == true) {
                          final userData = resp['data']?['user'] as Map<String, dynamic>?;
                          if (userData != null) {
                            setState(() {
                              userProfile = userData;
                            });
                          }

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Nama berhasil diperbarui'),
                            ),
                          );
                          Navigator.pop(context);
                        } else {
                          final msg = resp['message'] ?? 'Gagal memperbarui profil';
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(msg)),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Gagal menghubungi server: $e'),
                          ),
                        );
                      } finally {
                        setStateDialog(() {
                          isSaving = false;
                        });
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Simpan',
                      style: TextStyle(color: Colors.green),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// ================= LOGOUT =================
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar dari akun?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );

              await _performLogout();
            },
            child: const Text(
              'Keluar',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _performLogout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');

      if (token != null && token.isNotEmpty) {
        try {
          await ApiService.logout(token);
        } catch (_) {}
      }

      await prefs.remove('api_token');
      await prefs.remove('user_role');
      await prefs.remove('user_id');

      if (!mounted) return;

      Navigator.of(context).pop();

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SplashScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal logout: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}