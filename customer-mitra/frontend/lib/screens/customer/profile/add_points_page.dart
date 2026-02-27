import 'package:flutter/material.dart';
import '../../../services/api_service.dart';

class AddPointsPage extends StatefulWidget {
  const AddPointsPage({Key? key}) : super(key: key);

  @override
  State<AddPointsPage> createState() => _AddPointsPageState();
}

class _AddPointsPageState extends State<AddPointsPage> {
  Map<String, dynamic> pointValues = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPointValues();
  }

  Future<void> _loadPointValues() async {
    try {
      final data = await ApiService.getPointValues();
      setState(() {
        pointValues = data;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading point values: $e');
      setState(() {
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
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
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
                if (pointValues['motor'] != null)
                  _buildPointItem(
                    icon: Icons.motorcycle,
                    title: pointValues['motor']['name'] ?? 'Nebeng Motor',
                    description: pointValues['motor']['description'] ?? '',
                  ),
                if (pointValues['motor'] != null) const SizedBox(height: 32),

                // Nebeng Mobil
                if (pointValues['mobil'] != null)
                  _buildPointItem(
                    icon: Icons.directions_car,
                    title: pointValues['mobil']['name'] ?? 'Nebeng Mobil',
                    description: pointValues['mobil']['description'] ?? '',
                  ),
                if (pointValues['mobil'] != null) const SizedBox(height: 32),

                // Nebeng Barang
                if (pointValues['barang'] != null)
                  _buildPointItem(
                    icon: Icons.inventory_2_outlined,
                    title: pointValues['barang']['name'] ?? 'Nebeng Barang',
                    description: pointValues['barang']['description'] ?? '',
                  ),
                if (pointValues['barang'] != null) const SizedBox(height: 32),

                // Titip Barang Transportasi Umum
                if (pointValues['titip'] != null)
                  _buildPointItem(
                    icon: Icons.inventory_2_outlined,
                    title: pointValues['titip']['name'] ??
                        'Titip Barang Transportasi Umum',
                    description: pointValues['titip']['description'] ?? '',
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
