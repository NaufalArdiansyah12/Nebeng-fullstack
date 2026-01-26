import 'package:flutter/material.dart';

class PaymentInfoCard extends StatelessWidget {
  final String label;
  final String value;
  final bool isSelectable;
  final bool isAmount;

  const PaymentInfoCard({
    Key? key,
    required this.label,
    required this.value,
    this.isSelectable = false,
    this.isAmount = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        isSelectable
            ? SelectableText(
                value,
                style: TextStyle(
                  fontSize: isAmount ? 24 : 18,
                  fontWeight: FontWeight.w700,
                  color: isAmount ? const Color(0xFF0F4AA3) : Colors.black87,
                ),
              )
            : Text(
                value,
                style: TextStyle(
                  fontSize: isAmount ? 24 : 18,
                  fontWeight: FontWeight.w700,
                  color: isAmount ? const Color(0xFF0F4AA3) : Colors.black87,
                ),
              ),
      ],
    );
  }
}
