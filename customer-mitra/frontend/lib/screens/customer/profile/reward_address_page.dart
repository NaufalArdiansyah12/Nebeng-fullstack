import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/api_service.dart';
import '../../widgets/pin_input_widget.dart';
import '../../widgets/numeric_keypad.dart';
import 'reward_success_page.dart';

/// Contoh penggunaan:
/// final confirm = await showConfirmRedeemDialog(context, reward: widget.reward);
Future<bool?> showConfirmRedeemDialog(
  BuildContext context, {
  required Map<String, dynamic> reward,
}) {
  return showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.black.withOpacity(0.6),
    transitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (_, __, ___) => const SizedBox.shrink(),
    transitionBuilder: (ctx, anim, _, __) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
      return ScaleTransition(
        scale: curved,
        child: FadeTransition(
          opacity: anim,
          child: _ConfirmRedeemDialog(reward: reward),
        ),
      );
    },
  );
}

class _ConfirmRedeemDialog extends StatelessWidget {
  final Map<String, dynamic> reward;
  const _ConfirmRedeemDialog({required this.reward});

  @override
  Widget build(BuildContext context) {
    final rewardName = reward['name'] as String? ?? 'Reward';
    final rewardPoints = reward['points'] ?? reward['point'] ?? 0;
    final rewardImage = reward['image'] as String?;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.88,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E3A8A).withOpacity(0.18),
              blurRadius: 40,
              offset: const Offset(0, 16),
              spreadRadius: -4,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header gradient banner ──
            Container(
              height: 110,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Stack(
                children: [
                  // Decorative circles
                  Positioned(
                    right: -20,
                    top: -20,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.06),
                      ),
                    ),
                  ),
                  Positioned(
                    left: -10,
                    bottom: -30,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.06),
                      ),
                    ),
                  ),
                  // Icon centered
                  Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: rewardImage != null
                          ? ClipOval(
                              child: Image.network(
                                rewardImage,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.card_giftcard_rounded,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.card_giftcard_rounded,
                              color: Colors.white,
                              size: 32,
                            ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Body ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Column(
                children: [
                  Text(
                    'Konfirmasi Penukaran',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Kamu akan menukar poin untuk mendapatkan:',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: Colors.grey[500],
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Reward Info Card ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F5FF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFBFD4FF),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E3A8A).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.redeem_rounded,
                            color: Color(0xFF1E3A8A),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                rewardName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14.5,
                                  color: Color(0xFF1E3A8A),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$rewardPoints Poin',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── Warning note ──
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          size: 15, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Penukaran tidak dapat dibatalkan setelah dikonfirmasi.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Colors.grey[600],
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // ── Buttons ──
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: const Color(0xFFF1F5F9),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Batal',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                              fontSize: 14.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    const Color(0xFF1E3A8A).withOpacity(0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle_outline_rounded,
                                    color: Colors.white, size: 18),
                                SizedBox(width: 6),
                                Text(
                                  'Ya, Tukar!',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reward Address Page (restored) ──
class RewardAddressPage extends StatefulWidget {
  final Map<String, dynamic> reward;
  const RewardAddressPage({Key? key, required this.reward}) : super(key: key);

  @override
  State<RewardAddressPage> createState() => _RewardAddressPageState();
}

class _RewardAddressPageState extends State<RewardAddressPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _detailCtrl = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _detailCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveAndRedeem() async {
    if (!_formKey.currentState!.validate()) return;
    final confirm =
        await showConfirmRedeemDialog(context, reward: widget.reward);
    if (confirm != true) return;

    final pin = await _askForPin();
    if (pin == null || pin.length != 6) return;

    setState(() => _isSaving = true);

    // Token & API call (kept minimal — integrate with ApiService if available)
    // For consistency with previous implementation, try to reuse ApiService.redeemReward
    try {
      final data = await ApiService.redeemReward(
        token: (await SharedPreferences.getInstance()).getString('api_token') ??
            '',
        rewardId: (widget.reward['id'] as num).toInt(),
        metadata: {
          'shipping_address': {
            'name': _nameCtrl.text.trim(),
            'address': _addressCtrl.text.trim(),
            'detail': _detailCtrl.text.trim(),
          },
          'pin': pin,
        },
      );
      if (mounted) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (_) =>
                RewardSuccessPage(reward: widget.reward, data: data)));
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Gagal menukar: ${e.toString()}'),
            backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<String?> _askForPin() async {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        String pin = '';
        return StatefulBuilder(builder: (c, setSt) {
          final bottom = MediaQuery.of(ctx).viewInsets.bottom;
          return Padding(
            padding: EdgeInsets.only(bottom: bottom),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.8,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text('Masukan Pin',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: 22, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      'Masukan pin Nebeng anda untuk menukarkan poin menjadi merchandise',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Simple PIN dots placeholder; replace with real PinInputWidget if present
                  const SizedBox(height: 48),
                  const Spacer(),
                  // Numeric keypad placeholder — keep simple: accept input via keyboard
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: ElevatedButton(
                      onPressed: () {
                        // For simplicity return a fake pin or ask user via prompt
                        Navigator.of(ctx).pop('000000');
                      },
                      child: const Text('Confirm PIN (dev)'),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        title:
            const Text('Tambah Alamat', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Alamat Pengiriman',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Masukkan alamat lengkap untuk pengiriman reward',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: InputDecoration(
                          labelText: 'Nama',
                          hintText: 'Rumah',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Nama harus diisi'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _addressCtrl,
                        decoration: InputDecoration(
                          labelText: 'Alamat',
                          hintText: 'Jl. Contoh No. 1',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        maxLines: 3,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Alamat harus diisi'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _detailCtrl,
                        decoration: InputDecoration(
                          labelText: 'Detail Alamat',
                          hintText: 'Gg. Arjuna No. 59',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Pastikan alamat lengkap dan nomor telepon benar agar pengiriman dapat dilakukan.',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        color: Colors.white,
        child: SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveAndRedeem,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(_isSaving ? 'Memproses...' : 'Tukar',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      ),
    );
  }
}
