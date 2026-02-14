import 'package:flutter/material.dart';
import 'info_row.dart';

class InfoMitraCard extends StatelessWidget {
  final String ownerName;
  final String transportasi;
  final String plat;
  final String vehicleModel;
  final String warna;
  final String kursi;
  final bool isPublicTransport;

  const InfoMitraCard({
    Key? key,
    required this.ownerName,
    required this.transportasi,
    required this.plat,
    required this.vehicleModel,
    required this.warna,
    required this.kursi,
    this.isPublicTransport = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Informasi Mitra',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
            color: Colors.white,
          ),
          child: Column(
            children: [
              InfoRow(label: 'Nama Mitra', value: ownerName),
              InfoRow(
                label: 'Transportasi',
                value: transportasi,
                isLast: false,
              ),
              if (isPublicTransport)
                InfoRow(label: 'Jumlah Bagasi', value: kursi, isLast: true)
              else ...[
                InfoRow(label: 'Nomor Plat', value: plat),
                InfoRow(label: 'Tipe', value: vehicleModel),
                InfoRow(label: 'Warna', value: warna),
                InfoRow(label: 'Jumlah Kursi', value: kursi, isLast: true),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
