class TripModel {
  final String id;
  final String date;
  final String time;
  final String departureLocation;
  final String departureAddress;
  final String arrivalLocation;
  final String arrivalAddress;
  final int price;
  final String? vehicleName;
  final String? vehiclePlate;
  final String? vehicleBrand;
  final String? vehicleType;
  final int availableSeats;

  TripModel({
    required this.id,
    required this.date,
    required this.time,
    required this.departureLocation,
    required this.departureAddress,
    required this.arrivalLocation,
    required this.arrivalAddress,
    required this.price,
    this.vehicleName,
    this.vehiclePlate,
    this.vehicleBrand,
    this.vehicleType,
    this.availableSeats = 1,
  });

  // Factory constructor untuk convert dari API response
  factory TripModel.fromApi(Map<String, dynamic> json) {
    final originLocation = json['origin_location'] as Map<String, dynamic>?;
    final destinationLocation =
        json['destination_location'] as Map<String, dynamic>?;

    // Parse price dengan aman, handle string atau number
    int parsedPrice = 0;
    final priceValue = json['price'];
    if (priceValue is num) {
      parsedPrice = priceValue.toInt();
    } else if (priceValue is String) {
      parsedPrice = double.tryParse(priceValue)?.toInt() ?? 0;
    }

    // Parse available_seats dengan aman
    int parsedSeats = 1;
    final seatsValue = json['available_seats'];
    if (seatsValue is num) {
      parsedSeats = seatsValue.toInt();
    } else if (seatsValue is String) {
      parsedSeats = int.tryParse(seatsValue) ?? 1;
    }

    // Format departure date into readable Indonesian string
    String _formatDate(String raw) {
      if (raw.isEmpty) return '';
      final dt = DateTime.tryParse(raw);
      if (dt == null) {
        // fallback: try to split ISO date
        try {
          return raw.split('T').first;
        } catch (_) {
          return raw;
        }
      }
      final days = [
        'Senin',
        'Selasa',
        'Rabu',
        'Kamis',
        'Jumat',
        'Sabtu',
        'Minggu'
      ];
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agu',
        'Sep',
        'Okt',
        'Nov',
        'Des'
      ];
      final dayName = days[dt.weekday - 1];
      final monthName = months[dt.month - 1];
      return '$dayName, ${dt.day} $monthName ${dt.year}';
    }

    return TripModel(
      id: json['id'].toString(),
      date: _formatDate(json['departure_date'] ?? ''),
      time: json['departure_time']?.substring(0, 5) ?? '', // HH:mm
      departureLocation: originLocation?['name'] ?? '',
      departureAddress:
          '${originLocation?['name'] ?? ''} (${originLocation?['province'] ?? 'PI'})',
      arrivalLocation: destinationLocation?['name'] ?? '',
      arrivalAddress:
          '${destinationLocation?['name'] ?? ''} (${destinationLocation?['province'] ?? 'PI'})',
      price: parsedPrice,
      vehicleName: json['vehicle_name'],
      vehiclePlate: json['vehicle_plate'],
      vehicleBrand: json['vehicle_brand'],
      vehicleType: json['vehicle_type'],
      availableSeats: parsedSeats,
    );
  }
}
