import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api/api_config.dart';
import 'api/auth_service.dart';
import 'api/profile_service.dart';
import 'api/ride_service.dart';
import 'api/booking_service.dart';
import 'api/vehicle_service.dart';
import 'api/reward_service.dart';
import 'api/location_service.dart';
import 'api/rating_service.dart';
import 'api/verification_service.dart';
import 'api/credit_service.dart';
import 'api/reschedule_service.dart';
import 'payment_service.dart';

class ApiService {
  // Base URL configuration
  static String get baseUrl => ApiConfig.baseUrl;

  // ========== Auth Service Methods ==========
  static Future<Map<String, dynamic>> login(String email, String password) =>
      AuthService.login(email, password);

  static Future<bool> logout(String? token) => AuthService.logout(token);

  static Future<bool> checkPin({required String token}) =>
      AuthService.checkPin(token: token);

  static Future<Map<String, dynamic>> createPin({
    required String token,
    required String hashedPin,
  }) =>
      AuthService.createPin(token: token, hashedPin: hashedPin);

  static Future<bool> verifyPin({
    required String token,
    required String hashedPin,
  }) =>
      AuthService.verifyPin(token: token, hashedPin: hashedPin);

  // ========== Profile Service Methods ==========
  static Future<Map<String, dynamic>> getProfile({required String token}) =>
      ProfileService.getProfile(token: token);

  static Future<Map<String, dynamic>> getUserById(int userId, String token) =>
      ProfileService.getUserById(userId, token);

  static Future<Map<String, dynamic>> updateProfile({
    required String token,
    String? name,
    String? email,
    String? address,
    String? phone,
    String? gender,
    String? photoFilePath,
  }) =>
      ProfileService.updateProfile(
        token: token,
        name: name,
        email: email,
        address: address,
        phone: phone,
        gender: gender,
        photoFilePath: photoFilePath,
      );

  static Future<Map<String, dynamic>> uploadProfilePhoto({
    required String token,
    required String photoFilePath,
  }) =>
      ProfileService.uploadProfilePhoto(
        token: token,
        photoFilePath: photoFilePath,
      );

