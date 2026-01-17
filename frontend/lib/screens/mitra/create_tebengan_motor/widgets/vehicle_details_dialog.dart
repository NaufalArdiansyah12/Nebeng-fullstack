import 'package:flutter/material.dart';

class VehicleDetailsDialog extends StatelessWidget {
  final TextEditingController vehicleNameController;
  final TextEditingController vehiclePlateController;
  final TextEditingController vehicleBrandController;
  final TextEditingController vehicleTypeController;
  final TextEditingController vehicleColorController;
  final TextEditingController priceController;
  final TextEditingController seatsController;

  const VehicleDetailsDialog({
    Key? key,
    required this.vehicleNameController,
    required this.vehiclePlateController,
    required this.vehicleBrandController,
    required this.vehicleTypeController,
    required this.vehicleColorController,
    required this.priceController,
    required this.seatsController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detail Kendaraan & Tarif',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: vehicleNameController,
              label: 'Nama Mitra',
              hint: 'Contoh: Gamu Takayama',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: vehiclePlateController,
              label: 'Nomor Registrasi',
              hint: 'Contoh: N535YZ',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: vehicleBrandController,
              label: 'Merk',
              hint: 'Contoh: Honda',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: vehicleTypeController,
              label: 'Tipe',
              hint: 'Contoh: Beat',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: vehicleColorController,
              label: 'Warna',
              hint: 'Contoh: Hitam',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: priceController,
              label: 'Tarif per Penumpang',
              hint: 'Contoh: 50000',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: seatsController,
              label: 'Jumlah Kursi Tersedia',
              hint: 'Contoh: 1',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E40AF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Simpan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}
