import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

/// Phone Verification Service - handles phone verification with email OTP
class PhoneVerificationService {
  /// Kirim OTP ke email untuk verifikasi nomor HP
  static Future<Map<String, dynamic>> sendOtp({
    required String token,
    required String phone,
  }) async {
    final uri =
        Uri.parse('${ApiConfig.baseUrl}/api/v1/phone-verification/send-otp');
    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final body = json.encode({'phone': phone});

    try {
      final resp = await http.post(uri, headers: headers, body: body);
      final responseData = json.decode(resp.body);

      if (resp.statusCode == 200 && responseData['success'] == true) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Kode OTP berhasil dikirim',
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Gagal mengirim kode OTP',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }

  /// Verify OTP yang diinput user
  static Future<Map<String, dynamic>> verifyOtp({
    required String token,
    required String phone,
    required String otpCode,
  }) async {
    final uri =
        Uri.parse('${ApiConfig.baseUrl}/api/v1/phone-verification/verify-otp');
    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final body = json.encode({
      'phone': phone,
      'otp_code': otpCode,
    });

    try {
      final resp = await http.post(uri, headers: headers, body: body);
      final responseData = json.decode(resp.body);

      if (resp.statusCode == 200 && responseData['success'] == true) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Verifikasi berhasil',
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Kode OTP salah',
          'data': responseData['data'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }

  /// Resend OTP (request ulang kode baru)
  static Future<Map<String, dynamic>> resendOtp({
    required String token,
    required String phone,
  }) async {
    final uri =
        Uri.parse('${ApiConfig.baseUrl}/api/v1/phone-verification/resend-otp');
    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final body = json.encode({'phone': phone});

    try {
      final resp = await http.post(uri, headers: headers, body: body);
      final responseData = json.decode(resp.body);

      if (resp.statusCode == 200 && responseData['success'] == true) {
        return {
          'success': true,
          'message':
              responseData['message'] ?? 'Kode OTP baru berhasil dikirim',
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Gagal mengirim ulang kode OTP',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }

  /// Get status verifikasi nomor HP
  static Future<Map<String, dynamic>> getPhoneStatus({
    required String token,
  }) async {
    final uri =
        Uri.parse('${ApiConfig.baseUrl}/api/v1/phone-verification/status');
    final headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      final resp = await http.get(uri, headers: headers);
      final responseData = json.decode(resp.body);

      if (resp.statusCode == 200 && responseData['success'] == true) {
        return {
          'success': true,
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message':
              responseData['message'] ?? 'Gagal mengambil status verifikasi',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }
}
