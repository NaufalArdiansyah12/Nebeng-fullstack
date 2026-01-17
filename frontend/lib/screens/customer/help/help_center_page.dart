import 'package:flutter/material.dart';
import 'help_detail_page.dart';

class HelpCenterPage extends StatelessWidget {
  const HelpCenterPage({Key? key}) : super(key: key);

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
          'Pusat Bantuan',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: ListView(
        children: [
          _buildHelpItem(
            context,
            'Saya mengalami kecelakaan',
            'accident',
          ),
          const Divider(height: 1),
          _buildHelpItem(
            context,
            'Barang saya tertinggal di motor',
            'left_item_motor',
          ),
          const Divider(height: 1),
          _buildHelpItem(
            context,
            'Barang saya tertinggal di mobil',
            'left_item_car',
          ),
          const Divider(height: 1),
          _buildHelpItem(
            context,
            'Saya mengalami penipuan',
            'fraud',
          ),
          const Divider(height: 1),
          _buildHelpItem(
            context,
            'Driver melakukan pelecehan terhadap saya',
            'harassment',
          ),
          const Divider(height: 1),
          _buildHelpItem(
            context,
            'Cara mengubah nama, no hp, email, dan foto di akun nebeng',
            'change_profile',
          ),
          const Divider(height: 1),
          _buildHelpItem(
            context,
            'Saya ingin menghapus akun saya',
            'delete_account',
          ),
          const Divider(height: 1),
          _buildHelpItem(
            context,
            'Cara mengubah bahasa aplikasi',
            'change_language',
          ),
          const Divider(height: 1),
          _buildHelpItem(
            context,
            'Akun saya terblokir',
            'blocked_account',
          ),
          const Divider(height: 1),
          _buildHelpItem(
            context,
            'Bagaimana Proses Refund Bekerja?',
            'refund_process',
          ),
          const Divider(height: 1),
          _buildHelpItem(
            context,
            'Kebijakan Refund',
            'refund_policy',
          ),
          const Divider(height: 1),
        ],
      ),
    );
  }

  Widget _buildHelpItem(BuildContext context, String title, String type) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HelpDetailPage(
              title: title,
              type: type,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}