  static Future<Map<String, dynamic>> changePassword({
    required String token,
    required String oldPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) =>
      ProfileService.changePassword(
        token: token,
        oldPassword: oldPassword,
        newPassword: newPassword,
        newPasswordConfirmation: newPasswordConfirmation,
      );

  // ========== Ride Service Methods ==========
  static Future<List<Map<String, dynamic>>> fetchRides({
    int? originLocationId,
    int? destinationLocationId,
    String? date,
    String? rideType,
    int? userId,
  }) =>
      RideService.fetchRides(
        originLocationId: originLocationId,
        destinationLocationId: destinationLocationId,
        date: date,
        rideType: rideType,
        userId: userId,
      );

  static Future<List<Map<String, dynamic>>> fetchMitraHistory({
    required String token,
    String? status,
  }) =>
      RideService.fetchMitraHistory(token: token, status: status);

  static Future<Map<String, dynamic>> createRide({
    required String token,
    required int originLocationId,
    required int destinationLocationId,
    required String departureDate,
    required String departureTime,
    required String rideType,
    required String serviceType,
    required double price,
    int? kendaraanMitraId,
    int? bagasiCapacity,
    int? jumlahBagasi,
    String? vehicleName,
    String? vehiclePlate,
    String? vehicleBrand,
    String? vehicleType,
    String? vehicleColor,
    int? availableSeats,
    String? photoFilePath,
  }) =>
      RideService.createRide(
        token: token,
        originLocationId: originLocationId,
        destinationLocationId: destinationLocationId,
        departureDate: departureDate,
        departureTime: departureTime,
        rideType: rideType,
        serviceType: serviceType,
        price: price,
        kendaraanMitraId: kendaraanMitraId,
        bagasiCapacity: bagasiCapacity,
        jumlahBagasi: jumlahBagasi,
        vehicleName: vehicleName,
        vehiclePlate: vehiclePlate,
        vehicleBrand: vehicleBrand,
        vehicleType: vehicleType,
        vehicleColor: vehicleColor,
        availableSeats: availableSeats,
        photoFilePath: photoFilePath,
      );

  static Future<List<Map<String, dynamic>>> getRidePassengers(
          int rideId, String rideType) =>
      RideService.getRidePassengers(rideId, rideType);

  static Future<List<Map<String, dynamic>>> fetchAvailableRides(
          int bookingId, String bookingType,
          {String? date}) =>
      RideService.fetchAvailableRides(bookingId, bookingType, date: date);

  static Future<Map<String, dynamic>> startTrip({
    required int bookingId,
    required String token,
    String bookingType = 'motor',
  }) =>
      RideService.startTrip(
        bookingId: bookingId,
        token: token,
        bookingType: bookingType,
      );

  static Future<Map<String, dynamic>> completeTrip({
    required int bookingId,
    required String token,
    String bookingType = 'motor',
  }) =>
      RideService.completeTrip(
        bookingId: bookingId,
        token: token,
        bookingType: bookingType,
      );

  // ========== Booking Service Methods ==========
  static Future<Map<String, dynamic>> createBooking({
    required int rideId,
    required int userId,
    required int seats,
    required String bookingNumber,
    String? rideType,
    String? photoFilePath,
    String? weight,
    String? description,
    String? penerima,
    List<Map<String, dynamic>>? penumpang,
  }) =>
      BookingService.createBooking(
        rideId: rideId,
        userId: userId,
        seats: seats,
        bookingNumber: bookingNumber,
        rideType: rideType,
        photoFilePath: photoFilePath,
        weight: weight,
        description: description,
        penerima: penerima,
        penumpang: penumpang,
      );

  static Future<List<Map<String, dynamic>>> fetchBookings({
    required String token,
    String? type,
  }) =>
      BookingService.fetchBookings(token: token, type: type);

  static Future<Map<String, dynamic>> fetchBooking({
    required int bookingId,
    String? token,
  }) =>
      BookingService.fetchBooking(bookingId: bookingId, token: token);

  static Future<Map<String, dynamic>> updateBookingStatus({
    required int bookingId,
    required String status,
    required String token,
  }) =>
      BookingService.updateBookingStatus(
        bookingId: bookingId,
        status: status,
        token: token,
      );

  static Future<Map<String, dynamic>> cancelBooking(
          int bookingId, String reason) =>
      BookingService.cancelBooking(bookingId, reason);

  static Future<Map<String, dynamic>> getCancellationCount(int userId) =>
      BookingService.getCancellationCount(userId);

  static Future<Map<String, dynamic>> getBookingTracking({
    required int bookingId,
    required String token,
    String bookingType = 'motor',
  }) =>
      BookingService.getBookingTracking(
        bookingId: bookingId,
        token: token,
        bookingType: bookingType,
      );

  // ========== Vehicle Service Methods ==========
  static Future<List<Map<String, dynamic>>> fetchVehicles({
    required String token,
  }) =>
      VehicleService.fetchVehicles(token: token);

  static Future<Map<String, dynamic>> createVehicle({
    required String token,
    required String vehicleType,
    required String name,
    required String plateNumber,
    required String brand,
    required String model,
    required String color,
    int? year,
    required int seats,
  }) =>
      VehicleService.createVehicle(
        token: token,
        vehicleType: vehicleType,
        name: name,
        plateNumber: plateNumber,
        brand: brand,
        model: model,
        color: color,
        year: year,
        seats: seats,
      );

  static Future<bool> deleteVehicle({
    required String token,
    required int vehicleId,
    required String deletionReason,
  }) =>
      VehicleService.deleteVehicle(
        token: token,
        vehicleId: vehicleId,
        deletionReason: deletionReason,
      );

  // ========== Reward Service Methods ==========
  static Future<List<Map<String, dynamic>>> fetchRewards() =>
      RewardService.fetchRewards();

  static Future<Map<String, dynamic>> redeemReward({
    required String token,
    required int rewardId,
    Map<String, dynamic>? metadata,
  }) =>
      RewardService.redeemReward(
        token: token,
        rewardId: rewardId,
        metadata: metadata,
      );

  static Future<List<Map<String, dynamic>>> fetchMyRedemptions({
    required String token,
  }) =>
      RewardService.fetchMyRedemptions(token: token);

  // ========== Location Service Methods ==========
  static Future<List<Map<String, dynamic>>> fetchLocations() =>
      LocationService.fetchLocations();

  static Future<bool> reportMitraLocation({
    required String token,
    required double lat,
    required double lng,
    DateTime? at,
  }) =>
      LocationService.reportMitraLocation(
        token: token,
        lat: lat,
        lng: lng,
        at: at,
      );

  static Future<bool> updateBookingLocation({
    required int bookingId,
    required String token,
    required double lat,
    required double lng,
    DateTime? timestamp,
    double? accuracy,
    double? speed,
    String bookingType = 'motor',
  }) =>
      LocationService.updateBookingLocation(
        bookingId: bookingId,
        token: token,
        lat: lat,
        lng: lng,
        timestamp: timestamp,
        accuracy: accuracy,
        speed: speed,
        bookingType: bookingType,
      );

  static Future<Map<String, dynamic>> fetchBookingLocation({
    required int bookingId,
    String? token,
  }) =>
      LocationService.fetchBookingLocation(
        bookingId: bookingId,
        token: token,
      );

  // ========== Rating Service Methods ==========
  static Future<Map<String, dynamic>> submitRating({
    required String token,
    required int bookingId,
    required String bookingType,
    required int driverId,
    required int rating,
    String? review,
  }) =>
      RatingService.submitRating(
        token: token,
        bookingId: bookingId,
        bookingType: bookingType,
        driverId: driverId,
        rating: rating,
        review: review,
      );

  static Future<Map<String, dynamic>?> getRating({
    required int bookingId,
    required String bookingType,
  }) =>
      RatingService.getRating(
        bookingId: bookingId,
        bookingType: bookingType,
      );

  static Future<Map<String, dynamic>> getDriverRatings({
    required int driverId,
  }) =>
      RatingService.getDriverRatings(driverId: driverId);

  // ========== Verification Service Methods ==========
  static Future<Map<String, dynamic>> submitKtpVerification({
    required String token,
    required String ktpNumber,
    required String ktpName,
    required String ktpBirthDate,
    required String ktpPhotoPath,
  }) =>
      VerificationService.submitKtpVerification(
        token: token,
        ktpNumber: ktpNumber,
        ktpName: ktpName,
        ktpBirthDate: ktpBirthDate,
        ktpPhotoPath: ktpPhotoPath,
      );

  // ========== Credit Service Methods ==========
  static Future<Map<String, dynamic>> getCreditScore({required String token}) =>
      CreditService.getCreditScore(token: token);

  static Future<Map<String, dynamic>> submitSimVerification({
    required String token,
    required String simNumber,
    required String simType,
    required String simExpiryDate,
    required String simPhotoPath,
  }) =>
      VerificationService.submitSimVerification(
        token: token,
        simNumber: simNumber,
        simType: simType,
        simExpiryDate: simExpiryDate,
        simPhotoPath: simPhotoPath,
      );

  static Future<Map<String, dynamic>> submitSkckVerification({
    required String token,
    required String skckNumber,
    required String skckName,
    required String skckExpiryDate,
    required String skckPhotoPath,
  }) =>
      VerificationService.submitSkckVerification(
        token: token,
        skckNumber: skckNumber,
        skckName: skckName,
        skckExpiryDate: skckExpiryDate,
        skckPhotoPath: skckPhotoPath,
      );

  static Future<Map<String, dynamic>> submitBankVerification({
    required String token,
    required String bankAccountNumber,
    required String bankAccountName,
    required String bankName,
    required String bankPhotoPath,
  }) =>
      VerificationService.submitBankVerification(
        token: token,
        bankAccountNumber: bankAccountNumber,
        bankAccountName: bankAccountName,
        bankName: bankName,
        bankPhotoPath: bankPhotoPath,
      );

  static Future<Map<String, dynamic>> linkMitraVerifications(String token) =>
      VerificationService.linkMitraVerifications(token);

  static Future<Map<String, dynamic>> getMitraVerificationStatus(
          String token) =>
      VerificationService.getMitraVerificationStatus(token);

  // Helper methods for uploading documents with File objects
  static Future<Map<String, dynamic>> uploadKtp({
    required String token,
    required String ktpNumber,
    required String fullName,
    required String dateOfBirth,
    required dynamic ktpPhoto, // Can be File or null
  }) async {
    if (ktpPhoto == null) {
      throw Exception('KTP photo is required');
    }
    return submitKtpVerification(
      token: token,
      ktpNumber: ktpNumber,
      ktpName: fullName,
      ktpBirthDate: dateOfBirth,
      ktpPhotoPath: ktpPhoto.path,
    );
  }

  static Future<Map<String, dynamic>> updateKtp({
    required String token,
    required String ktpNumber,
    required String fullName,
    required String dateOfBirth,
    dynamic ktpPhoto,
  }) async {
    return VerificationService.updateKtpVerification(
      token: token,
      ktpNumber: ktpNumber,
      ktpName: fullName,
      ktpBirthDate: dateOfBirth,
      ktpPhotoPath: ktpPhoto is String
          ? ktpPhoto
          : (ktpPhoto != null ? ktpPhoto.path : null),
    );
  }

  static Future<Map<String, dynamic>> uploadSim({
    required String token,
    required String simNumber,
    required String expiryDate,
    required dynamic simPhoto, // Can be File or null
  }) async {
    if (simPhoto == null) {
      throw Exception('SIM photo is required');
    }
    return submitSimVerification(
      token: token,
      simNumber: simNumber,
      simType: 'C', // Default to C, can be parameterized if needed
      simExpiryDate: expiryDate,
      simPhotoPath: simPhoto.path,
    );
  }

  static Future<Map<String, dynamic>> updateSim({
    required String token,
    required String simNumber,
    required String expiryDate,
    required String simType,
    dynamic simPhoto,
  }) async {
    return VerificationService.updateSimVerification(
      token: token,
      simNumber: simNumber,
      simType: simType,
      simExpiryDate: expiryDate,
      simPhotoPath: simPhoto is String
          ? simPhoto
          : (simPhoto != null ? simPhoto.path : null),
    );
  }

  static Future<Map<String, dynamic>> uploadSkck({
    required String token,
    required dynamic skckPhoto, // Can be File or null
  }) async {
    if (skckPhoto == null) {
      throw Exception('SKCK photo is required');
    }
    // Generate default values for required fields
    final now = DateTime.now();
    final expiryDate = DateTime(now.year + 1, now.month, now.day);
    return submitSkckVerification(
      token: token,
      skckNumber: 'SKCK-${DateTime.now().millisecondsSinceEpoch}',
      skckName: 'SKCK',
      skckExpiryDate: expiryDate.toString().split(' ')[0],
      skckPhotoPath: skckPhoto.path,
    );
  }

  static Future<Map<String, dynamic>> updateSkck({
    required String token,
    required String skckNumber,
    required String skckName,
    required String skckExpiryDate,
    dynamic skckPhoto,
  }) async {
    return VerificationService.updateSkckVerification(
      token: token,
      skckNumber: skckNumber,
      skckName: skckName,
      skckExpiryDate: skckExpiryDate,
      skckPhotoPath: skckPhoto is String
          ? skckPhoto
          : (skckPhoto != null ? skckPhoto.path : null),
    );
  }

  static Future<Map<String, dynamic>> uploadBankAccount({
    required String token,
    required String accountNumber,
    required String accountName,
    required String bankName,
    required dynamic bankPhoto, // Can be File or null
  }) async {
    if (bankPhoto == null) {
      throw Exception('Bank account photo is required');
    }
    return submitBankVerification(
      token: token,
      bankAccountNumber: accountNumber,
      bankAccountName: accountName,
      bankName: bankName,
      bankPhotoPath: bankPhoto.path,
    );
  }

  static Future<Map<String, dynamic>> updateBankAccount({
    required String token,
    required String accountNumber,
    required String accountName,
    required String bankName,
    dynamic bankPhoto, // Can be File, String, or null
  }) async {
    return VerificationService.updateBankVerification(
      token: token,
      bankAccountNumber: accountNumber,
      bankAccountName: accountName,
      bankName: bankName,
      bankPhotoPath: bankPhoto is String
          ? bankPhoto
          : (bankPhoto != null ? bankPhoto.path : null),
    );
  }

  // ========== Reschedule Service Methods ==========
  static Future<Map<String, dynamic>> createReschedule({
    required String token,
    required int bookingId,
    required String bookingType,
    required String requestedTargetType,
    required int requestedTargetId,
    String? reason,
    String? barangImagePath,
  }) =>
      RescheduleService.createReschedule(
        token: token,
        bookingId: bookingId,
        bookingType: bookingType,
        requestedTargetType: requestedTargetType,
        requestedTargetId: requestedTargetId,
        reason: reason,
        barangImagePath: barangImagePath,
      );

  // ========== Payment Service Methods ==========
  // Note: These are wrapper methods for payment_service.dart (non-static class)
  static Future<Map<String, dynamic>> createPayment({
    required int rideId,
    required int userId,
    required String bookingNumber,
    int? bookingId,
    required String paymentMethod,
    required double amount,
    double? adminFee,
  }) async {
    // Use non-static PaymentService
    final service = PaymentService();
    return await service.createPayment(
      rideId: rideId,
      userId: userId,
      bookingNumber: bookingNumber,
      bookingId: bookingId,
      paymentMethod: paymentMethod,
      amount: amount,
      adminFee: adminFee,
    );
  }

  static Future<Map<String, dynamic>> confirmReschedulePayment({
    required int requestId,
    required String paymentTxnId,
    List<Map<String, dynamic>>? passengers,
  }) async {
    final uri = Uri.parse(
        '${ApiConfig.baseUrl}/api/v1/reschedule/$requestId/confirm-payment');

    final body = <String, dynamic>{
      'payment_txn_id': paymentTxnId,
    };

    if (passengers != null && passengers.isNotEmpty) {
      body['passengers'] = passengers;
    }

    final resp = await http.post(uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json'
        },
        body: jsonEncode(body));

    final decoded = (resp.body.isNotEmpty) ? jsonDecode(resp.body) : {};
    if (resp.statusCode == 200 || resp.statusCode == 201) {
      return Map<String, dynamic>.from(decoded as Map);
    }
    throw Exception(decoded['message'] ?? 'Failed to confirm reschedule');
  }

