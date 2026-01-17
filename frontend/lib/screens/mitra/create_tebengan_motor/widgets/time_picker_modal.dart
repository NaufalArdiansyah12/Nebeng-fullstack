import 'package:flutter/material.dart';

class TimePickerModal extends StatefulWidget {
  final TimeOfDay? initialTime;

  const TimePickerModal({
    Key? key,
    this.initialTime,
  }) : super(key: key);

  @override
  State<TimePickerModal> createState() => _TimePickerModalState();
}

class _TimePickerModalState extends State<TimePickerModal> {
  late int _hour;
  late int _minute;

  @override
  void initState() {
    super.initState();
    _hour = widget.initialTime?.hour ?? TimeOfDay.now().hour;
    _minute = widget.initialTime?.minute ?? TimeOfDay.now().minute;
  }

  void _incrementHour() {
    setState(() {
      _hour = (_hour + 1) % 24;
    });
  }

  void _decrementHour() {
    setState(() {
      _hour = (_hour - 1 + 24) % 24;
    });
  }

  void _incrementMinute() {
    setState(() {
      _minute = (_minute + 1) % 60;
    });
  }

  void _decrementMinute() {
    setState(() {
      _minute = (_minute - 1 + 60) % 60;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'PILIH WAKTU',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6B7280),
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Hour Picker
                  _buildTimePicker(
                    value: _hour,
                    onIncrement: _incrementHour,
                    onDecrement: _decrementHour,
                    isHour: true,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      ':',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),
                  // Minute Picker
                  _buildTimePicker(
                    value: _minute,
                    onIncrement: _incrementMinute,
                    onDecrement: _decrementMinute,
                    isHour: false,
                  ),
                ],
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(
                      context, TimeOfDay(hour: _hour, minute: _minute));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E40AF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Pilih',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimePicker({
    required int value,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
    required bool isHour,
  }) {
    return Column(
      children: [
        IconButton(
          onPressed: onIncrement,
          icon: Icon(
            Icons.keyboard_arrow_up,
            color: const Color(0xFF9CA3AF),
            size: 32,
          ),
        ),
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: isHour ? const Color(0xFF1E40AF) : const Color(0xFFE5E7EB),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            value.toString().padLeft(2, '0'),
            style: TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.bold,
              color: isHour ? Colors.white : const Color(0xFF1F2937),
            ),
          ),
        ),
        IconButton(
          onPressed: onDecrement,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: const Color(0xFF9CA3AF),
            size: 32,
          ),
        ),
      ],
    );
  }
}