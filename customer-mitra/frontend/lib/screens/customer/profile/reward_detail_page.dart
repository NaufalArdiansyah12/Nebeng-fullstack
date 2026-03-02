import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../../../services/api_service.dart';
import 'reward_address_page.dart';

class RewardDetailPage extends StatefulWidget {
  final Map<String, dynamic> reward;
  const RewardDetailPage({Key? key, required this.reward}) : super(key: key);

  @override
  State<RewardDetailPage> createState() => _RewardDetailPageState();
}

class _RewardDetailPageState extends State<RewardDetailPage> {
  bool _isProcessing = false;

  Future<void> _redeem() async {
    // Navigate to address page to collect shipping address, then redeem there.
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => RewardAddressPage(reward: widget.reward),
      ),
    );
    if (result == true && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.reward;
    final pointsCost = (r['points_cost'] ?? 0) as num;
    final stock = (r['stock'] ?? 0) as num;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        title: const Text('Penawaran Spesial',
            style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: Column(
        children: [
          // Image
          if (r['image_url'] != null)
            _buildDetailImage(r['image_url'])
          else
            Container(height: 200, color: Colors.grey[200]),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  r['title'] ?? 'Dapatkan Merchandise',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  r['subtitle'] ?? 'Berlaku s.d 31 Agustus 2024',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${pointsCost.toInt()} / Poin',
                              style: const TextStyle(
                                  color: Color(0xFF1E3A8A),
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Sisa Stock',
                            style: TextStyle(color: Colors.grey[500])),
                        Text('${stock.toInt()}',
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                ExpansionTile(
                  title: const Text('Syarat dan Ketentuan'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      child: Text(r['terms'] ?? 'Tidak ada syarat tambahan'),
                    ),
                  ],
                ),
                const SizedBox(height: 200),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: Colors.white,
        child: Row(
          children: [
            Expanded(
              child: Text('${pointsCost.toInt()} Poin',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
            ElevatedButton(
              onPressed: _isProcessing ? null : _redeem,
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20.0, vertical: 12.0),
                child: Text(_isProcessing ? 'Memproses...' : 'Tukar',
                    style: const TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailImage(dynamic imageUrl) {
    if (imageUrl == null)
      return Container(height: 200, color: Colors.grey[200]);

    // data URL (base64)
    if (imageUrl is String && imageUrl.startsWith('data:')) {
      final m =
          RegExp(r'data:(?:image/[^;]+);base64,(.+)').firstMatch(imageUrl);
      if (m != null) {
        try {
          final bytes = base64Decode(m.group(1)!);
          return Image.memory(
            Uint8List.fromList(bytes),
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                Container(height: 200, color: Colors.grey[200]),
          );
        } catch (_) {
          return Container(height: 200, color: Colors.grey[200]);
        }
      }
    }

    // Relative uploads path - prefix admin origin (port 3001)
    if (imageUrl is String && imageUrl.startsWith('/uploads')) {
      try {
        final base = ApiService.baseUrl; // e.g. http://10.0.2.2:8000
        final parsed = Uri.parse(base);
        final origin = Uri(scheme: parsed.scheme, host: parsed.host, port: 3001)
            .toString();
        final full = origin + imageUrl;
        return Image.network(
          full,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              Container(height: 200, color: Colors.grey[200]),
        );
      } catch (_) {
        return Container(height: 200, color: Colors.grey[200]);
      }
    }

    // absolute URL
    if (imageUrl is String &&
        (imageUrl.startsWith('http://') || imageUrl.startsWith('https://'))) {
      return Image.network(
        imageUrl,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            Container(height: 200, color: Colors.grey[200]),
      );
    }

    return Container(height: 200, color: Colors.grey[200]);
  }
}
