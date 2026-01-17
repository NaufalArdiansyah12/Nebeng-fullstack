import 'package:flutter/material.dart';
import 'location_input_field.dart';
import 'date_input_field.dart';

class FormSection extends StatelessWidget {
  final String? lokasiAwal;
  final String? lokasiAwalAddress;
  final String? lokasiTujuan;
  final String? lokasiTujuanAddress;
  final DateTime? tanggalKeberangkatan;
  final VoidCallback onLokasiAwalTap;
  final VoidCallback onLokasiTujuanTap;
  final VoidCallback onTanggalTap;

  const FormSection({
    Key? key,
    this.lokasiAwal,
    this.lokasiAwalAddress,
    this.lokasiTujuan,
    this.lokasiTujuanAddress,
    this.tanggalKeberangkatan,
    required this.onLokasiAwalTap,
    required this.onLokasiTujuanTap,
    required this.onTanggalTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Location Container with subtle shadow
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: LocationInputField(
                    icon: Icons.my_location_rounded,
                    iconColor: Colors.white,
                    iconBgColor: const Color(0xFF10B981),
                    label: 'Lokasi Awal',
                    value: lokasiAwal,
                    address: lokasiAwalAddress,
                    onTap: onLokasiAwalTap,
                  ),
                ),
                // Divider with connecting line
                Padding(
                  padding: const EdgeInsets.only(left: 38),
                  child: Row(
                    children: [
                      Container(
                        width: 2,
                        height: 24,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              const Color(0xFF10B981).withOpacity(0.3),
                              const Color(0xFFF97316).withOpacity(0.3),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          height: 1,
                          color: Colors.grey[200],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: LocationInputField(
                    icon: Icons.location_on_rounded,
                    iconColor: Colors.white,
                    iconBgColor: const Color(0xFFF97316),
                    label: 'Lokasi Tujuan',
                    value: lokasiTujuan,
                    address: lokasiTujuanAddress,
                    onTap: onLokasiTujuanTap,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Date Container with subtle shadow
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: DateInputField(
              selectedDate: tanggalKeberangkatan,
              onTap: onTanggalTap,
            ),
          ),
        ],
      ),
    );
  }
}