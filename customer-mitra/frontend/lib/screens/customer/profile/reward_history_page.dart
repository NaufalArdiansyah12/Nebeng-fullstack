import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/api_service.dart';
import 'package:intl/intl.dart';

class RewardHistoryPage extends StatefulWidget {
  const RewardHistoryPage({Key? key}) : super(key: key);

  @override
  State<RewardHistoryPage> createState() => _RewardHistoryPageState();
}

class _RewardHistoryPageState extends State<RewardHistoryPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _redemptions = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token') ?? '';

      if (token.isEmpty) {
        throw Exception('Token tidak ditemukan');
      }

      final redemptions = await ApiService.fetchMyRedemptions(token: token);

      // Debug: print structure of first redemption
      if (redemptions.isNotEmpty) {
        print('Sample redemption data: ${redemptions.first}');
      }

      setState(() {
        _redemptions = redemptions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat riwayat: ${e.toString()}')),
        );
      }
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return '-';
    try {
      final dt = DateTime.parse(date.toString());
      return DateFormat('dd MMM yyyy, HH:mm').format(dt);
    } catch (_) {
      return date.toString();
    }
  }

  String _getStatusText(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return 'Menunggu';
      case 'processing':
        return 'Diproses';
      case 'shipped':
        return 'Dikirim';
      case 'delivered':
        return 'Diterima';
      case 'completed':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status ?? 'Tidak diketahui';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'shipped':
        return Colors.purple;
      case 'delivered':
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        title: const Text('Riwayat Penukaran',
            style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _redemptions.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.6,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.history,
                                  size: 80,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Belum ada riwayat penukaran',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tukarkan poin Anda dengan reward menarik',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _redemptions.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final redemption = _redemptions[index];
                        return _buildRedemptionCard(redemption);
                      },
                    ),
            ),
    );
  }

  Widget _buildHistoryImage(dynamic imageUrl) {
    if (imageUrl == null) {
      return Center(
        child: Icon(
          Icons.card_giftcard,
          size: 32,
          color: Colors.grey[400],
        ),
      );
    }

    // data URL (base64)
    if (imageUrl is String && imageUrl.startsWith('data:')) {
      final m =
          RegExp(r'data:(?:image/[^;]+);base64,(.+)').firstMatch(imageUrl);
      if (m != null) {
        try {
          final bytes = base64Decode(m.group(1)!);
          return Image.memory(
            Uint8List.fromList(bytes),
            fit: BoxFit.cover,
            width: 80,
            height: 80,
            errorBuilder: (context, error, stackTrace) => Center(
              child: Icon(
                Icons.card_giftcard,
                size: 32,
                color: Colors.grey[400],
              ),
            ),
          );
        } catch (_) {
          return Center(
            child: Icon(
              Icons.card_giftcard,
              size: 32,
              color: Colors.grey[400],
            ),
          );
        }
      }
    }

    // relative uploads path - prefix with admin origin (port 3001)
    if (imageUrl is String && imageUrl.startsWith('/uploads')) {
      try {
        final base = ApiService
            .baseUrl; // e.g. http://10.0.2.2:8000 or http://localhost:8000
        final parsed = Uri.parse(base);
        final origin = Uri(scheme: parsed.scheme, host: parsed.host, port: 3001)
            .toString();
        final full = origin + imageUrl;
        return Image.network(
          full,
          fit: BoxFit.cover,
          width: 80,
          height: 80,
          errorBuilder: (context, error, stackTrace) => Center(
            child: Icon(
              Icons.card_giftcard,
              size: 32,
              color: Colors.grey[400],
            ),
          ),
        );
      } catch (_) {
        return Center(
          child: Icon(
            Icons.card_giftcard,
            size: 32,
            color: Colors.grey[400],
          ),
        );
      }
    }

    // absolute URL
    if (imageUrl is String &&
        (imageUrl.startsWith('http://') || imageUrl.startsWith('https://'))) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: 80,
        height: 80,
        errorBuilder: (context, error, stackTrace) => Center(
          child: Icon(
            Icons.card_giftcard,
            size: 32,
            color: Colors.grey[400],
          ),
        ),
      );
    }

    return Center(
      child: Icon(
        Icons.card_giftcard,
        size: 32,
        color: Colors.grey[400],
      ),
    );
  }

  Widget _buildRedemptionCard(Map<String, dynamic> redemption) {
    final reward = redemption['reward'] ?? {};
    final title = reward['title'] ?? redemption['reward_title'] ?? 'Reward';

    // Field name in database is 'points_spent'
    final pointsCost = redemption['points_spent'] ??
        redemption['points_cost'] ??
        redemption['points'] ??
        reward['points_cost'] ??
        0;

    final status = redemption['status'] ?? 'pending';
    final createdAt = redemption['created_at'] ?? redemption['redeemed_at'];
    final imageUrl = reward['image_url'] ?? redemption['reward_image_url'];
    final trackingNumber = redemption['tracking_number'];
    final shippingAddress = redemption['shipping_address'];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[200],
                    child: _buildHistoryImage(imageUrl),
                  ),
                ),
                const SizedBox(width: 12),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.stars,
                            size: 14,
                            color: Color(0xFFFFA500),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$pointsCost Poin',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E3A8A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatDate(createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Status: ',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getStatusText(status),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(status),
                        ),
                      ),
                    ),
                  ],
                ),
                if (trackingNumber != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.local_shipping,
                          size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Resi: ',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Expanded(
                        child: Text(
                          trackingNumber.toString(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E3A8A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (shippingAddress != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.location_on,
                          size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          shippingAddress.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