  static Future<List<Map<String, dynamic>>> fetchTransactionHistory({
    required String token,
    String? status,
  }) async {
    final queryParams = status != null ? '?status=$status' : '';
    final uri = Uri.parse(
        '${ApiConfig.baseUrl}/api/v1/transactions/history$queryParams');

    final resp = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (resp.statusCode == 200) {
      final body = jsonDecode(resp.body);
      if (body is Map && body['success'] == true && body['data'] is List) {
        return List<Map<String, dynamic>>.from(body['data']);
      }
      throw Exception('Unexpected response format');
    }
    throw Exception('Failed to fetch transaction history: ${resp.statusCode}');
  }

  static Future<Map<String, dynamic>> checkRefundEligibility(
    int bookingId,
    String bookingType,
  ) async {
    final uri = Uri.parse(
        '${ApiConfig.baseUrl}/api/v1/bookings/$bookingId/refund-eligibility?type=$bookingType');

    final resp = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
      },
    );

    if (resp.statusCode == 200) {
      final body = jsonDecode(resp.body);
      if (body is Map && body['success'] == true) {
        return Map<String, dynamic>.from(body['data'] ?? {});
      }
      throw Exception(body['message'] ?? 'Failed to check refund eligibility');
    }
    throw Exception('Failed to check refund eligibility: ${resp.statusCode}');
  }

  static Future<Map<String, dynamic>> submitRefund({
    required int userId,
    required int bookingId,
    required String bookingType,
    required String refundReason,
    required String bankName,
    required String accountNumber,
    required String accountHolderName,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/refunds');

    final resp = await http.post(
      uri,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'user_id': userId,
        'booking_id': bookingId,
        'booking_type': bookingType,
        'refund_reason': refundReason,
        'bank_name': bankName,
        'account_number': accountNumber,
        'account_holder_name': accountHolderName,
      }),
    );

    if (resp.statusCode == 201 || resp.statusCode == 200) {
      final body = jsonDecode(resp.body);
      if (body is Map && body['success'] == true) {
        return Map<String, dynamic>.from(body['data'] ?? {});
      }
      throw Exception(body['message'] ?? 'Failed to submit refund');
    }
    throw Exception('Failed to submit refund: ${resp.statusCode}');
  }

  static Future<List<Map<String, dynamic>>> getRefundHistory(int userId) async {
    final uri =
        Uri.parse('${ApiConfig.baseUrl}/api/v1/refunds?user_id=$userId');

    final resp = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
      },
    );

    if (resp.statusCode == 200) {
      final body = jsonDecode(resp.body);
      if (body is Map && body['success'] == true && body['data'] is List) {
        return List<Map<String, dynamic>>.from(body['data']);
      }
      return [];
    }
    return [];
  }

  static Future<Map<String, dynamic>> getRefundDetail(int refundId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/refunds/$refundId');

    final resp = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
      },
    );

    if (resp.statusCode == 200) {
      final body = jsonDecode(resp.body);
      if (body is Map && body['success'] == true) {
        return Map<String, dynamic>.from(body['data'] ?? {});
      }
      throw Exception(body['message'] ?? 'Failed to get refund detail');
    }
    throw Exception('Failed to get refund detail: ${resp.statusCode}');
  }
}

// Note: For direct PaymentService usage (non-static methods):
// import 'package:frontend/services/payment_service.dart';
