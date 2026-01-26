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
  final int? bagasiCapacity;
  final int? jumlahBagasi;
  final String? serviceType;

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
    this.bagasiCapacity,
    this.jumlahBagasi,
    this.serviceType,
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
      bagasiCapacity: () {
        final b = json['bagasi_capacity'] ??
            json['bagasiCapacity'] ??
            json['max_bagasi'] ??
            json['bagasi'];
        if (b == null) return null;
        if (b is num) return b.toInt();
        if (b is String) return int.tryParse(b) ?? null;
        return null;
      }(),
      jumlahBagasi: () {
        final j = json['jumlah_bagasi'] ??
            json['jumlahBagasi'] ??
            json['remaining_bagasi'] ??
            json['sisa_bagasi'];
        if (j == null) return null;
        if (j is num) return j.toInt();
        if (j is String) return int.tryParse(j) ?? null;
        return null;
      }(),
      serviceType:
          (json['service_type'] ?? json['serviceType'] ?? '').toString(),
    );
  }
}
