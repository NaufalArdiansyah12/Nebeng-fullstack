import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/api_service.dart';
import 'reward_detail_page.dart';

class RewardPage extends StatefulWidget {
  const RewardPage({Key? key}) : super(key: key);

  @override
  State<RewardPage> createState() => _RewardPageState();
}

class _RewardPageState extends State<RewardPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _rewards = [];
  int _points = 0;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredRewards = [];

  @override
  void initState() {
    super.initState();
    _load();
    _searchController.addListener(_filterRewards);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterRewards() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredRewards = _rewards;
      } else {
        _filteredRewards = _rewards.where((reward) {
          final title = (reward['title'] ?? '').toString().toLowerCase();
          return title.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token') ?? '';

      int points = 0;
      if (token.isNotEmpty) {
        try {
          final profile = await ApiService.getProfile(token: token);
          if (profile['success'] == true && profile['data'] != null) {
            final user = profile['data']['user'] ?? profile['data'];
            final rawPoints =
                user['reward_points'] ?? user['rewardPoints'] ?? 0;
            if (rawPoints is num) {
              points = rawPoints.toInt();
            } else if (rawPoints is String) {
              points = int.tryParse(rawPoints) ?? 0;
            } else {
              points = 0;
            }
          }
        } catch (_) {
          // ignore profile fetch errors but keep points as 0
        }
      }

      final rewards = await ApiService.fetchRewards();
      setState(() {
        _points = points;
        _rewards = rewards;
        _filteredRewards = rewards;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat rewards: ${e.toString()}')),
        );
      }
    }
  }

  Widget _buildHeader() {
    return Container(
      color: const Color(0xFF1E3A8A),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16),
          child: Row(
            children: [
              // Back button
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Spacer(),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.notifications_none,
                    color: Color(0xFF1E3A8A)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final bottomPadding = mq.padding.bottom + 16.0;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(140),
        child: _buildHeader(),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.only(bottom: bottomPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    // Points Card (floating style)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 18),
                              child: Row(
                                children: [
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF6E5),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.stars_rounded,
                                        color: Color(0xFFFFA500),
                                        size: 28,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      '$_points Point',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF111827),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1),
                            Row(
                              children: [
                                Expanded(
                                  child: TextButton(
                                    onPressed: () {},
                                    child: const Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 14.0),
                                      child: Text('Tambah Point'),
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 48,
                                  color: Colors.grey[200],
                                ),
                                Expanded(
                                  child: TextButton(
                                    onPressed: () {},
                                    child: const Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 14.0),
                                      child: Text('Riwayat'),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Search Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Ketik untuk mencari reward kamu',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            prefixIcon:
                                Icon(Icons.search, color: Colors.grey[400]),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Category pill
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E3A8A),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Merchandise',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Spesial Diskon Buat Kamu',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111827),
                            ),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: const Text(
                              'Lihat semua >',
                              style: TextStyle(color: Color(0xFFEF4444)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Rewards List
                    _filteredRewards.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.search_off,
                                    size: 64,
                                    color: Colors.grey[300],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Tidak ada reward ditemukan',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : SizedBox(
                            height: 240,
                            child: ListView.separated(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              itemCount: _filteredRewards.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 12),
                              itemBuilder: (context, index) {
                                final r = _filteredRewards[index];
                                return _buildRewardCard(r);
                              },
                            ),
                          ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildRewardCard(Map<String, dynamic> r) {
    final pointsCost = r['points_cost'] ?? 0;
    final canRedeem = _points >= pointsCost;

    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: Container(
                  height: 120,
                  width: double.infinity,
                  color: Colors.grey[200],
                  child: r['image_url'] != null
                      ? Image.network(
                          r['image_url'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Icon(
                                Icons.card_giftcard,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                            );
                          },
                        )
                      : Center(
                          child: Icon(
                            Icons.card_giftcard,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                        ),
                ),
              ),
              if (!canRedeem)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.lock,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r['title'] ?? 'Reward',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFF1F2937),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      const Icon(
                        Icons.stars,
                        size: 16,
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
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: canRedeem
                          ? () async {
                              final result =
                                  await Navigator.of(context).push<bool>(
                                MaterialPageRoute(
                                  builder: (_) => RewardDetailPage(reward: r),
                                ),
                              );
                              if (result == true) {
                                _load();
                              }
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        disabledBackgroundColor: Colors.grey[300],
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        canRedeem ? 'Tukar' : 'Poin Kurang',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: canRedeem ? Colors.white : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
