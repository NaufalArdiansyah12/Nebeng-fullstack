import 'package:flutter/material.dart';

class MobilVehicleCard extends StatelessWidget {
  final String vehicleName;
  final String vehiclePlate;
  final VoidCallback onTap;

  const MobilVehicleCard({
    Key? key,
    required this.vehicleName,
    required this.vehiclePlate,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.black26,
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFF1E40AF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.directions_car,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Kendaraan',
                      style: TextStyle(
                          fontSize: 15,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(
                    vehicleName.isNotEmpty
                        ? '$vehicleName • $vehiclePlate'
                        : 'Belum memilih kendaraan',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: onTap,
              child: const Text('Pilih Kendaraan'),
            ),
          ],
        ),
      ),
    );
  }
}
