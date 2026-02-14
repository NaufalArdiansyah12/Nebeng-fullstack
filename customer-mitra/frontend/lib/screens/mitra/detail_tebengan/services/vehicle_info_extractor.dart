class VehicleInfoExtractor {
  static Map<String, String> extractVehicleInfo(Map<String, dynamic> item) {
    final ride = Map<String, dynamic>.from(item['ride'] ?? {});
    final rideType = (item['type'] ?? '').toString().toLowerCase();
    final mitraVehicle = ride['kendaraan_mitra'] != null
        ? Map<String, dynamic>.from(ride['kendaraan_mitra'] as Map)
        : <String, dynamic>{};

    // Extract owner name
    String ownerName = _extractOwnerName(ride, item, mitraVehicle);

    // Extract transportation type
    String transportasi = _extractTransportationType(
        mitraVehicle, (ride['service_type'] ?? '').toString(), ride, rideType);

    // Extract plate number
    String plat = (mitraVehicle['plat_number'] ??
            mitraVehicle['plate_number'] ??
            mitraVehicle['license_plate'] ??
            '-')
        .toString();

    // Extract vehicle model
    String vehicleModel = (mitraVehicle['name'] ??
            mitraVehicle['vehicle_name'] ??
            mitraVehicle['model'] ??
            mitraVehicle['tipe'] ??
            '-')
        .toString();

    // Extract color
    String warna =
        (mitraVehicle['color'] ?? mitraVehicle['warna'] ?? '-').toString();

    // Extract seat count
    String kursi = _extractSeatCount(mitraVehicle, ride);

    return {
      'ownerName': ownerName,
      'transportasi': transportasi,
      'plat': plat,
      'vehicleModel': vehicleModel,
      'warna': warna,
      'kursi': kursi,
    };
  }

  static String _extractOwnerName(
    Map<String, dynamic> ride,
    Map<String, dynamic> item,
    Map<String, dynamic> mitraVehicle,
  ) {
    final candidates = <String?>[
      if (ride['mitra'] is Map) (ride['mitra']['name'] ?? '')?.toString(),
      if (item['mitra'] is Map) (item['mitra']['name'] ?? '')?.toString(),
      if (ride['owner'] is Map) (ride['owner']['name'] ?? '')?.toString(),
      if (item['owner'] is Map) (item['owner']['name'] ?? '')?.toString(),
      if (ride['user'] is Map) (ride['user']['name'] ?? '')?.toString(),
      if (item['user'] is Map) (item['user']['name'] ?? '')?.toString(),
      (item['mitra_name'] ?? '')?.toString(),
      (ride['mitra_name'] ?? '')?.toString(),
      (item['owner_name'] ?? '')?.toString(),
      (mitraVehicle['owner_name'] ?? '')?.toString(),
      (mitraVehicle['owner'] ?? '')?.toString(),
      (mitraVehicle['driver_name'] ?? '')?.toString(),
    ];

    for (final c in candidates) {
      if (c != null && c.toString().trim().isNotEmpty) {
        return c.toString().trim();
      }
    }
    return '-';
  }

  static String _extractTransportationType(
    Map<String, dynamic> vehicle,
    String serviceType,
    Map<String, dynamic> ride,
    String rideType,
  ) {
    // For titip barang, use transportation_type from ride
    if (rideType == 'titip') {
      final transportationType = (ride['transportation_type'] ?? '').toString();
      if (transportationType.isNotEmpty) {
        // Capitalize first letter
        return transportationType[0].toUpperCase() +
            transportationType.substring(1);
      }
    }

    final rawType = (vehicle['type'] ??
            vehicle['vehicle_type'] ??
            vehicle['transportation'] ??
            '')
        .toString()
        .toLowerCase();
    final sType = serviceType.toString().toLowerCase();

    if (rawType.contains('motor') || sType.contains('motor')) return 'Motor';
    if (rawType.contains('mobil') ||
        rawType.contains('car') ||
        sType.contains('mobil') ||
        sType.contains('car')) return 'Mobil';
    return 'Motor';
  }

  static String _extractSeatCount(
    Map<String, dynamic> mitraVehicle,
    Map<String, dynamic> ride,
  ) {
    // Check for jumlah_bagasi first (count of bagasi, used in titip barang and others)
    if ((ride['jumlah_bagasi'] ?? '').toString().isNotEmpty) {
      return ride['jumlah_bagasi'].toString();
    }

    if ((mitraVehicle['seat_count'] ?? '').toString().isNotEmpty) {
      return mitraVehicle['seat_count'].toString();
    } else if ((mitraVehicle['jumlah_kursi'] ?? '').toString().isNotEmpty) {
      return mitraVehicle['jumlah_kursi'].toString();
    } else if ((ride['seat_count'] ?? '').toString().isNotEmpty) {
      return ride['seat_count'].toString();
    } else if ((mitraVehicle['seats'] ?? '').toString().isNotEmpty) {
      return mitraVehicle['seats'].toString();
    }
    return '-';
  }
}
