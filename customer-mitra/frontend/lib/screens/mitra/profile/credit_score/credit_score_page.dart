import 'package:flutter/material.dart';
import 'dart:math' as Math;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../services/api_service.dart';
import '../../rating_review_page.dart';

class CreditScorePage extends StatefulWidget {
  const CreditScorePage({Key? key}) : super(key: key);

  @override
  State<CreditScorePage> createState() => _CreditScorePageState();
}

class _CreditScorePageState extends State<CreditScorePage> {
  bool isLoading = true;
  double? score; // expected 0..5 scale
  double needleAngle = 0.0; // 0..1 relative

  @override
  void initState() {
    super.initState();
    _loadScore();
  }

  Future<void> _loadScore() async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');
      if (token != null) {
        final resp = await ApiService.getCreditScore(token: token);
        if (resp['success'] == true && resp['data'] != null) {
          final raw = resp['data'];
          double parsed = 0.0;
          if (raw is Map && raw['score'] != null) {
            parsed = (raw['score'] is num)
                ? raw['score'].toDouble()
                : double.tryParse(raw['score'].toString()) ?? 0.0;
          } else if (resp['data'] is num) {
            parsed = (resp['data'] as num).toDouble();
          }

          // normalize to 0..1 (assuming max score is 5)
          final angle = (parsed.clamp(0.0, 5.0)) / 5.0;

          setState(() {
            score = parsed;
            needleAngle = angle;
            isLoading = false;
          });
          return;
        }
        // If credit endpoint doesn't return score, fallback to profile.average_rating
        final profile = await ApiService.getProfile(token: token);
        if (profile['success'] == true && profile['data'] != null) {
          final user = profile['data']['user'] ?? profile['data'];
          double parsed = 0.0;
          if (user != null && user['average_rating'] != null) {
            parsed = (user['average_rating'] is num)
                ? user['average_rating'].toDouble()
                : double.tryParse(user['average_rating'].toString()) ?? 0.0;
          }
          final angle = (parsed.clamp(0.0, 5.0)) / 5.0;
          setState(() {
            score = parsed;
            needleAngle = angle;
            isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      // ignore
    }
    setState(() {
      isLoading = false;
      score = null;
      needleAngle = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Kredit Score',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  children: [
                    const SizedBox(height: 28),

                    // Gauge area
                    SizedBox(
                      height: 220,
                      child: Center(
                        child: CustomPaint(
                          size: const Size(280, 140),
                          painter: _GaugePainter(angle: needleAngle),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('SANGAT BURUK', style: TextStyle(fontSize: 12)),
                        Text('SANGAT BAIK', style: TextStyle(fontSize: 12)),
                      ],
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    CreditScoreDetailPage(score: score)),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF2B2B6B)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('View Score Details',
                            style: TextStyle(
                                color: Color(0xFF2B2B6B),
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double angle; // 0..1 relative position of needle
  _GaugePainter({required this.angle});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width * 0.45;
    final stroke = 18.0;

    final rect = Rect.fromCircle(center: center, radius: radius);
    final start = -3.14; // leftmost
    final sweep = 3.14; // semicircle

    final paints = [
      Paint()
        ..color = const Color(0xFFEF4444)
        ..strokeWidth = stroke
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.butt,
      Paint()
        ..color = const Color(0xFFFFA500)
        ..strokeWidth = stroke
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.butt,
      Paint()
        ..color = const Color(0xFFFCD34D)
        ..strokeWidth = stroke
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.butt,
      Paint()
        ..color = const Color(0xFF86EFAC)
        ..strokeWidth = stroke
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.butt,
      Paint()
        ..color = const Color(0xFF16A34A)
        ..strokeWidth = stroke
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.butt,
    ];

    final segment = sweep / paints.length;
    for (var i = 0; i < paints.length; i++) {
      canvas.drawArc(
          rect, start + segment * i, segment - 0.02, false, paints[i]);
    }

    // needle
    final needleAngle = start + sweep * angle;
    final needlePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 3;
    final needleLen = radius - stroke / 2 - 6;
    final needleEnd = Offset(center.dx + needleLen * Math.cos(needleAngle),
        center.dy + needleLen * Math.sin(needleAngle));
    canvas.drawLine(center, needleEnd, needlePaint);

    // center circle
    final centerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 12, centerPaint);
    final centerBorder = Paint()
      ..color = const Color(0xFF2B2B6B)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, 12, centerBorder);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CreditScoreDetailPage extends StatelessWidget {
  final double? score;

  const CreditScoreDetailPage({Key? key, this.score}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final display = score != null ? score!.toStringAsFixed(1) : '-';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Detail Kredit Score',
            style:
                TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          children: [
            const SizedBox(height: 40),
            Center(
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFF1F6FF),
                  border: Border.all(color: const Color(0xFF1E2A66), width: 6),
                ),
                child: Center(
                  child: Text(display,
                      style: const TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E2A66))),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text('Score Anda Saat Ini',
                style: TextStyle(fontSize: 14, color: Colors.black87)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () async {
                  // Navigate to existing RatingReviewPage for this mitra
                  try {
                    final prefs = await SharedPreferences.getInstance();
                    final token = prefs.getString('api_token');
                    if (token == null) return;
                    final profile = await ApiService.getProfile(token: token);
                    if (profile['success'] == true && profile['data'] != null) {
                      final user = profile['data']['user'] ?? profile['data'];
                      final id = (user != null && (user['id'] != null))
                          ? int.tryParse(user['id'].toString()) ??
                              (user['id'] is int ? user['id'] as int : 0)
                          : 0;
                      if (id > 0) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  RatingReviewPage(driverId: id)),
                        );
                      }
                    }
                  } catch (e) {
                    // ignore
                  }
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF2B2B6B)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Riwayat Kredit Score',
                    style: TextStyle(
                        color: Color(0xFF2B2B6B), fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
