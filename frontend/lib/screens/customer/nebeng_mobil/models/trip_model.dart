class TripModel {
  final String id;
  final String date;
  final String time;
  final String departureLocation;
  final String departureAddress;
  final String arrivalLocation;
  final String arrivalAddress;
  final int price;
  final int availableSeats;
  final int maxPassengers;

  TripModel({
    required this.id,
    required this.date,
    required this.time,
    required this.departureLocation,
    required this.departureAddress,
    required this.arrivalLocation,
    required this.arrivalAddress,
    required this.price,
    this.availableSeats = 3,
    this.maxPassengers = 4,
  });

  factory TripModel.fromApi(Map<String, dynamic> json) {
    final originLocation = (json['origin_location'] ?? json['originLocation'])
        as Map<String, dynamic>?;
    final destinationLocation = (json['destination_location'] ??
        json['destinationLocation']) as Map<String, dynamic>?;

    int parsedPrice = 0;
    final priceValue = json['price'];
    if (priceValue is num) {
      parsedPrice = priceValue.toInt();
    } else if (priceValue is String) {
      parsedPrice = double.tryParse(priceValue)?.toInt() ?? 0;
    }

    int parsedSeats = 1;
    if (json['available_seats'] is num) {
      parsedSeats = (json['available_seats'] as num).toInt();
    } else if (json['car_ride'] != null &&
        json['car_ride']['available_seats'] is num) {
      parsedSeats = (json['car_ride']['available_seats'] as num).toInt();
    } else if (json['available_seats'] is String) {
      parsedSeats = int.tryParse(json['available_seats']) ?? 1;
    }

    // Format date into readable Indonesian string
    String _formatDate(String raw) {
      if (raw.isEmpty) return '';
      final dt = DateTime.tryParse(raw);
      if (dt == null) return raw.split('T').first;
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
      return '${days[dt.weekday - 1]}, ${dt.day} ${months[dt.month - 1]} ${dt.year}';
    }

    return TripModel(
      id: json['id'].toString(),
      date: _formatDate(json['departure_date'] ?? ''),
      time: (() {
        final rt = (json['departure_time'] ?? '').toString();
        return rt.length >= 5 ? rt.substring(0, 5) : rt;
      })(),
      departureLocation: originLocation?['name'] ?? '',
      departureAddress: (() {
        final name = originLocation?['name'] ?? '';
        final prov = (originLocation?['province'] ?? '').toString().trim();
        return prov.isNotEmpty ? '$name ($prov)' : name;
      })(),
      arrivalLocation: destinationLocation?['name'] ?? '',
      arrivalAddress: (() {
        final name = destinationLocation?['name'] ?? '';
        final prov = (destinationLocation?['province'] ?? '').toString().trim();
        return prov.isNotEmpty ? '$name ($prov)' : name;
      })(),
      price: parsedPrice,
      availableSeats: parsedSeats,
      maxPassengers: parsedSeats,
    );
  }
}
