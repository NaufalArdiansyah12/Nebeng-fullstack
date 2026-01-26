import 'package:flutter/material.dart';

class BagasiSelectorDialog extends StatefulWidget {
  final int? currentCapacity;

  const BagasiSelectorDialog({Key? key, this.currentCapacity})
      : super(key: key);

  @override
  State<BagasiSelectorDialog> createState() => _BagasiSelectorDialogState();
}

class _BagasiSelectorDialogState extends State<BagasiSelectorDialog> {
  int? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentCapacity;
  }

  Widget _option(String label, int kg) {
    final selected = _selected == kg;
    return InkWell(
      onTap: () => Navigator.of(context).pop(kg),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE8F0FF) : const Color(0xFFF6F8FB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFF1E40AF) : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF1E40AF)
                    : const Color(0xFFF0F6FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.luggage,
                color: selected ? Colors.white : const Color(0xFF1E40AF),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500)),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: Color(0xFF1E40AF)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pilih Kapasitas Bagasi',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              _option('Kecil - Maksimal 5 Kg', 5),
              const SizedBox(height: 12),
              _option('Sedang - Maksimal 10 Kg', 10),
              const SizedBox(height: 12),
              _option('Besar - Maksimal 20 Kg', 20),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
