// import 'dart:convert';
// import 'dart:io';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import '../api_service.dart';

// class PosMitraService {
//   static String get baseUrl => ApiService.baseUrl;

//   // ==================== AUTHENTICATION ====================

//   /// Get authorization header with bearer token
//   static Future<Map<String, String>> _getHeaders() async {
//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString('api_token');

//     if (token == null || token.isEmpty) {
//       throw Exception('Token tidak ditemukan');
//     }

//     return {
//       'Content-Type': 'application/json',
//       'Accept': 'application/json',
//       'Authorization': 'Bearer $token',
//     };
//   }

//   // ==================== BERANDA / DASHBOARD ====================

//   /// Get pos mitra balance
// static Future<double> getBalance() async {
//   final headers = await _getHeaders();
//   final response = await http.get(
//     Uri.parse('$baseUrl/api/v1/posmitra/beranda'),
//     headers: headers,
//   );

//   if (response.statusCode == 200) {
//     final data = json.decode(response.body);
//     if (data['success'] == true) {
//       final balance = data['data']['balance'];
      
//       // ✅ Parse balance ke double
//       return double.tryParse(balance.toString()) ?? 0.0;
//     }
//     throw Exception(data['message'] ?? 'Gagal mengambil saldo');
//   }
//   throw Exception('Gagal mengambil saldo: ${response.statusCode}');
// }


