import 'package:flutter/material.dart';

class NumericKeypad extends StatelessWidget {
  final Function(String) onNumberPressed;
  final VoidCallback onBackspace;

  const NumericKeypad({
    Key? key,
    required this.onNumberPressed,
    required this.onBackspace,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[200],
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildRow(['1', '2', '3']),
          const SizedBox(height: 8),
          _buildRow(['4', '5', '6']),
          const SizedBox(height: 8),
          _buildRow(['7', '8', '9']),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: Container()),
              Expanded(child: _buildKey('0')),
              Expanded(
                child: _buildBackspaceKey(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRow(List<String> numbers) {
    return Row(
      children: numbers.map((num) => Expanded(child: _buildKey(num))).toList(),
    );
  }

  Widget _buildKey(String number) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => onNumberPressed(number),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 56,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  number,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                if (number != '0' && number != '1') ...[
                  const SizedBox(height: 2),
                  Text(
                    _getLetters(number),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackspaceKey() {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onBackspace,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 56,
            alignment: Alignment.center,
            child: const Icon(
              Icons.backspace_outlined,
              size: 24,
              color: Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  String _getLetters(String number) {
    switch (number) {
      case '2':
        return 'ABC';
      case '3':
        return 'DEF';
      case '4':
        return 'GHI';
      case '5':
        return 'JKL';
      case '6':
        return 'MNO';
      case '7':
        return 'PQRS';
      case '8':
        return 'TUV';
      case '9':
        return 'WXYZ';
      default:
        return '';
    }
  }
}
