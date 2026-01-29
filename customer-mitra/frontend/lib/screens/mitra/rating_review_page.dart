import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

class RatingReviewPage extends StatefulWidget {
  final int driverId;
  const RatingReviewPage({Key? key, required this.driverId}) : super(key: key);

  @override
  State<RatingReviewPage> createState() => _RatingReviewPageState();
}

class _RatingReviewPageState extends State<RatingReviewPage> {
  bool _loading = true;
  double _average = 0.0;
  int _total = 0;
  List<Map<String, dynamic>> _ratings = [];

  @override
  void initState() {
    super.initState();
    _loadRatings();
  }

  Future<void> _loadRatings() async {
    setState(() => _loading = true);
    try {
      final resp = await ApiService.getDriverRatings(driverId: widget.driverId);
      final avg = resp['average_rating'];
      if (avg != null) _average = double.tryParse(avg.toString()) ?? 0.0;
      _total = (resp['total_ratings'] ?? 0) is int
          ? resp['total_ratings']
          : int.tryParse((resp['total_ratings'] ?? '0').toString()) ?? 0;
      final list = resp['ratings'];
      if (list is List) {
        _ratings = List<Map<String, dynamic>>.from(
            list.map((e) => Map<String, dynamic>.from(e)));
      }
    } catch (e) {
      // ignore
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatDate(String? src) {
    if (src == null || src.isEmpty) return '';
    try {
      final dt = DateTime.parse(src);
      return DateFormat('dd/MM/yyyy').format(dt);
    } catch (e) {
      return src;
    }
  }

  Widget _buildStarRow(int rating) {
    return Row(
      children: List.generate(5, (i) {
        return Icon(
          i < rating ? Icons.star : Icons.star_border,
          color: const Color(0xFF10367d),
          size: 16,
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rating & Review'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: false,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: _ratings.length,
                      itemBuilder: (context, index) {
                        final r = _ratings[index];
                        final user = r['user'] is Map ? r['user'] : null;
                        final name = user != null
                            ? (user['name'] ?? user['nama'] ?? 'User')
                            : (r['user_name'] ?? 'User');
                        final avatarLetter =
                            (name ?? 'U').toString().trim().isNotEmpty
                                ? name.toString().trim()[0].toUpperCase()
                                : 'U';
                        final rating = (r['rating'] ?? r['rate'] ?? 0);
                        int ratingInt = 0;
                        if (rating is num)
                          ratingInt = (rating as num).toInt();
                        else
                          ratingInt = int.tryParse(rating.toString()) ?? 0;
                        final createdAt =
                            r['created_at'] ?? r['date'] ?? r['createdAt'];
                        final review = r['review'] ?? r['comment'] ?? '';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFECEFF1)),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2))
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: const Color(0xFFf0f4ff),
                                child: Text(avatarLetter,
                                    style: const TextStyle(
                                        color: Color(0xFF10367d),
                                        fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        _buildStarRow(ratingInt),
                                        Text(_formatDate(createdAt?.toString()),
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey)),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(review?.toString() ?? '',
                                        style: const TextStyle(
                                            color: Color(0xFF37474F))),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: () {},
                                icon: const Icon(Icons.more_vert,
                                    size: 18, color: Color(0xFF9E9E9E)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  if (_ratings.length > 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: GestureDetector(
                        onTap: () {},
                        child: const Text('Lebih Banyak',
                            style: TextStyle(color: Color(0xFF10367d))),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
