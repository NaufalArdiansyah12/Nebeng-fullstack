import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/withdrawal_model.dart';
import '../services/api_service.dart';

class WithdrawalService {
  static String get baseUrl => ApiService.baseUrl;

  // Get balance and bank info
  static Future<BalanceInfo> getBalanceInfo(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/mitra/withdrawal/balance'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return BalanceInfo.fromJson(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Gagal mengambil informasi saldo');
        }
      } else {
        final data = json.decode(response.body);
        throw Exception(data['message'] ?? 'Gagal mengambil informasi saldo');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Submit withdrawal request
  static Future<Map<String, dynamic>> submitWithdrawal({
    required String token,
    required double amount,
    required String pin,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/mitra/withdrawal/submit'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'amount': amount,
          'pin': pin,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        if (data['success']) {
          return data['data'];
        } else {
          throw Exception(data['message'] ?? 'Gagal mengajukan penarikan');
        }
      } else {
        throw Exception(data['message'] ?? 'Gagal mengajukan penarikan');
      }
    } catch (e) {
      throw Exception('$e');
    }
  }

  // Get withdrawal detail
  static Future<WithdrawalModel> getWithdrawalDetail({
    required String token,
    required int withdrawalId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/mitra/withdrawal/$withdrawalId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return WithdrawalModel.fromJson(data['data']);
        } else {
          throw Exception(
              data['message'] ?? 'Gagal mengambil detail penarikan');
        }
      } else {
        final data = json.decode(response.body);
        throw Exception(data['message'] ?? 'Gagal mengambil detail penarikan');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Check withdrawal status
  static Future<Map<String, dynamic>> checkStatus({
    required String token,
    required int withdrawalId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/mitra/withdrawal/$withdrawalId/status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return data['data'];
        } else {
          throw Exception(data['message'] ?? 'Gagal memeriksa status');
        }
      } else {
        throw Exception('Gagal memeriksa status');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Verify PIN
  static Future<bool> verifyPin({
    required String token,
    required String pin,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/mitra/pin/verify'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'pin': pin,
        }),
      );

      final data = json.decode(response.body);
      return data['success'] ?? false;
    } catch (e) {
      return false;
    }
  }

  // Get withdrawal history
  static Future<List<Map<String, dynamic>>> getHistory({
    required String token,
    String? status, // null for all, 'processing' or 'completed'
  }) async {
    try {
      String url = '$baseUrl/api/v1/mitra/withdrawal/history/list';
      if (status != null) {
        url += '?status=$status';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return List<Map<String, dynamic>>.from(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Gagal mengambil riwayat');
        }
      } else {
        final data = json.decode(response.body);
        throw Exception(data['message'] ?? 'Gagal mengambil riwayat');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
