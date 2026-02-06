import 'package:flutter/material.dart';

class AddPointsPage extends StatelessWidget {
  const AddPointsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Title
          const Text(
            'Tambah Point',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Point akan bertambah setiap transaksi',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 40),

          // Nebeng Motor
          _buildPointItem(
            icon: Icons.motorcycle,
            title: 'Nebeng Motor',
            description:
                'Setiap penggunaan fitur nebeng motor, point akan bertambah sebanyak 15 point',
          ),
          const SizedBox(height: 32),

          // Nebeng Mobil
          _buildPointItem(
            icon: Icons.directions_car,
            title: 'Nebeng Mobil',
            description:
                'Setiap penggunaan fitur nebeng mobil, point akan bertambah sebanyak 25 point',
          ),
          const SizedBox(height: 32),

          // Nebeng Barang
          _buildPointItem(
            icon: Icons.inventory_2_outlined,
            title: 'Nebeng Barang',
            description:
                'Setiap penggunaan fitur nebeng barang, point akan bertambah sebanyak 20 point',
          ),
          const SizedBox(height: 32),

          // Titip Barang Transportasi Umum
          _buildPointItem(
            icon: Icons.inventory_2_outlined,
            title: 'Titip Barang Transportasi Umum',
            description:
                'Setiap penggunaan fitur nebeng barang, point akan bertambah sebanyak 18 point',
          ),
        ],
      ),
    );
  }

  Widget _buildPointItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
