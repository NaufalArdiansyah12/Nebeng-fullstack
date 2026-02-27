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
  final int? bagasiCapacity;
  final int? jumlahBagasi;
  final String? serviceType;
  final String? transportation;
  final String?
      rideSource; // 'barang' or 'titip' - to identify which table the ride comes from
  final double? originLat;
  final double? originLon;
  final double? destinationLat;
  final double? destinationLon;

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
    this.bagasiCapacity,
    this.jumlahBagasi,
    this.serviceType,
    this.transportation,
    this.rideSource,
    this.originLat,
    this.originLon,
    this.destinationLat,
    this.destinationLon,
  });

  factory TripModel.fromApi(Map<String, dynamic> json) {
    final originLocation = json['origin_location'] as Map<String, dynamic>?;
    final destinationLocation =
        json['destination_location'] as Map<String, dynamic>?;

    // Prefer server-calculated price when available
    int parsedPrice = 0;
    dynamic calcPrice = json['calculated_price'] ?? json['calculatedPrice'];
    if (calcPrice == null && json['price_breakdown'] is Map) {
      final pb = json['price_breakdown'] as Map<String, dynamic>;
      calcPrice =
          pb['final_price'] ?? pb['total'] ?? pb['price'] ?? pb['amount'];
    }
    final priceValue = calcPrice ?? json['price'];
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
      transportation: (json['transportation'] ??
              json['transportation_type'] ??
              json['transportationType'] ??
              json['vehicle_type'] ??
              json['vehicleType'] ??
              '')
          .toString(),
      serviceType:
          (json['service_type'] ?? json['serviceType'] ?? json['service'] ?? '')
              .toString(),
      originLat: (() {
        final o = json['origin_location'] as Map<String, dynamic>?;
        if (o == null) return null;
        final v = o['latitude'] ?? o['lat'];
        if (v is num) return v.toDouble();
        if (v is String) return double.tryParse(v);
        return null;
      })(),
      originLon: (() {
        final o = json['origin_location'] as Map<String, dynamic>?;
        if (o == null) return null;
        final v = o['longitude'] ?? o['lon'] ?? o['lng'];
        if (v is num) return v.toDouble();
        if (v is String) return double.tryParse(v);
        return null;
      })(),
      destinationLat: (() {
        final d = json['destination_location'] as Map<String, dynamic>?;
        if (d == null) return null;
        final v = d['latitude'] ?? d['lat'];
        if (v is num) return v.toDouble();
        if (v is String) return double.tryParse(v);
        return null;
      })(),
      destinationLon: (() {
        final d = json['destination_location'] as Map<String, dynamic>?;
        if (d == null) return null;
        final v = d['longitude'] ?? d['lon'] ?? d['lng'];
        if (v is num) return v.toDouble();
        if (v is String) return double.tryParse(v);
        return null;
      })(),
      // Determine rideSource: if transportation_type exists (kereta/pesawat/bus), it's titip barang
      rideSource: () {
        final transportType = (json['transportation_type'] ??
                json['transportationType'] ??
                json['transportation'] ??
                '')
            .toString()
            .toLowerCase();
        if (transportType.contains('kereta') ||
            transportType.contains('pesawat') ||
            transportType.contains('bus')) {
          return 'titip';
        }
        return 'barang';
      }(),
    );
  }
}
