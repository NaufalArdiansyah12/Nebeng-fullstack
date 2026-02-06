import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../services/api_service.dart';
import 'package:intl/intl.dart';
import 'status/registration_status_page.dart';
import 'status/document_change_status_page.dart';
import 'status/vehicle_add_status_page.dart';
import 'status/vehicle_delete_status_page.dart';

class AccountStatusPage extends StatefulWidget {
  const AccountStatusPage({Key? key}) : super(key: key);

  @override
  State<AccountStatusPage> createState() => _AccountStatusPageState();
}

class _AccountStatusPageState extends State<AccountStatusPage> {
  bool isLoading = true;
  Map<String, dynamic>? user;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');
      if (token != null) {
        final profile = await ApiService.getProfile(token: token);
        if (profile['success'] == true && profile['data'] != null) {
          final userData = profile['data']['user'] ?? profile['data'];

          if (userData != null && userData['profile_photo'] != null) {
            String? photoUrl = userData['profile_photo'];
            if (photoUrl != null && photoUrl.isNotEmpty) {
              if (!photoUrl.startsWith('http')) {
                final base = ApiService.baseUrl;
                photoUrl = photoUrl.startsWith('/')
                    ? '$base$photoUrl'
                    : '$base/$photoUrl';
              }
              userData['profile_photo'] = photoUrl;
            }
          }

          setState(() {
            user = Map<String, dynamic>.from(userData);
            isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      // ignore
    }
    setState(() => isLoading = false);
  }

  Widget _buildInfoCard() {
    final name = user?['name'] ?? 'User';
    final id = user?['id']?.toString() ?? '';
    final joined = user?['created_at'] ?? '';
    String joinedText = '';
    if (joined != null && joined.toString().isNotEmpty) {
      try {
        joinedText = DateFormat('d MMMM yyyy').format(DateTime.parse(joined));
      } catch (_) {}
    }

    final phone = user?['phone'] ?? user?['no_hp'] ?? '';
    final email = user?['email'] ?? '';
    final address = user?['address'] ?? user?['alamat'] ?? '';

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: user?['profile_photo'] != null &&
                    user!['profile_photo'].toString().isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(user!['profile_photo'],
                        fit: BoxFit.cover),
                  )
                : const Icon(Icons.person, size: 36, color: Colors.black54),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                if (id.isNotEmpty || joinedText.isNotEmpty)
                  Text(
                    '${id.isNotEmpty ? id + ' | ' : ''}${joinedText.isNotEmpty ? 'Bergabung sejak $joinedText' : ''}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                if (phone.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(phone, style: TextStyle(color: Colors.grey.shade600)),
                ],
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(email, style: TextStyle(color: Colors.grey.shade600)),
                ],
                if (address.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(address,
                      style: TextStyle(color: Colors.grey.shade600),
                      overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMenuTile(String title, VoidCallback onTap) {
    return Column(
      children: [
        ListTile(
          title:
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
        Divider(height: 1, color: Colors.grey.shade200),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Status Akun',
            style:
                TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
      ),
      backgroundColor: Colors.white,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text('Informasi Akun',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade800)),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(),
                  const SizedBox(height: 8),
                  _buildMenuTile('Status pendaftaran', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const RegistrationStatusPage()),
                    );
                  }),
                  _buildMenuTile('Status tambah kendaraan', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const VehicleAddStatusPage()),
                    );
                  }),
                  _buildMenuTile('Status hapus kendaraan', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              const VehicleDeleteStatusPage()),
                    );
                  }),
                  _buildMenuTile('Status perubahan dokumen', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              const DocumentChangeStatusPage()),
                    );
                  }),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}
