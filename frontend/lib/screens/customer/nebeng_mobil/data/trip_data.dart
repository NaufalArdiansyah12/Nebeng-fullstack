import '../models/trip_model.dart';

class TripData {
  static List<TripModel> getAvailableTrips({
    required String from,
    required String to,
    required DateTime date,
  }) {
    // Dummy data - nanti bisa diganti dengan API call
    return [
      TripModel(
        id: '1',
        date: 'Minggu 28-07-2024',
        time: '09:00-13:00',
        departureLocation: from,
        departureAddress:
            'Patehan, Kecamatan Kraton, Kota Yogyakarta, Daerah Istimewa Yogyakarta 55133',
        arrivalLocation: to,
        arrivalAddress:
            'Jl. Jend. Sudirman No.296, Purwng, Sokanegara, Kec. Purwokerto Tim., Kabupaten Banyumas, Jawa Tengah 53116',
        price: 120000,
      ),
      TripModel(
        id: '2',
        date: 'Minggu 28-07-2024',
        time: '09:00-13:00',
        departureLocation: from,
        departureAddress:
            'Patehan, Kecamatan Kraton, Kota Yogyakarta, Daerah Istimewa Yogyakarta 55133',
        arrivalLocation: to,
        arrivalAddress:
            'Jl. Jend. Sudirman No.296, Purwng, Sokanegara, Kec. Purwokerto Tim., Kabupaten Banyumas, Jawa Tengah 53116',
        price: 120000,
      ),
      TripModel(
        id: '3',
        date: 'Minggu 28-07-2024',
        time: '09:00-13:00',
        departureLocation: from,
        departureAddress:
            'Patehan, Kecamatan Kraton, Kota Yogyakarta, Daerah Istimewa Yogyakarta 55133',
        arrivalLocation: to,
        arrivalAddress:
            'Jl. Jend. Sudirman No.296, Purwng, Sokanegara, Kec. Purwokerto Tim., Kabupaten Banyumas, Jawa Tengah 53116',
        price: 120000,
      ),
      TripModel(
        id: '4',
        date: 'Minggu 28-07-2024',
        time: '09:00-13:00',
        departureLocation: from,
        departureAddress:
            'Patehan, Kecamatan Kraton, Kota Yogyakarta, Daerah Istimewa Yogyakarta 55133',
        arrivalLocation: to,
        arrivalAddress:
            'Jl. Jend. Sudirman No.296, Purwng, Sokanegara, Kec. Purwokerto Tim., Kabupaten Banyumas, Jawa Tengah 53116',
        price: 120000,
      ),
    ];
  }
}
