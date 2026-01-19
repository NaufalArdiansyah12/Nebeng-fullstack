import 'package:flutter/material.dart';

class RewardSuccessPage extends StatelessWidget {
  final Map<String, dynamic> reward;
  final Map<String, dynamic>? data;
  const RewardSuccessPage({Key? key, required this.reward, this.data})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final title = reward['title'] ?? 'Merchandise';
    final points = (reward['points_cost'] ?? 0).toString();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        title: const Text('Status Penukaran'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 24),
          CircleAvatar(
            radius: 48,
            backgroundColor: Colors.lightBlue[100],
            child: const Icon(Icons.check_circle, size: 56, color: Colors.blue),
          ),
          const SizedBox(height: 24),
          const Center(
            child: Text('Penukaran Telah Berhasil',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 8),
          const Center(
              child: Text('Voucher anda akan dikirim beberapa saat lagi',
                  style: TextStyle(color: Colors.grey))),
          const SizedBox(height: 24),
          Card(
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            color: Colors.grey[100],
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(DateTime.now().toLocal().toString(),
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 8),
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Voucher kadaluarsa pada'),
                      const Text('31 Agustus 2024')
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Poin'),
                      Text('$points Poin',
                          style: const TextStyle(fontWeight: FontWeight.w700))
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A)),
              onPressed: () {
                Navigator.of(context).popUntil((r) => r.isFirst);
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14.0),
                child: Text('Kembali ke Halaman Beranda'),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                // pop to root; user can navigate to Rewards from home
                Navigator.of(context).popUntil((r) => r.isFirst);
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14.0),
                child: Text('Pergi ke Halaman Hadiah'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
