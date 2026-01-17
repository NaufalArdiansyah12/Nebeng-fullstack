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
  final String? photoUrl;
  final String? weight;
  final String? description;

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
    this.photoUrl,
    this.weight,
    this.description,
  });

  factory TripModel.fromApi(Map<String, dynamic> json) {
    final originLocation = json['origin_location'] as Map<String, dynamic>?;
    final destinationLocation =
        json['destination_location'] as Map<String, dynamic>?;

    int parsedPrice = 0;
    final priceValue = json['price'];
    if (priceValue is num) {
      parsedPrice = priceValue.toInt();
    } else if (priceValue is String) {
      parsedPrice = double.tryParse(priceValue)?.toInt() ?? 0;
    }

    int parsedSeats = 1;
    final seatsValue = json['available_seats'];
    if (seatsValue is num) {
      parsedSeats = seatsValue.toInt();
    } else if (seatsValue is String) {
      parsedSeats = int.tryParse(seatsValue) ?? 1;
    }

    // Extract photo URL from extra field
    String? photoUrl;
    String? weight;
    String? description;
    if (json['extra'] != null) {
      if (json['extra'] is Map) {
        photoUrl = json['extra']['photo'];
        weight = json['extra']['weight'];
        description = json['extra']['description'];
      } else if (json['extra'] is String) {
        try {
          final extraMap = Map<String, dynamic>.from(json['extra'] as Map);
          photoUrl = extraMap['photo'];
          weight = extraMap['weight'];
          description = extraMap['description'];
        } catch (e) {
          photoUrl = null;
          weight = null;
          description = null;
        }
      }
    }

    // Normalize id: if numeric, store as integer string (no decimals)
    String normalizedId;
    if (json['id'] is num) {
      normalizedId = (json['id'] as num).toInt().toString();
    } else {
      // If string like "1.0" ensure we extract integer part
      final idStr = json['id']?.toString() ?? '';
      if (idStr.contains('.')) {
        final parts = idStr.split('.');
        normalizedId = int.tryParse(parts[0])?.toString() ?? idStr;
      } else {
        normalizedId = idStr;
      }
    }

    // Format departure date into readable Indonesian string
    String _formatDate(String raw) {
      if (raw.isEmpty) return '';
      final dt = DateTime.tryParse(raw);
      if (dt == null) {
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
      return '${days[dt.weekday - 1]}, ${dt.day} ${months[dt.month - 1]} ${dt.year}';
    }

    return TripModel(
      id: normalizedId,
      date: _formatDate(json['departure_date'] ?? ''),
      time: json['departure_time']?.substring(0, 5) ?? '',
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
      photoUrl: photoUrl,
      weight: weight,
      description: description,
    );
  }
}
