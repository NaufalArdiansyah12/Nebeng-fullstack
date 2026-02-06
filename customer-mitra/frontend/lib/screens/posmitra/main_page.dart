import 'package:flutter/material.dart';
import 'beranda_page.dart';
import 'aktivitas_page.dart';
import 'pesan_page.dart';
import 'profil_page.dart';
import 'scan/qr_scanner_intro_page.dart';

class PosMitraMainPage extends StatefulWidget {
  const PosMitraMainPage({Key? key}) : super(key: key);

  @override
  State<PosMitraMainPage> createState() => _PosMitraMainPageState();
}

class _PosMitraMainPageState extends State<PosMitraMainPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    BerandaPage(),
    AktivitasPage(),
    PesanPage(),
    ProfilPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],

      // ===== FAB =====
      floatingActionButton: Container(
        width: 65,
        height: 65,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF1E3A8A), Color(0xFF2852B8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E3A8A).withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
                Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const QRScannerIntroPage(),
      ),
    );
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.qr_code_scanner,
                color: Colors.white,
                size: 26,
              ),
              const SizedBox(height: 2),
              Text(
                'Scan',
                style: TextStyle(
                  height: 1.0,
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // ===== BOTTOM BAR =====
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 8,
          elevation: 0,
          child: SizedBox(
            height: 72, // 🔑 aman semua device
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  icon: Icons.home,
                  label: 'Beranda',
                  index: 0,
                ),
                _buildNavItem(
                  icon: Icons.access_time,
                  label: 'Aktivitas',
                  index: 1,
                ),
                const SizedBox(width: 60),
                _buildNavItem(
                  icon: Icons.chat_bubble_outline,
                  label: 'Pesan',
                  index: 2,
                ),
                _buildNavItem(
                  icon: Icons.person_outline,
                  label: 'Profil',
                  index: 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===== NAV ITEM =====
  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final bool isSelected = _selectedIndex == index;

    return InkWell(
      onTap: () => _onItemTapped(index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected
                  ? const Color(0xFF1E3A8A)
                  : const Color(0xFFBDBDBD),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              style: TextStyle(
                height: 1.0, // 🔑 anti overflow
                fontSize: 11,
                color: isSelected
                    ? const Color(0xFF1E3A8A)
                    : const Color(0xFFBDBDBD),
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
