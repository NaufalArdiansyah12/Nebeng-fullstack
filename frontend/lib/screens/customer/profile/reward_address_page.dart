import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/api_service.dart';
import '../../widgets/pin_input_widget.dart';
import '../../widgets/numeric_keypad.dart';
import 'reward_success_page.dart';

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
    // show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Konfirmasi Tukar'),
        content: const Text('Apakah anda yakin ingin tukar voucher?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Tidak'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A)),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text('Iya'),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // ask for PIN
    final pin = await _askForPin();
    if (pin == null || pin.length != 6) return;

    setState(() => _isSaving = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('api_token');
    if (token == null || token.isEmpty) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Silakan login terlebih dahulu'),
            backgroundColor: Colors.red));
      setState(() => _isSaving = false);
      return;
    }

    final shipping = {
      'name': _nameCtrl.text.trim(),
      'address': _addressCtrl.text.trim(),
      'detail': _detailCtrl.text.trim(),
    };

    try {
      final data = await ApiService.redeemReward(
        token: token,
        rewardId: (widget.reward['id'] as num).toInt(),
        metadata: {
          'shipping_address': shipping,
          'pin': pin,
        },
      );
      if (mounted) {
        // navigate to success page and replace this page
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
                  PinInputWidget(pin: pin, length: 6),
                  const Spacer(),
                  NumericKeypad(
                    onNumberPressed: (val) {
                      if (pin.length < 6) {
                        setSt(() => pin = pin + val);
                        if (pin.length + 1 == 6) {
                          // delay a bit so user sees the last dot
                          Future.delayed(const Duration(milliseconds: 150), () {
                            Navigator.of(ctx).pop(pin + val);
                          });
                        }
                      }
                    },
                    onBackspace: () {
                      if (pin.isNotEmpty)
                        setSt(() => pin = pin.substring(0, pin.length - 1));
                    },
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
        title: const Text('Tambah Alamat'),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).maybePop()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration:
                    const InputDecoration(labelText: 'Nama', hintText: 'Rumah'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Nama harus diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressCtrl,
                decoration: const InputDecoration(
                    labelText: 'Alamat', hintText: 'Jl. Contoh No. 1'),
                maxLines: 2,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Alamat harus diisi'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _detailCtrl,
                decoration: const InputDecoration(
                    labelText: 'Detail Alamat', hintText: 'Gg. Arjuna No. 59'),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveAndRedeem,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14.0),
                    child: Text(
                        _isSaving ? 'Memproses...' : 'Simpan Alamat & Tukar'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
