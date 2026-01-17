import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../models/user_model.dart';
import '../../models/service_model.dart';
import 'notification_page.dart';
import 'nebeng_motor_page.dart';
import 'nebeng_mobil_page.dart';
import 'nebeng_barang/pages/nebeng_barang_page.dart';
import 'barang_umum/pages/barang_umum_page.dart';
import 'profile/profile_page.dart';

class BerandaPage extends StatefulWidget {
  final bool showBottomNav;

  const BerandaPage({Key? key, this.showBottomNav = true}) : super(key: key);

  @override
  State<BerandaPage> createState() => _BerandaPageState();
}

class _BerandaPageState extends State<BerandaPage> {
  late User currentUser;
  int _currentCarouselIndex = 0;
  bool _showKTPWarning = true;

  final List<Service> services = [
    Service(
      id: 1,
      name: 'Nebeng Motor',
      icon: FontAwesomeIcons.motorcycle,
      description: 'Layanan motor',
    ),
    Service(
      id: 2,
      name: 'Nebeng Mobil',
      icon: FontAwesomeIcons.car,
      description: 'Layanan mobil',
    ),
    Service(
      id: 3,
      name: 'Nebeng Barang',
      icon: FontAwesomeIcons.box,
      description: 'Layanan barang',
    ),
    Service(
      id: 4,
      name: 'Barang (Umum)',
      icon: FontAwesomeIcons.truck,
      description: 'Layanan transportasi',
    ),
  ];

  @override
  void initState() {
    super.initState();
    currentUser = User(
      id: 1,
      name: 'Ailsa',
      email: 'ailsa@example.com',
      isKTPVerified: false,
      rewardPoints: 1000,
      profileImage: '👋',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(),
              if (!currentUser.isKTPVerified && _showKTPWarning)
                _buildKTPWarning(),
              const SizedBox(height: 24),
              _buildServicesSection(),
              const SizedBox(height: 24),
              _buildNebenDisiniSection(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      decoration: const BoxDecoration(
        color: Color(0xFF1E3A8A),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Hallo Ailsa👋',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationPage(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.notifications,
                    color: Colors.red,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSearchBarInHeader(),
        ],
      ),
    );
  }

  Widget _buildSearchBarInHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search',
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          fillColor: Colors.white,
          filled: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildKTPWarning() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.warning_rounded, color: Colors.red, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kamu belum melakukan verifikasi KTP',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Verifikasi Sekarang!',
                  style: TextStyle(
                    color: Colors.red[600],
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _showKTPWarning = false;
              });
            },
            child: Icon(Icons.close, color: Colors.grey[600], size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Layanan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildServiceCard(services[0], const Color(0xFF1E40AF)),
              _buildServiceCard(services[1], const Color(0xFF1E40AF)),
              _buildServiceCard(services[2], const Color(0xFF1E40AF)),
              _buildServiceCard(services[3], const Color(0xFF1E40AF)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(Service service, Color bgColor) {
    return GestureDetector(
      onTap: () {
        if (service.name == 'Nebeng Motor') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NebengMotorPage()),
          );
        } else if (service.name == 'Nebeng Mobil') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NebengMobilPage()),
          );
        } else if (service.name == 'Nebeng Barang') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NebengBarangPage()),
          );
        } else if (service.name == 'Barang (Umum)') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BarangUmumPage()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${service.name} tapped')),
          );
        }
      },
      child: SizedBox(
        width: 80,
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: FaIcon(
                  service.icon as IconData?,
                  size: 28,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 70,
              child: Text(
                service.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNebenDisiniSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nebeng Disini',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: PageView.builder(
              onPageChanged: (index) {
                setState(() {
                  _currentCarouselIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return _buildCarouselCard();
              },
              itemCount: 3,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              3,
              (index) => Container(
                height: 8,
                width: _currentCarouselIndex == index ? 24 : 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: _currentCarouselIndex == index
                      ? Colors.grey[400]
                      : Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarouselCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF87CEEB), Color(0xFF98D8C8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Background pattern/illustration
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 200,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Illustration of person on motorcycle
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: Center(
                      child: FaIcon(
                        FontAwesomeIcons.motorcycle,
                        size: 60,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nebeng Motor',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Jalanan padat? Nebeng Motor bisa membantu Anda menembus kemacetan. Cepat, aman, dan aman. Tingkatkan maset, nikmati perjalanan yang lancar!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            height: 1.4,
                          ),
                          maxLines: 5,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return widget.showBottomNav
        ? Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: BottomNavigationBar(
              backgroundColor: Colors.white,
              type: BottomNavigationBarType.fixed,
              elevation: 0,
              items: const [
                BottomNavigationBarItem(
                  icon: FaIcon(FontAwesomeIcons.house),
                  label: 'Beranda',
                ),
                BottomNavigationBarItem(
                  icon: FaIcon(FontAwesomeIcons.receipt),
                  label: 'Riwayat',
                ),
                BottomNavigationBarItem(
                  icon: FaIcon(FontAwesomeIcons.comment),
                  label: 'Pesan',
                ),
                BottomNavigationBarItem(
                  icon: FaIcon(FontAwesomeIcons.user),
                  label: 'Profil',
                ),
              ],
              currentIndex: 0,
              selectedItemColor: const Color(0xFF1E3A8A),
              unselectedItemColor: Colors.grey[400],
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
              unselectedLabelStyle:
                  const TextStyle(fontWeight: FontWeight.w500),
              onTap: (index) {
                if (index == 3) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ProfilePage()),
                  );
                }
              },
            ),
          )
        : const SizedBox.shrink();
  }
}
