import 'dart:async';

/// Helper class for managing countdown timers
class CountdownHelper {
  Timer? _timer;
  Function(Duration?)? _onUpdate;

  /// Start countdown to a specific departure date and time
  void start({
    required String departureDate,
    required String departureTime,
    required Function(Duration?) onUpdate,
  }) {
    _onUpdate = onUpdate;

    try {
      if (departureDate.isEmpty || departureTime.isEmpty) {
        _onUpdate?.call(null);
        return;
      }

      final departureDateTimeParts = departureDate.split('T')[0].split('-');
      final departureTimeParts = departureTime.split(':');

      final departureDateTime = DateTime(
        int.parse(departureDateTimeParts[0]),
        int.parse(departureDateTimeParts[1]),
        int.parse(departureDateTimeParts[2]),
        int.parse(departureTimeParts[0]),
        int.parse(departureTimeParts[1]),
      );

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        final now = DateTime.now();
        final difference = departureDateTime.difference(now);

        if (difference.isNegative) {
          _onUpdate?.call(null);
          cancel();
        } else {
          _onUpdate?.call(difference);
        }
      });
    } catch (e) {
      print('Error starting countdown: $e');
      _onUpdate?.call(null);
    }
  }

  /// Cancel the countdown timer
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  /// Dispose and clean up resources
  void dispose() {
    cancel();
    _onUpdate = null;
  }
}
