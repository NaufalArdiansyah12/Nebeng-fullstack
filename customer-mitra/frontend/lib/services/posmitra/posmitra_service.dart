import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../api_service.dart';

class PosMitraService {
  static String get baseUrl => ApiService.baseUrl;

  // ==================== AUTHENTICATION ====================

  /// Get authorization header with bearer token
  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('api_token');

    if (token == null || token.isEmpty) {
      throw Exception('Token tidak ditemukan');
    }

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ==================== BERANDA / DASHBOARD ====================

  /// Get pos mitra balance
  static Future<double> getBalance() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/posmitra/beranda'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return (data['data']['balance'] ?? 0).toDouble();
        }
        throw Exception(data['message'] ?? 'Gagal mengambil saldo');
      } else if (response.statusCode == 401) {
        throw Exception('Token tidak valid atau sudah kadaluarsa');
      } else {
        throw Exception('Gagal mengambil saldo: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error saat mengambil saldo: $e');
    }
  }

  /// Get dashboard statistics
  static Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/posmitra/dashboard/stats'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'];
        }
        throw Exception(data['message'] ?? 'Gagal mengambil statistik');
      }
      throw Exception('Gagal mengambil statistik: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error saat mengambil statistik: $e');
    }
  }

  // ==================== PROFILE ====================

  /// Get pos mitra profile
  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/pos-mitra/profile'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data']['user'];
        }
        throw Exception(data['message'] ?? 'Gagal mengambil profil');
      } else if (response.statusCode == 401) {
        throw Exception('Token tidak valid atau sudah kadaluarsa');
      }
      throw Exception('Gagal mengambil profil: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error saat mengambil profil: $e');
    }
  }

  /// Update pos mitra profile
  static Future<Map<String, dynamic>> updateProfile({
    String? email,
    String? photoFilePath,
    String? name,
    String? phone,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');

      if (token == null || token.isEmpty) {
        throw Exception('Token tidak ditemukan');
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/pos-mitra/profile'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      if (email != null && email.isNotEmpty) {
        request.fields['email'] = email;
      }

      if (name != null && name.isNotEmpty) {
        request.fields['name'] = name;
      }

      if (phone != null && phone.isNotEmpty) {
        request.fields['phone'] = phone;
      }

      if (photoFilePath != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'profile_photo',
            photoFilePath,
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data;
        }
        throw Exception(data['message'] ?? 'Gagal memperbarui profil');
      }
      throw Exception('Gagal memperbarui profil: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error saat memperbarui profil: $e');
    }
  }

  // ==================== ACTIVITIES / TEBENGAN ====================

  /// Get upcoming rides (tebengan akan datang) berdasarkan lokasi pos mitra
  static Future<List<Map<String, dynamic>>> getUpcomingRides() async {
    try {
      final headers = await _getHeaders();
      final url = '$baseUrl/api/v1/posmitra/tebengan-akan-datang';

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['data'] ?? []);
        }
        throw Exception(data['message'] ?? 'Gagal mengambil data tebengan');
      } else if (response.statusCode == 401) {
        throw Exception('Token tidak valid atau sudah kadaluarsa');
      }
      throw Exception('Gagal mengambil data tebengan: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error saat mengambil data tebengan: $e');
    }
  }

  /// Get upcoming rides/activities
  static Future<List<Map<String, dynamic>>> getUpcomingActivities({
    String? status, // 'semua', 'proses', 'kosong'
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final headers = await _getHeaders();
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (status != null && status != 'semua') {
        queryParams['status'] = status;
      }

      final uri = Uri.parse('$baseUrl/api/v1/posmitra/activities')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(
              data['data']['activities'] ?? []);
        }
        throw Exception(data['message'] ?? 'Gagal mengambil aktivitas');
      }
      throw Exception('Gagal mengambil aktivitas: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error saat mengambil aktivitas: $e');
    }
  }

  /// Get statistics (completed rides by location)
  static Future<Map<String, dynamic>> getStatistics() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/posmitra/statistics'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'] as Map<String, dynamic>;
        }
        throw Exception(data['message'] ?? 'Gagal mengambil statistik');
      } else if (response.statusCode == 401) {
        throw Exception('Token tidak valid atau sudah kadaluarsa');
      }
      throw Exception('Gagal mengambil statistik: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error saat mengambil statistik: $e');
    }
  }

  /// Get activity detail
  static Future<Map<String, dynamic>> getActivityDetail(int activityId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/posmitra/activities/$activityId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data']['activity'];
        }
        throw Exception(data['message'] ?? 'Gagal mengambil detail aktivitas');
      }
      throw Exception('Gagal mengambil detail: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error saat mengambil detail: $e');
    }
  }

  // ==================== QR CODE SCANNING ====================

  /// Verify QR code and complete ride
  static Future<Map<String, dynamic>> verifyQRCode(String qrData) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/posmitra/qr/verify'),
        headers: headers,
        body: json.encode({'qr_data': qrData}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'];
        }
        throw Exception(data['message'] ?? 'QR Code tidak valid');
      } else if (response.statusCode == 400) {
        final data = json.decode(response.body);
        throw Exception(data['message'] ?? 'QR Code tidak valid');
      }
      throw Exception('Gagal memverifikasi QR Code: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error saat memverifikasi QR Code: $e');
    }
  }

  /// Complete ride after QR scan
  static Future<Map<String, dynamic>> completeRide({
    required int bookingId,
    required String qrData,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/posmitra/rides/complete'),
        headers: headers,
        body: json.encode({
          'booking_id': bookingId,
          'qr_data': qrData,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'];
        }
        throw Exception(data['message'] ?? 'Gagal menyelesaikan tebengan');
      }
      throw Exception('Gagal menyelesaikan tebengan: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error saat menyelesaikan tebengan: $e');
    }
  }

  // ==================== WITHDRAWAL ====================

  /// Get withdrawal history
  static Future<List<Map<String, dynamic>>> getWithdrawalHistory({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/api/v1/posmitra/withdrawals')
          .replace(queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
      });

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(
              data['data']['withdrawals'] ?? []);
        }
        throw Exception(data['message'] ?? 'Gagal mengambil riwayat pencairan');
      }
      throw Exception('Gagal mengambil riwayat: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error saat mengambil riwayat: $e');
    }
  }

  /// Get withdrawal detail
  static Future<Map<String, dynamic>> getWithdrawalDetail(
      int withdrawalId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/posmitra/withdrawals/$withdrawalId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data']['withdrawal'];
        }
        throw Exception(data['message'] ?? 'Gagal mengambil detail pencairan');
      }
      throw Exception('Gagal mengambil detail: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error saat mengambil detail: $e');
    }
  }

  /// Request withdrawal
  static Future<Map<String, dynamic>> requestWithdrawal({
    required double amount,
    required String bankAccount,
    required String pin,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/posmitra/withdrawals'),
        headers: headers,
        body: json.encode({
          'amount': amount,
          'bank_account': bankAccount,
          'pin': pin,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'];
        }
        throw Exception(data['message'] ?? 'Gagal mengajukan pencairan');
      } else if (response.statusCode == 400) {
        final data = json.decode(response.body);
        throw Exception(data['message'] ?? 'Data tidak valid');
      }
      throw Exception('Gagal mengajukan pencairan: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error saat mengajukan pencairan: $e');
    }
  }

  // ==================== NOTIFICATIONS ====================

  /// Get notifications
  static Future<List<Map<String, dynamic>>> getNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/api/v1/posmitra/notifications')
          .replace(queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
      });

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(
              data['data']['notifications'] ?? []);
        }
        throw Exception(data['message'] ?? 'Gagal mengambil notifikasi');
      }
      throw Exception('Gagal mengambil notifikasi: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error saat mengambil notifikasi: $e');
    }
  }

  /// Mark notification as read
  static Future<void> markNotificationAsRead(int notificationId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(
            '$baseUrl/api/v1/posmitra/notifications/$notificationId/read'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Gagal menandai notifikasi: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error saat menandai notifikasi: $e');
    }
  }

  /// Mark all notifications as read
  static Future<void> markAllNotificationsAsRead() async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/posmitra/notifications/read-all'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Gagal menandai semua notifikasi: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error saat menandai semua notifikasi: $e');
    }
  }

  // ==================== EARNINGS / PENDAPATAN ====================

  /// Get earnings summary
  static Future<Map<String, dynamic>> getEarningsSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final headers = await _getHeaders();
      final queryParams = <String, String>{};

      if (startDate != null) {
        queryParams['start_date'] = startDate.toIso8601String().split('T')[0];
      }
      if (endDate != null) {
        queryParams['end_date'] = endDate.toIso8601String().split('T')[0];
      }

      final uri = Uri.parse('$baseUrl/api/v1/posmitra/earnings/summary')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'];
        }
        throw Exception(
            data['message'] ?? 'Gagal mengambil ringkasan pendapatan');
      }
      throw Exception('Gagal mengambil ringkasan: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error saat mengambil ringkasan: $e');
    }
  }

  /// Get detailed earnings history
  static Future<List<Map<String, dynamic>>> getEarningsHistory({
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final headers = await _getHeaders();
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (startDate != null) {
        queryParams['start_date'] = startDate.toIso8601String().split('T')[0];
      }
      if (endDate != null) {
        queryParams['end_date'] = endDate.toIso8601String().split('T')[0];
      }

      final uri = Uri.parse('$baseUrl/api/v1/posmitra/earnings/history')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(
              data['data']['earnings'] ?? []);
        }
        throw Exception(
            data['message'] ?? 'Gagal mengambil riwayat pendapatan');
      }
      throw Exception('Gagal mengambil riwayat: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error saat mengambil riwayat: $e');
    }
  }

  // ==================== STATISTICS ====================

  /// Get daily statistics
  static Future<Map<String, dynamic>> getDailyStats(DateTime date) async {
    try {
      final headers = await _getHeaders();
      final dateStr = date.toIso8601String().split('T')[0];
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/posmitra/stats/daily?date=$dateStr'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'];
        }
        throw Exception(data['message'] ?? 'Gagal mengambil statistik harian');
      }
      throw Exception('Gagal mengambil statistik: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error saat mengambil statistik: $e');
    }
  }

  /// Get monthly statistics
  static Future<Map<String, dynamic>> getMonthlyStats(
      int year, int month) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(
            '$baseUrl/api/v1/posmitra/stats/monthly?year=$year&month=$month'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'];
        }
        throw Exception(data['message'] ?? 'Gagal mengambil statistik bulanan');
      }
      throw Exception('Gagal mengambil statistik: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error saat mengambil statistik: $e');
    }
  }

  // ==================== HELP / BANTUAN ====================

  /// Get help articles
  static Future<List<Map<String, dynamic>>> getHelpArticles() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/posmitra/help/articles'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(
              data['data']['articles'] ?? []);
        }
        throw Exception(data['message'] ?? 'Gagal mengambil artikel bantuan');
      }
      throw Exception('Gagal mengambil artikel: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error saat mengambil artikel: $e');
    }
  }

  /// Get help article detail
  static Future<Map<String, dynamic>> getHelpArticleDetail(
      int articleId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/posmitra/help/articles/$articleId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data']['article'];
        }
        throw Exception(data['message'] ?? 'Gagal mengambil detail artikel');
      }
      throw Exception('Gagal mengambil detail: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error saat mengambil detail: $e');
    }
  }

  /// Submit help request / feedback
  static Future<void> submitHelpRequest({
    required String subject,
    required String message,
    File? attachment,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');

      if (token == null || token.isEmpty) {
        throw Exception('Token tidak ditemukan');
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/v1/posmitra/help/request'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      request.fields['subject'] = subject;
      request.fields['message'] = message;

      if (attachment != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'attachment',
            attachment.path,
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(
            'Gagal mengirim permintaan bantuan: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error saat mengirim permintaan bantuan: $e');
    }
  }
}
