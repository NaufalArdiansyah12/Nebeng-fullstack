import 'package:flutter/material.dart';

class PinInputWidget extends StatelessWidget {
  final String pin;
  final int length;

  const PinInputWidget({
    Key? key,
    required this.pin,
    this.length = 6,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (index) {
        final isFilled = index < pin.length;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color(0xFF1E3A8A),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: Center(
            child: isFilled
                ? Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1E3A8A),
                      shape: BoxShape.circle,
                    ),
                  )
                : null,
          ),
        );
      }),
    );
  }
}
