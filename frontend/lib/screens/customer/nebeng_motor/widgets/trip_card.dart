import 'package:flutter/material.dart';
import '../models/trip_model.dart';
import '../utils/theme.dart';

class TripCard extends StatelessWidget {
  final TripModel trip;
  final VoidCallback onTap;

  const TripCard({
    Key? key,
    required this.trip,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                trip.date,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              if ((trip.serviceType ?? '').isNotEmpty)
                Row(
                  children: [
                    Icon(
                      _serviceIcon(trip.serviceType),
                      size: 16,
                      color: Colors.black87,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _serviceLabel(trip.serviceType),
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),
          _buildLocationRow(
            icon: Icons.arrow_upward,
            iconColor: NebengMotorTheme.greenIcon,
            title: trip.departureLocation,
            subtitle: trip.departureAddress,
          ),
          const SizedBox(height: 8),
          _buildLocationRow(
            icon: Icons.location_on,
            iconColor: NebengMotorTheme.orangeIcon,
            title: trip.arrivalLocation,
            subtitle: trip.arrivalAddress,
          ),
          const SizedBox(height: 12),
          if ((trip.serviceType ?? '').toLowerCase() != 'barang')
            Row(
              children: [
                const Icon(Icons.event_seat, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Sisa kursi: ${trip.availableSeats}',
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
              ],
            ),
          const SizedBox(height: 8),
          if ((trip.jumlahBagasi ?? 0) > 0)
            Padding(
              padding: const EdgeInsets.only(top: 6.0, bottom: 8.0),
              child: Row(
                children: [
                  Icon(Icons.card_travel, size: 14, color: Colors.grey[700]),
                  const SizedBox(width: 8),
                  Text(
                    'Sisa ${trip.jumlahBagasi} Bagasi',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  trip.time,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
              ),
              if ((trip.bagasiCapacity ?? 0) > 0)
                Row(
                  children: [
                    Icon(
                      Icons.card_travel,
                      color: Colors.grey[700],
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Maks. ${trip.bagasiCapacity} Bagasi',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[800],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 1,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 6),
          Center(
            child: TextButton(
              onPressed: onTap,
              child: Text(
                'Selengkapnya',
                style: TextStyle(
                  color: NebengMotorTheme.primaryBlue,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: iconColor,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  String _serviceLabel(String? s) {
    final v = (s ?? '').toString().toLowerCase();
    switch (v) {
      case 'tebengan':
        return 'Hanya Tebengan';
      case 'barang':
        return 'Hanya Titip Barang';
      case 'both':
        return 'Barang dan Tebengan';
      default:
        return v.isNotEmpty ? _titleCase(v) : '';
    }
  }

  IconData _serviceIcon(String? s) {
    final v = (s ?? '').toString().toLowerCase();
    switch (v) {
      case 'tebengan':
        return Icons.person;
      case 'barang':
        return Icons.local_shipping;
      case 'both':
        return Icons.layers;
      default:
        return Icons.info_outline;
    }
  }

  String _titleCase(String s) {
    return s.split(RegExp(r'\s+')).map((w) {
      if (w.isEmpty) return w;
      return w[0].toUpperCase() + (w.length > 1 ? w.substring(1) : '');
    }).join(' ');
  }
}
