import 'package:flutter/material.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import 'home_page.dart';
import 'riwayat_page.dart';
import 'profile/profile_page.dart';
import 'messages/chats_page.dart';

class MitraMainPage extends StatefulWidget {
  const MitraMainPage({Key? key}) : super(key: key);

  @override
  State<MitraMainPage> createState() => _MitraMainPageState();
}

class _MitraMainPageState extends State<MitraMainPage>
    with WidgetsBindingObserver {
  int _currentIndex = 0;
  Timer? _locationTimer;

  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // report location once on page init
    _reportCurrentLocation();
    _startLocationTimer();

    // initialize pages with callback so child can request opening history tab
    _pages.addAll([
      MitraHomePage(onOpenHistory: () => setState(() => _currentIndex = 1)),
      const MitraRiwayatPage(),
      const MitraChatsPage(),
      const MitraProfilePage(),
    ]);
  }

  @override
  void dispose() {
    _stopLocationTimer();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _reportCurrentLocation();
      _startLocationTimer();
    }
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _stopLocationTimer();
    }
  }

  Future<void> _reportCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best);

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');
      if (token == null || token.isEmpty) return;

      await ApiService.reportMitraLocation(
          token: token, lat: pos.latitude, lng: pos.longitude);
    } catch (e) {
      // ignore errors for now
    }
  }

  void _startLocationTimer() {
    if (_locationTimer != null && _locationTimer!.isActive) return;
    _locationTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) return;

        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          return;
        }

        final pos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.best);
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('api_token');
        if (token == null || token.isEmpty) return;

        await ApiService.reportMitraLocation(
            token: token, lat: pos.latitude, lng: pos.longitude);
      } catch (_) {
        // ignore periodic errors
      }
    });
  }

  void _stopLocationTimer() {
    try {
      _locationTimer?.cancel();
      _locationTimer = null;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  label: 'Beranda',
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.history_outlined,
                  activeIcon: Icons.history,
                  label: 'Riwayat',
                ),
                _buildNavItem(
                  index: 2,
                  icon: Icons.chat_bubble_outline,
                  activeIcon: Icons.chat_bubble,
                  label: 'Pesan',
                ),
                _buildNavItem(
                  index: 3,
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: 'Profil',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isActive = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color:
                  isActive ? const Color(0xFF1E40AF) : const Color(0xFF9CA3AF),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive
                    ? const Color(0xFF1E40AF)
                    : const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
