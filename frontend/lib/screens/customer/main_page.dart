import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'beranda_page.dart';
import 'profile/profile_page.dart';
import 'messages/chats_page.dart';
import 'riwayat/riwayat_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const BerandaPage(showBottomNav: false),
    const RiwayatPage(),
    const ChatsPage(),
    const ProfilePage(showBottomNav: false),
  ];

  final List<Map<String, dynamic>> _navItems = [
    {'icon': FontAwesomeIcons.house, 'label': 'Beranda'},
    {'icon': FontAwesomeIcons.receipt, 'label': 'Riwayat'},
    {'icon': FontAwesomeIcons.comment, 'label': 'Pesan'},
    {'icon': FontAwesomeIcons.user, 'label': 'Profil'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.only(top: 8, bottom: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 14,
              offset: const Offset(0, -4),
            ),
          ],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(22),
            topRight: Radius.circular(22),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_navItems.length, (index) {
              final item = _navItems[index];
              final bool active = _currentIndex == index;
              final Color activeColor = const Color(0xFF123F8A);
              final Color inactiveColor = const Color(0xFFBFCBE6);

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _currentIndex = index),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // top pill indicator
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      height: 6,
                      width: active ? 48 : 0,
                      decoration: BoxDecoration(
                        color: active ? activeColor : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FaIcon(
                      item['icon'] as IconData,
                      size: active ? 28 : 24,
                      color: active ? activeColor : inactiveColor,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item['label'] as String,
                      style: TextStyle(
                        fontSize: active ? 13 : 12,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                        color: active ? activeColor : inactiveColor,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