//   /// Get dashboard statistics
//   static Future<Map<String, dynamic>> getDashboardStats() async {
//     try {
//       final headers = await _getHeaders();
//       final response = await http.get(
//         Uri.parse('$baseUrl/api/v1/posmitra/dashboard/stats'),
//         headers: headers,
//       );

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         if (data['success'] == true) {
//           return data['data'];
//         }
//         throw Exception(data['message'] ?? 'Gagal mengambil statistik');
//       }
//       throw Exception('Gagal mengambil statistik: ${response.statusCode}');
//     } catch (e) {
//       throw Exception('Error saat mengambil statistik: $e');
//     }
//   }




//   // ==================== ACTIVITIES / TEBENGAN ====================

//   /// Get upcoming rides (tebengan akan datang) berdasarkan lokasi pos mitra
//   static Future<List<Map<String, dynamic>>> getUpcomingRides() async {
//     try {
//       final headers = await _getHeaders();
//       final url = '$baseUrl/api/v1/posmitra/tebengan-akan-datang';

//       final response = await http.get(
//         Uri.parse(url),
//         headers: headers,
//       );

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         if (data['success'] == true) {
//           return List<Map<String, dynamic>>.from(data['data'] ?? []);
//         }
//         throw Exception(data['message'] ?? 'Gagal mengambil data tebengan');
//       } else if (response.statusCode == 401) {
//         throw Exception('Token tidak valid atau sudah kadaluarsa');
//       }
//       throw Exception('Gagal mengambil data tebengan: ${response.statusCode}');
//     } catch (e) {
//       throw Exception('Error saat mengambil data tebengan: $e');
//     }
//   }

//   /// Get upcoming rides/activities
//   static Future<List<Map<String, dynamic>>> getUpcomingActivities({
//     String? status, // 'semua', 'proses', 'kosong'
//     int page = 1,
//     int limit = 10,
//   }) async {
//     try {
//       final headers = await _getHeaders();
//       final queryParams = {
//         'page': page.toString(),
//         'limit': limit.toString(),
//       };

//       if (status != null && status != 'semua') {
//         queryParams['status'] = status;
//       }

//       final uri = Uri.parse('$baseUrl/api/v1/posmitra/activities')
//           .replace(queryParameters: queryParams);

//       final response = await http.get(uri, headers: headers);

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         if (data['success'] == true) {
//           return List<Map<String, dynamic>>.from(
//               data['data']['activities'] ?? []);
//         }
//         throw Exception(data['message'] ?? 'Gagal mengambil aktivitas');
//       }
//       throw Exception('Gagal mengambil aktivitas: ${response.statusCode}');
//     } catch (e) {
//       throw Exception('Error saat mengambil aktivitas: $e');
//     }
//   }

//   /// Get statistics (completed rides by location)
//   static Future<Map<String, dynamic>> getStatistics() async {
//     try {
//       final headers = await _getHeaders();
//       final response = await http.get(
//         Uri.parse('$baseUrl/api/v1/posmitra/statistics'),
//         headers: headers,
//       );

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         if (data['success'] == true) {
//           return data['data'] as Map<String, dynamic>;
//         }
//         throw Exception(data['message'] ?? 'Gagal mengambil statistik');
//       } else if (response.statusCode == 401) {
//         throw Exception('Token tidak valid atau sudah kadaluarsa');
//       }
//       throw Exception('Gagal mengambil statistik: ${response.statusCode}');
//     } catch (e) {
//       throw Exception('Error saat mengambil statistik: $e');
//     }
//   }

//   /// Get activity detail
//   static Future<Map<String, dynamic>> getActivityDetail(int activityId) async {
//     try {
//       final headers = await _getHeaders();
//       final response = await http.get(
//         Uri.parse('$baseUrl/api/v1/posmitra/activities/$activityId'),
//         headers: headers,
//       );

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         if (data['success'] == true) {
//           return data['data']['activity'];
//         }
//         throw Exception(data['message'] ?? 'Gagal mengambil detail aktivitas');
//       }
//       throw Exception('Gagal mengambil detail: ${response.statusCode}');
//     } catch (e) {
//       throw Exception('Error saat mengambil detail: $e');
//     }
//   }



//   // ==================== WITHDRAWAL ====================

//   /// Withdraw Balance - Penarikan Saldo
//   /// 
//   /// Method untuk melakukan penarikan saldo dengan verifikasi PIN
//   /// 
//   /// Parameters:
//   /// - [token]: API token untuk autentikasi
//   /// - [amount]: Jumlah uang yang akan ditarik
//   /// - [bankName]: Nama bank tujuan
//   /// - [accountNumber]: Nomor rekening tujuan
//   /// - [pin]: PIN verifikasi pengguna (6 digit)
//   /// 
//   /// Returns:
//   /// Map dengan struktur:
//   /// {
//   ///   'success': bool,
//   ///   'message': String,
//   ///   'data': dynamic (optional)
//   /// }

//   /// Get withdrawal history
//   static Future<List<Map<String, dynamic>>> getWithdrawalHistory({
//     int page = 1,
//     int limit = 10,
//   }) async {
//     try {
//       final headers = await _getHeaders();
//       final uri = Uri.parse('$baseUrl/api/v1/posmitra/withdraw/history')
//           .replace(queryParameters: {
//         'page': page.toString(),
//         'limit': limit.toString(),
//       });

//       final response = await http.get(uri, headers: headers);

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         if (data['success'] == true) {
//           return List<Map<String, dynamic>>.from(
//               data['data']['withdrawals'] ?? []);
//         }
//         throw Exception(data['message'] ?? 'Gagal mengambil riwayat pencairan');
//       }
//       throw Exception('Gagal mengambil riwayat: ${response.statusCode}');
//     } catch (e) {
//       throw Exception('Error saat mengambil riwayat: $e');
//     }
//   }

//   /// Get withdrawal detail
//   static Future<Map<String, dynamic>> getWithdrawalDetail(
//       int withdrawalId) async {
//     try {
//       final headers = await _getHeaders();
//       final response = await http.get(
//         Uri.parse('$baseUrl/api/v1/posmitra/withdraw/$withdrawalId'),
//         headers: headers,
//       );

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         if (data['success'] == true) {
//           return data['data']['withdrawal'];
//         }
//         throw Exception(data['message'] ?? 'Gagal mengambil detail pencairan');
//       }
//       throw Exception('Gagal mengambil detail: ${response.statusCode}');
//     } catch (e) {
//       throw Exception('Error saat mengambil detail: $e');
//     }
//   }

//   /// Request withdrawal
//   // ==================== NOTIFICATIONS ====================

//   /// Get notifications
//   static Future<List<Map<String, dynamic>>> getNotifications({
//     int page = 1,
//     int limit = 20,
//   }) async {
//     try {
//       final headers = await _getHeaders();
//       final uri = Uri.parse('$baseUrl/api/v1/posmitra/notifications')
//           .replace(queryParameters: {
//         'page': page.toString(),
//         'limit': limit.toString(),
//       });

//       final response = await http.get(uri, headers: headers);

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         if (data['success'] == true) {
//           return List<Map<String, dynamic>>.from(
//               data['data']['notifications'] ?? []);
//         }
//         throw Exception(data['message'] ?? 'Gagal mengambil notifikasi');
//       }
//       throw Exception('Gagal mengambil notifikasi: ${response.statusCode}');
//     } catch (e) {
//       throw Exception('Error saat mengambil notifikasi: $e');
//     }
//   }

//   /// Mark notification as read
//   static Future<void> markNotificationAsRead(int notificationId) async {
//     try {
//       final headers = await _getHeaders();
//       final response = await http.post(
//         Uri.parse(
//             '$baseUrl/api/v1/posmitra/notifications/$notificationId/read'),
//         headers: headers,
//       );

//       if (response.statusCode != 200) {
//         throw Exception('Gagal menandai notifikasi: ${response.statusCode}');
//       }
//     } catch (e) {
//       throw Exception('Error saat menandai notifikasi: $e');
//     }
//   }

//   /// Mark all notifications as read
//   static Future<void> markAllNotificationsAsRead() async {
//     try {
//       final headers = await _getHeaders();
//       final response = await http.post(
//         Uri.parse('$baseUrl/api/v1/posmitra/notifications/read-all'),
//         headers: headers,
//       );

//       if (response.statusCode != 200) {
//         throw Exception(
//             'Gagal menandai semua notifikasi: ${response.statusCode}');
//       }
//     } catch (e) {
//       throw Exception('Error saat menandai semua notifikasi: $e');
//     }
//   }

//   // ==================== EARNINGS / PENDAPATAN ====================

//   /// Get earnings summary
//   static Future<Map<String, dynamic>> getEarningsSummary({
//     DateTime? startDate,
//     DateTime? endDate,
//   }) async {
//     try {
//       final headers = await _getHeaders();
//       final queryParams = <String, String>{};

//       if (startDate != null) {
//         queryParams['start_date'] = startDate.toIso8601String().split('T')[0];
//       }
//       if (endDate != null) {
//         queryParams['end_date'] = endDate.toIso8601String().split('T')[0];
//       }

//       final uri = Uri.parse('$baseUrl/api/v1/posmitra/earnings/summary')
//           .replace(queryParameters: queryParams);

//       final response = await http.get(uri, headers: headers);

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         if (data['success'] == true) {
//           return data['data'];
//         }
//         throw Exception(
//             data['message'] ?? 'Gagal mengambil ringkasan pendapatan');
//       }
//       throw Exception('Gagal mengambil ringkasan: ${response.statusCode}');
//     } catch (e) {
//       throw Exception('Error saat mengambil ringkasan: $e');
//     }
//   }

//   /// Get detailed earnings history
//   static Future<List<Map<String, dynamic>>> getEarningsHistory({
//     DateTime? startDate,
//     DateTime? endDate,
//     int page = 1,
//     int limit = 10,
//   }) async {
//     try {
//       final headers = await _getHeaders();
//       final queryParams = {
//         'page': page.toString(),
//         'limit': limit.toString(),
//       };

//       if (startDate != null) {
//         queryParams['start_date'] = startDate.toIso8601String().split('T')[0];
//       }
//       if (endDate != null) {
//         queryParams['end_date'] = endDate.toIso8601String().split('T')[0];
//       }

//       final uri = Uri.parse('$baseUrl/api/v1/posmitra/earnings/history')
//           .replace(queryParameters: queryParams);

//       final response = await http.get(uri, headers: headers);

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         if (data['success'] == true) {
//           return List<Map<String, dynamic>>.from(
//               data['data']['earnings'] ?? []);
//         }
//         throw Exception(
//             data['message'] ?? 'Gagal mengambil riwayat pendapatan');
//       }
//       throw Exception('Gagal mengambil riwayat: ${response.statusCode}');
//     } catch (e) {
//       throw Exception('Error saat mengambil riwayat: $e');
//     }
//   }

//   // ==================== STATISTICS ====================

//   /// Get daily statistics
//   static Future<Map<String, dynamic>> getDailyStats(DateTime date) async {
//     try {
//       final headers = await _getHeaders();
//       final dateStr = date.toIso8601String().split('T')[0];
//       final response = await http.get(
//         Uri.parse('$baseUrl/api/v1/posmitra/stats/daily?date=$dateStr'),
//         headers: headers,
//       );

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         if (data['success'] == true) {
//           return data['data'];
//         }
//         throw Exception(data['message'] ?? 'Gagal mengambil statistik harian');
//       }
//       throw Exception('Gagal mengambil statistik: ${response.statusCode}');
//     } catch (e) {
//       throw Exception('Error saat mengambil statistik: $e');
//     }
//   }

//   // Di file lib/services/posmitra/posmitra_service.dart

// // ✅ SIMPAN YANG INI SAJA (hapus yang lain)
// static Future<Map<String, dynamic>> withdrawBalance({
//   required String token,
//   required double amount,
//   required String bankName,
//   required String accountNumber,
//   required String pin,
// }) async {
//   final response = await http.post(
//     Uri.parse('$baseUrl/api/v1/posmitra/withdraw'),
//     headers: {
//       'Accept': 'application/json',
//       'Content-Type': 'application/json',
//       'Authorization': 'Bearer $token',
//     },
//     body: json.encode({
//       'amount': amount,
//       'bank_name': bankName,
//       'account_number': accountNumber,
//       'pin': pin,
//     }),
//   );

//   print('Withdraw Response Status: ${response.statusCode}');
//   print('Withdraw Response Body: ${response.body}');

//   if (response.statusCode == 200) {
//     return json.decode(response.body);
//   } else {
//     final error = json.decode(response.body);
//     throw Exception(error['message'] ?? 'Failed to withdraw');
//   }
// }

//   /// Get monthly statistics
//   static Future<Map<String, dynamic>> getMonthlyStats(
//       int year, int month) async {
//     try {
//       final headers = await _getHeaders();
//       final response = await http.get(
//         Uri.parse(
//             '$baseUrl/api/v1/posmitra/stats/monthly?year=$year&month=$month'),
//         headers: headers,
//       );

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         if (data['success'] == true) {
//           return data['data'];
//         }
//         throw Exception(data['message'] ?? 'Gagal mengambil statistik bulanan');
//       }
//       throw Exception('Gagal mengambil statistik: ${response.statusCode}');
//     } catch (e) {
//       throw Exception('Error saat mengambil statistik: $e');
//     }
//   }

//   // ==================== HELP / BANTUAN ====================

//   /// Get help articles
//   static Future<List<Map<String, dynamic>>> getHelpArticles() async {
//     try {
//       final headers = await _getHeaders();
//       final response = await http.get(
//         Uri.parse('$baseUrl/api/v1/posmitra/help/articles'),
//         headers: headers,
//       );

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         if (data['success'] == true) {
//           return List<Map<String, dynamic>>.from(
//               data['data']['articles'] ?? []);
//         }
//         throw Exception(data['message'] ?? 'Gagal mengambil artikel bantuan');
//       }
//       throw Exception('Gagal mengambil artikel: ${response.statusCode}');
//     } catch (e) {
//       throw Exception('Error saat mengambil artikel: $e');
//     }
//   }


//   /// Get help article detail
//   static Future<Map<String, dynamic>> getHelpArticleDetail(
//       int articleId) async {
//     try {
//       final headers = await _getHeaders();
//       final response = await http.get(
//         Uri.parse('$baseUrl/api/v1/posmitra/help/articles/$articleId'),
//         headers: headers,
//       );

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         if (data['success'] == true) {
//           return data['data']['article'];
//         }
//         throw Exception(data['message'] ?? 'Gagal mengambil detail artikel');
//       }
//       throw Exception('Gagal mengambil detail: ${response.statusCode}');
//     } catch (e) {
//       throw Exception('Error saat mengambil detail: $e');
//     }
//   }

//   /// Submit help request / feedback
//   static Future<void> submitHelpRequest({
//     required String subject,
//     required String message,
//     File? attachment,
//   }) async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString('api_token');

//       if (token == null || token.isEmpty) {
//         throw Exception('Token tidak ditemukan');
//       }

//       var request = http.MultipartRequest(
//         'POST',
//         Uri.parse('$baseUrl/api/v1/posmitra/help/request'),
//       );

//       request.headers['Authorization'] = 'Bearer $token';
//       request.headers['Accept'] = 'application/json';

//       request.fields['subject'] = subject;
//       request.fields['message'] = message;

//       if (attachment != null) {
//         request.files.add(
//           await http.MultipartFile.fromPath(
//             'attachment',
//             attachment.path,
//           ),
//         );
//       }

//       final streamedResponse = await request.send();
//       final response = await http.Response.fromStream(streamedResponse);

//       if (response.statusCode != 200 && response.statusCode != 201) {
//         throw Exception(
//             'Gagal mengirim permintaan bantuan: ${response.statusCode}');
//       }
//     } catch (e) {
//       throw Exception('Error saat mengirim permintaan bantuan: $e');
//     }
//   }
// }

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
  /// ✅ DIPERBAIKI: Endpoint yang benar
  static Future<double> getBalance() async {
    try {
      print('🔄 [getBalance] Fetching balance...');
      
      final headers = await _getHeaders();
      
      // ✅ ENDPOINT YANG BENAR: /api/posmitra/beranda
      final response = await http.get(
        Uri.parse('$baseUrl/api/posmitra/beranda'),
        headers: headers,
      );

      print('📡 [getBalance] Status: ${response.statusCode}');
      print('📡 [getBalance] Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final balance = data['data']['balance'];
          
          // ✅ Parse balance ke double
          final result = double.tryParse(balance.toString()) ?? 0.0;
          print('✅ [getBalance] Balance parsed: $result');
          return result;
        }
        throw Exception(data['message'] ?? 'Gagal mengambil saldo');
      }
      throw Exception('Gagal mengambil saldo: ${response.statusCode}');
    } catch (e) {
      print('❌ [getBalance] Error: $e');
      rethrow;
    }
  }

  // ==================== PROFILE ====================

static Future<Map<String, dynamic>> getProfile(String token) async {
    try {
      final url = Uri.parse('${ApiService.baseUrl}/api/v1/pos-mitra/profile');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      // Jika status code 200, parse body
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        // Pastikan format success/data ada
        if (data.containsKey('success') && data.containsKey('data')) {
          return data;
        } else {
          // Jika struktur response tidak sesuai
          return {
            'success': false,
            'message': 'Format response tidak valid',
          };
        }
      } else if (response.statusCode == 401) {
        // Token invalid / unauthorized
        return {
          'success': false,
          'message': 'Token tidak valid atau sesi habis. Silakan login kembali.',
        };
      } else {
        // Error lain
        return {
          'success': false,
          'message': 'Gagal load profile (${response.statusCode})',
        };
      }
    } catch (e) {
      // Error koneksi / parsing
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }



  // ==================== STATISTICS ====================

  /// Get statistics (nebeng motor, mobil, barang, titip barang)
  /// ✅ DIPERBAIKI: Endpoint yang benar
  static Future<Map<String, dynamic>> getStatistics() async {
    try {
      print('🔄 [getStatistics] Fetching statistics...');
      
      final headers = await _getHeaders();
      
      // ✅ ENDPOINT YANG BENAR: /api/posmitra/statistics
      final response = await http.get(
        Uri.parse('$baseUrl/api/posmitra/statistics'),
        headers: headers,
      );

      print('📡 [getStatistics] Status: ${response.statusCode}');
      print('📡 [getStatistics] Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          print('✅ [getStatistics] Data: ${data['data']}');
          return data['data'] as Map<String, dynamic>;
        }
        throw Exception(data['message'] ?? 'Gagal mengambil statistik');
      } else if (response.statusCode == 401) {
        throw Exception('Token tidak valid atau sudah kadaluarsa');
      }
      throw Exception('Gagal mengambil statistik: ${response.statusCode}');
    } catch (e) {
      print('❌ [getStatistics] Error: $e');
      rethrow;
    }
  }

  // ==================== UPCOMING RIDES ====================

  /// Get upcoming rides (tebengan akan datang)
  /// ✅ DIPERBAIKI: Endpoint yang benar
 // ==================== RIDES / TEBENGAN UNTUK FILTER TAB ====================

/// 🟢 GET UPCOMING RIDES - Tab "Akan Datang"
static Future<List<Map<String, dynamic>>> getUpcomingRides() async {
  try {
    print('🔄 [getUpcomingRides] Fetching upcoming rides...');
    
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/api/posmitra/upcoming-rides'),
      headers: headers,
    );

    print('📡 [getUpcomingRides] Status: ${response.statusCode}');
    
    // 🔥 TAMBAH 1 BARIS INI UNTUK LIHAT ISI RESPONSE
    print('📦 [getUpcomingRides] Response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        final rides = List<Map<String, dynamic>>.from(data['data'] ?? []);
        print('✅ [getUpcomingRides] Found ${rides.length} upcoming rides');
        return rides;
      }
      throw Exception(data['message'] ?? 'Gagal mengambil data tebengan');
    }
    throw Exception('Gagal mengambil data tebengan: ${response.statusCode}');
  } catch (e) {
    print('❌ [getUpcomingRides] Error: $e');
    return [];
  }
}

/// 🟢 GET COMPLETED RIDES - Tab "Selesai"
/// 🔥 INI YANG ANDA BUTUHKAN!
/// 🟢 GET COMPLETED RIDES - Tab "Selesai"
static Future<List<Map<String, dynamic>>> getCompletedRides() async {
  try {
    print('🔄 [getCompletedRides] Fetching completed rides...');
    
    final headers = await _getHeaders();
    
    // 🔥 GUNAKAN 1 ENDPOINT INI SAJA - HAPUS ALTERNATIF LAINNYA
    final response = await http.get(
      Uri.parse('$baseUrl/api/posmitra/completed-rides'),  // PASTIKAN ENDPOINT INI ADA DI BACKEND
      headers: headers,
    );
    
    print('📡 [getCompletedRides] Status: ${response.statusCode}');
    print('📦 [getCompletedRides] Response: ${response.body}');
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        final rides = List<Map<String, dynamic>>.from(data['data'] ?? []);
        print('✅ [getCompletedRides] Found ${rides.length} completed rides');
        return rides;
      }
    }
    
    print('❌ [getCompletedRides] No completed rides found');
    return [];
    
  } catch (e) {
    print('❌ [getCompletedRides] Error: $e');
    return [];
  }
}
/// 🟢 GET ALL RIDES - Tab "Semua"
static Future<List<Map<String, dynamic>>> getAllRides() async {
  try {
    print('🔄 [getAllRides] Fetching all rides...');
    
    // Ambil upcoming dan completed secara parallel
    final results = await Future.wait([
      getUpcomingRides(),
      getCompletedRides(),
    ], eagerError: false);
    
    final upcoming = results[0];
    final completed = results[1];
    
    // Gabungkan semua rides
    final allRides = [...upcoming, ...completed];
    
    // Urutkan berdasarkan tanggal (terbaru ke terlama)
    allRides.sort((a, b) {
      final dateA = a['date']?.toString() ?? '';
      final dateB = b['date']?.toString() ?? '';
      return dateB.compareTo(dateA);
    });
    
    print('✅ [getAllRides] Total: ${allRides.length} rides');
    print('   - Upcoming: ${upcoming.length}');
    print('   - Completed: ${completed.length}');
    
    return allRides;
  } catch (e) {
    print('❌ [getAllRides] Error: $e');
    return []; // ⚠️ RETURN EMPTY LIST
  }
}
  /// Withdraw Balance
  static Future<Map<String, dynamic>> withdrawBalance({
    required String token,
    required double amount,
    required String bankName,
    required String accountNumber,
    required String pin,
  }) async {
    try {
      print('🔄 [withdrawBalance] Processing withdrawal...');
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/posmitra/withdraw'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'amount': amount,
          'bank_name': bankName,
          'account_number': accountNumber,
          'pin': pin,
        }),
      );

      print('📡 [withdrawBalance] Status: ${response.statusCode}');
      print('📡 [withdrawBalance] Response: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to withdraw');
      }
    } catch (e) {
      print('❌ [withdrawBalance] Error: $e');
      rethrow;
    }
  }

  /// Get withdrawal history
static Future<List<Map<String, dynamic>>> getWithdrawalHistory({
  int page = 1,
  int limit = 10,
}) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('api_token');

    print("TOKEN WITHDRAW: $token");

    final uri = Uri.parse('$baseUrl/v1/posmitra/withdraw/history')
        .replace(queryParameters: {
      'page': page.toString(),
      'limit': limit.toString(),
    });

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    print("STATUS: ${response.statusCode}");
    print("BODY: ${response.body}");

    if (response.statusCode != 200) {
      throw Exception('Gagal mengambil riwayat: ${response.statusCode}');
    }

    final decoded = json.decode(response.body);

    if (decoded is! Map) {
      throw Exception('Format response tidak valid');
    }

    if (decoded['success'] != true) {
      throw Exception(decoded['message'] ?? 'Gagal mengambil riwayat');
    }

    final rawData = decoded['data'];

    if (rawData is List) {
      return List<Map<String, dynamic>>.from(rawData);
    }

    // Jika backend suatu saat mengubah struktur
    if (rawData is Map && rawData['withdrawals'] is List) {
      return List<Map<String, dynamic>>.from(rawData['withdrawals']);
    }

    return [];
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
        Uri.parse('$baseUrl/api/v1/posmitra/withdraw/$withdrawalId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data']['withdrawal'] ?? data['data'];
        }
        throw Exception(data['message'] ?? 'Gagal mengambil detail pencairan');
      }
      throw Exception('Gagal mengambil detail: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error saat mengambil detail: $e');
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
      final uri = Uri.parse('$baseUrl/api/v1/notifications')
          .replace(queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
      });

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(
              data['data']['notifications'] ?? data['data'] ?? []);
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
        Uri.parse('$baseUrl/api/v1/notifications/$notificationId/read'),
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
        Uri.parse('$baseUrl/api/v1/notifications/read-all'),
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
       Uri.parse('$baseUrl/api/v1/auth/update-profile'),
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


  //   // ==================== QR CODE SCANNING ====================

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

}