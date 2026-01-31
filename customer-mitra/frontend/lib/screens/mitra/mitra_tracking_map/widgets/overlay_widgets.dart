import 'package:flutter/material.dart';

/// Top message button overlay
class TopMessageButton extends StatelessWidget {
  final VoidCallback onPressed;

  const TopMessageButton({
    Key? key,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 50,
      left: 0,
      right: 0,
      child: Center(
        child: Material(
          color: const Color(0xFF1E3A8A),
          borderRadius: BorderRadius.circular(25),
          elevation: 4,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(25),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.message, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Pesan',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Back button overlay
class BackButtonOverlay extends StatelessWidget {
  final VoidCallback onPressed;

  const BackButtonOverlay({
    Key? key,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 50,
      left: 16,
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        elevation: 4,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Container(
            padding: const EdgeInsets.all(12),
            child: const Icon(Icons.arrow_back, color: Colors.black87),
          ),
        ),
      ),
    );
  }
}

/// Toll toggle button overlay (for mobil only)
class TollToggleButton extends StatelessWidget {
  final bool avoidTolls;
  final VoidCallback onToggle;

  const TollToggleButton({
    Key? key,
    required this.avoidTolls,
    required this.onToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 110,
      right: 16,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        elevation: 4,
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  avoidTolls ? Icons.do_not_disturb_on : Icons.toll,
                  color: avoidTolls ? Colors.red : const Color(0xFF1E3A8A),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  avoidTolls ? 'Hindari Tol' : 'Lewat Tol',
                  style: TextStyle(
                    color: avoidTolls ? Colors.red : const Color(0xFF1E3A8A),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Countdown timer overlay
class CountdownTimerOverlay extends StatelessWidget {
  final Duration? timeUntilDeparture;
  final bool isDepartureReady;
  final String Function(Duration) formatCountdown;

  const CountdownTimerOverlay({
    Key? key,
    required this.timeUntilDeparture,
    required this.isDepartureReady,
    required this.formatCountdown,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (timeUntilDeparture == null) return const SizedBox.shrink();

    return Positioned(
      top: 120,
      left: 16,
      right: 16,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color:
                isDepartureReady ? Colors.green.shade600 : Colors.red.shade600,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isDepartureReady ? Icons.check_circle : Icons.timer,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isDepartureReady
                    ? 'Siap Berangkat!'
                    : 'Keberangkatan: ${formatCountdown(timeUntilDeparture!)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Action button widget
class ActionButton extends StatelessWidget {
  final bool isDepartureReady;
  final VoidCallback onPressed;

  const ActionButton({
    Key? key,
    required this.isDepartureReady,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: isDepartureReady ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                isDepartureReady ? const Color(0xFF1E3A8A) : Colors.grey,
            disabledBackgroundColor: Colors.grey[400],
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            isDepartureReady ? 'Mulai Menuju' : 'Menunggu waktu keberangkatan',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
