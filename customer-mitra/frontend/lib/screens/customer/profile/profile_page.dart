import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../services/api_service.dart';
import '../../auth/splash_screen.dart';
import 'security_page.dart';
import 'edit_profile_page.dart';
import '../help/help_center_page.dart';
import '../../pin/create_pin_page.dart';
import '../main_page.dart';
import 'reward_page.dart';
import 'verifikasi_intro_page.dart';
import 'language_page.dart';
import 'transaction_history_page.dart';
import '../refund/refund_landing_page.dart';

class ProfilePage extends StatefulWidget {
  final bool showBottomNav;

  const ProfilePage({Key? key, this.showBottomNav = true}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _name;
  String? _email;
  String? _profilePhotoUrl;
  bool _isLoadingProfile = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoadingProfile = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('api_token');
    if (token == null) {
      setState(() => _isLoadingProfile = false);
      return;
    }

    try {
      final resp = await ApiService.getProfile(token: token);
      if (resp['success'] == true && resp['data'] != null) {
        final user = resp['data']['user'];
        setState(() {
          _name = user['name'] as String? ?? '';
          _email = user['email'] as String? ?? '';
          _profilePhotoUrl = user['profile_photo'] as String?;
        });
      }
    } catch (e) {
      // ignore, keep defaults
    } finally {
      setState(() => _isLoadingProfile = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E3A8A),
      body: SafeArea(
        child: Stack(
          children: [
            // Blue background extends to top
            Container(
              height: 280,
              decoration: const BoxDecoration(
                color: Color(0xFF1E3A8A),
              ),
            ),
            Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 50),
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(top: 80, bottom: 20),
                      child: _buildMenuCard(),
                    ),
                  ),
                ),
              ],
            ),
            // Avatar positioned over the card
            Positioned(
              top: 140,
              left: 0,
              right: 0,
              child: Center(
                child: _buildAvatar(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const MainPage()),
                  );
                }
              },
              color: const Color(0xFF1E3A8A),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'profile'.tr(),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: Container(
              color: const Color(0xFF1E3A8A),
              child: _isLoadingProfile
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white))
                  : (_profilePhotoUrl != null && _profilePhotoUrl!.isNotEmpty)
                      ? Image.network(
                          (_profilePhotoUrl!.startsWith('http')
                              ? _profilePhotoUrl!
                              : ApiService.baseUrl + _profilePhotoUrl!),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.person,
                              size: 50, color: Colors.white),
                        )
                      : const Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.white,
                        ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _name ?? 'User',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _email ?? '',
          style: const TextStyle(
            fontSize: 13,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Akun Section
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              'account'.tr(),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ),
          _buildMenuItem(
            icon: Icons.monetization_on,
            iconColor: const Color(0xFFFFA500),
            title: 'reward_point'.tr(),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RewardPage()),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.person_outline,
            iconColor: Colors.black87,
            title: 'edit_profile'.tr(),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CustomerEditProfilePage(),
                ),
              );
              // refresh profile after returning from edit
              _loadProfile();
            },
          ),
          _buildMenuItem(
            icon: Icons.verified_user,
            iconColor: const Color(0xFF1E40AF),
            title: 'verification'.tr(),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const VerifikasiIntroPage(),
                ),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.receipt_long_outlined,
            iconColor: Colors.black87,
            title: 'transaction_history'.tr(),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TransactionHistoryPage(),
                ),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.monetization_on_outlined,
            iconColor: Colors.black87,
            title: 'refund'.tr(),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const RefundLandingPage(),
                ),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.language,
            iconColor: Colors.black87,
            title: 'language'.tr(),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LanguagePage(),
                ),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.lock_outline,
            iconColor: Colors.black87,
            title: 'create_pin'.tr(),
            onTap: () {
              _checkAndNavigateToPin();
            },
          ),
          const SizedBox(height: 16),
          // Lainnya Section
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Text(
              'others'.tr(),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ),
          _buildMenuItem(
            icon: Icons.shield_outlined,
            iconColor: Colors.black87,
            title: 'security'.tr(),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SecurityPage(),
                ),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.help_outline,
            iconColor: Colors.black87,
            title: 'help_center'.tr(),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HelpCenterPage(),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          // Logout
          _buildMenuItem(
            icon: Icons.logout,
            iconColor: Colors.red,
            title: 'logout'.tr(),
            titleColor: Colors.red,
            onTap: () {
              _showLogoutDialog();
            },
            showArrow: false,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    Color? titleColor,
    required VoidCallback onTap,
    bool showArrow = true,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(
              icon,
              color: iconColor,
              size: 22,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: titleColor ?? Colors.black87,
                ),
              ),
            ),
            if (showArrow)
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _checkAndNavigateToPin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('api_token');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token tidak ditemukan')),
      );
      return;
    }

    try {
      final hasPin = await ApiService.checkPin(token: token);

      if (!mounted) return;

      if (hasPin) {
        // User already has PIN, show dialog
        showDialog(
          context: context,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 60,
                    color: Color(0xFF1E3A8A),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'PIN Sudah Dibuat',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Anda sudah memiliki PIN. Jika ingin mengubah PIN, silakan hubungi customer service.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'OK',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      } else {
        // User doesn't have PIN, navigate to create PIN page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CreatePinPage(),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Kamu yakin akan keluar?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: const Text('Tidak',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _performLogout();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: const Text('Iya',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _performLogout() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('api_token');

    try {
      await ApiService.logout(token);
    } catch (_) {
      // ignore errors from logout call; we'll clear local token anyway
    }

    await prefs.remove('api_token');

    if (!mounted) return;
    Navigator.of(context).pop(); // remove progress dialog

    // Navigate to splash screen and clear history
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SplashScreen()),
      (route) => false,
    );
  }
}
