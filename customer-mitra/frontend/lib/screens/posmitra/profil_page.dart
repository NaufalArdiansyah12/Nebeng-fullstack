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
  int _photoCacheBuster = 0;

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
      // Jika token kosong, langsung ke login
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

    // Ambil data profil dengan token
    final response = await PosMitraService.getProfile(token);

    if (response['success'] == true) {
      final userData = response['data']?['user'] as Map<String, dynamic>?;

      setState(() {
        userProfile = userData;
        _photoCacheBuster = DateTime.now().millisecondsSinceEpoch;
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
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacementNamed(context, '/home');
    }
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
                  children: [
                    /// FOTO PROFIL
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
                            // Bangun URL lengkap untuk foto profil berdasarkan API yang sudah ada
                            String photoUrl =
                                'https://i.pravatar.cc/150?img=12';
                            final raw = userProfile?['profile_photo'];

                            if (raw != null && raw.isNotEmpty) {
                              if (raw.startsWith('http')) {
                                photoUrl = raw;
                              } else {
                                final base = ApiService.baseUrl;
                                photoUrl = raw.startsWith('/')
                                    ? '$base$raw'
                                    : '$base/$raw';
                              }
                            }

                            return Image.network(
                              '$photoUrl?t=$_photoCacheBuster',
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const Center(
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Image.network(
                                  'https://i.pravatar.cc/150?img=12',
                                  fit: BoxFit.cover,
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    /// INFO PROFIL
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
      // ✅ Gabungkan Location: "Terminal Blok M - Jakarta"
      Builder(
        builder: (context) {
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
        },
      ),
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
                        // Reload profile and notify user
                        _loadProfile();
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Foto profil diperbarui')));
                      }
                    },
                  ),
                  Divider(height: 1, color: Colors.grey[200], indent: 60),
                  _buildMenuItem(
                    icon: Icons.card_giftcard_outlined,
                    title: 'Kode Referral',
                    onTap: () {},
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
                              content: Text('Nama tidak boleh kosong')),
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
                                content: Text(
                                    'Token tidak ditemukan. Silakan login.')),
                          );
                          Navigator.pop(context);
                          return;
                        }

                        final resp = await ApiService.updateProfile(
                            token: token, name: newName);

                        // API returns success flag and data.user
                        if (resp['success'] == true) {
                          final userData =
                              resp['data']?['user'] as Map<String, dynamic>?;
                          if (userData != null) {
                            setState(() {
                              userProfile = userData;
                            });
                          }

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Nama berhasil diperbarui')),
                          );
                        } else {
                          final msg =
                              resp['message'] ?? 'Gagal memperbarui profil';
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(msg)),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Gagal menghubungi server: $e')),
                        );
                      } finally {
                        setStateDialog(() {
                          isSaving = false;
                        });
                        Navigator.pop(context);
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
              Navigator.pop(context); // Close dialog first

              // Show loading
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

      // Call logout API if token exists
      if (token != null && token.isNotEmpty) {
        try {
          await ApiService.logout(token);
        } catch (_) {
          // Ignore logout API errors, still clear local data
        }
      }

      // Clear all local data
      await prefs.remove('api_token');
      await prefs.remove('user_role');
      await prefs.remove('user_id');

      if (!mounted) return;

      // Close loading dialog
      Navigator.of(context).pop();

      // Navigate to splash screen and clear all routes
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SplashScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      // Close loading dialog
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
