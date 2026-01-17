import 'package:flutter/material.dart';

class DateInputField extends StatelessWidget {
  final DateTime? selectedDate;
  final VoidCallback onTap;

  const DateInputField({
    Key? key,
    this.selectedDate,
    required this.onTap,
  }) : super(key: key);

  String _formatDateLong(DateTime date) {
    final days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu'
    ];
    final dayName = days[date.weekday - 1];
    return '$dayName, ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.calendar_month,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              selectedDate != null
                  ? _formatDateLong(selectedDate!)
                  : 'Tanggal Keberangkatan',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
