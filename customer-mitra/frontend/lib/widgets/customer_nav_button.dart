import 'package:flutter/material.dart';

/// A compact bottom navigation button that matches the customer's app style.
///
/// Usage:
/// ```dart
/// CustomerNavButton(
///   icon: Icons.home,
///   label: 'Beranda',
///   active: true,
///   onTap: () {},
/// )
/// ```
class CustomerNavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  const CustomerNavButton({
    Key? key,
    required this.icon,
    required this.label,
    this.active = false,
    this.onTap,
  }) : super(key: key);

  static const Color _activeColor = Color(0xFF1E3A8A);
  static const Color _inactiveIconColor = Color(0xFFBFCFE3);
  static const Color _inactiveBg = Color(0xFFEFF5FF);
  static const double _iconSizeActive = 28.0;
  static const double _iconSizeInactive = 22.0;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon area
            if (active) ...[
              Icon(icon, color: _activeColor, size: _iconSizeActive),
            ] else ...[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _inactiveBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Icon(icon,
                      color: _inactiveIconColor, size: _iconSizeInactive),
                ),
              ),
            ],

            const SizedBox(height: 6),

            // Label
            Text(
              label,
              style: TextStyle(
                color: active ? _activeColor : _inactiveIconColor,
                fontSize: 13,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
