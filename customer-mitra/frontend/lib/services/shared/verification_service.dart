import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

/// Verification Service - handles mitra document verification
class VerificationService {
  /// Submit KTP verification
  static Future<Map<String, dynamic>> submitKtpVerification({
    required String token,
    required String ktpNumber,
    required String ktpName,
    required String ktpBirthDate,
    required String ktpPhotoPath,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/mitra/verification/ktp');
    final request = http.MultipartRequest('POST', uri);

    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';

    request.fields['ktp_number'] = ktpNumber;
    request.fields['ktp_name'] = ktpName;
    request.fields['ktp_birth_date'] = ktpBirthDate;

    final file = await http.MultipartFile.fromPath('ktp_photo', ktpPhotoPath);
    request.files.add(file);

    final streamedResp = await request.send();
    final resp = await http.Response.fromStream(streamedResp);

    if (resp.statusCode == 201 || resp.statusCode == 200) {
      final body = json.decode(resp.body);
      if (body is Map && body['success'] == true) {
        return Map<String, dynamic>.from(body);
      }
      throw Exception(body['message'] ?? 'Failed to submit KTP verification');
    }

    final body = json.decode(resp.body);
    throw Exception(body['message'] ??
        'Failed to submit KTP verification: ${resp.statusCode}');
  }

  /// Update KTP verification (uses PUT)
  static Future<Map<String, dynamic>> updateKtpVerification({
    required String token,
    required String ktpNumber,
    required String ktpName,
    required String ktpBirthDate,
    String? ktpPhotoPath,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/mitra/verification/ktp');

    // If no new photo path provided, send a JSON PUT
    if (ktpPhotoPath == null) {
      final resp = await http.put(uri,
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'ktp_number': ktpNumber,
            'ktp_name': ktpName,
            'ktp_birth_date': ktpBirthDate,
          }));

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final body = json.decode(resp.body);
        if (body is Map && body['success'] == true) {
          return Map<String, dynamic>.from(body);
        }
        throw Exception(body['message'] ?? 'Failed to update KTP verification');
      }

      final body = json.decode(resp.body);
      throw Exception(body['message'] ??
          'Failed to update KTP verification: ${resp.statusCode}');
    }

    final request = http.MultipartRequest('PUT', uri);
    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';
    request.fields['ktp_number'] = ktpNumber;
    request.fields['ktp_name'] = ktpName;
    request.fields['ktp_birth_date'] = ktpBirthDate;

    final file = await http.MultipartFile.fromPath('ktp_photo', ktpPhotoPath);
    request.files.add(file);

    final streamedResp = await request.send();
    final resp = await http.Response.fromStream(streamedResp);

    if (resp.statusCode == 200 || resp.statusCode == 201) {
      final body = json.decode(resp.body);
      if (body is Map && body['success'] == true) {
        return Map<String, dynamic>.from(body);
      }
      throw Exception(body['message'] ?? 'Failed to update KTP verification');
    }

    final body = json.decode(resp.body);
    throw Exception(body['message'] ??
        'Failed to update KTP verification: ${resp.statusCode}');
  }

  /// Submit SIM verification
  static Future<Map<String, dynamic>> submitSimVerification({
    required String token,
    required String simNumber,
    required String simType,
    required String simExpiryDate,
    required String simPhotoPath,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/mitra/verification/sim');
    final request = http.MultipartRequest('POST', uri);

    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';

    request.fields['sim_number'] = simNumber;
    request.fields['sim_type'] = simType;
    request.fields['sim_expiry_date'] = simExpiryDate;

    final file = await http.MultipartFile.fromPath('sim_photo', simPhotoPath);
    request.files.add(file);

    final streamedResp = await request.send();
    final resp = await http.Response.fromStream(streamedResp);

    if (resp.statusCode == 201 || resp.statusCode == 200) {
      final body = json.decode(resp.body);
      if (body is Map && body['success'] == true) {
        return Map<String, dynamic>.from(body);
      }
      throw Exception(body['message'] ?? 'Failed to submit SIM verification');
    }

    final body = json.decode(resp.body);
    throw Exception(body['message'] ??
        'Failed to submit SIM verification: ${resp.statusCode}');
  }

  /// Update SIM verification (uses PUT)
  static Future<Map<String, dynamic>> updateSimVerification({
    required String token,
    required String simNumber,
    required String simType,
    required String simExpiryDate,
    String? simPhotoPath,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/mitra/verification/sim');

    if (simPhotoPath == null) {
      final resp = await http.put(uri,
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'sim_number': simNumber,
            'sim_type': simType,
            'sim_expiry_date': simExpiryDate,
          }));

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final body = json.decode(resp.body);
        if (body is Map && body['success'] == true) {
          return Map<String, dynamic>.from(body);
        }
        throw Exception(body['message'] ?? 'Failed to update SIM verification');
      }

      final body = json.decode(resp.body);
      throw Exception(body['message'] ??
          'Failed to update SIM verification: ${resp.statusCode}');
    }

    final request = http.MultipartRequest('PUT', uri);
    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';
    request.fields['sim_number'] = simNumber;
    request.fields['sim_type'] = simType;
    request.fields['sim_expiry_date'] = simExpiryDate;

    final file = await http.MultipartFile.fromPath('sim_photo', simPhotoPath);
    request.files.add(file);

    final streamedResp = await request.send();
    final resp = await http.Response.fromStream(streamedResp);

    if (resp.statusCode == 200 || resp.statusCode == 201) {
      final body = json.decode(resp.body);
      if (body is Map && body['success'] == true) {
        return Map<String, dynamic>.from(body);
      }
      throw Exception(body['message'] ?? 'Failed to update SIM verification');
    }

    final body = json.decode(resp.body);
    throw Exception(body['message'] ??
        'Failed to update SIM verification: ${resp.statusCode}');
  }

  /// Submit SKCK verification
  static Future<Map<String, dynamic>> submitSkckVerification({
    required String token,
    required String skckNumber,
    required String skckName,
    required String skckExpiryDate,
    required String skckPhotoPath,
  }) async {
    final uri =
        Uri.parse('${ApiConfig.baseUrl}/api/v1/mitra/verification/skck');
    final request = http.MultipartRequest('POST', uri);

    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';

    request.fields['skck_number'] = skckNumber;
    request.fields['skck_name'] = skckName;
    request.fields['skck_expiry_date'] = skckExpiryDate;

    final file = await http.MultipartFile.fromPath('skck_photo', skckPhotoPath);
    request.files.add(file);

    final streamedResp = await request.send();
    final resp = await http.Response.fromStream(streamedResp);

    if (resp.statusCode == 201 || resp.statusCode == 200) {
      final body = json.decode(resp.body);
      if (body is Map && body['success'] == true) {
        return Map<String, dynamic>.from(body);
      }
      throw Exception(body['message'] ?? 'Failed to submit SKCK verification');
    }

    final body = json.decode(resp.body);
    throw Exception(body['message'] ??
        'Failed to submit SKCK verification: ${resp.statusCode}');
  }

  /// Update SKCK verification (uses PUT)
  static Future<Map<String, dynamic>> updateSkckVerification({
    required String token,
    required String skckNumber,
    required String skckName,
    required String skckExpiryDate,
    String? skckPhotoPath,
  }) async {
    final uri =
        Uri.parse('${ApiConfig.baseUrl}/api/v1/mitra/verification/skck');

    if (skckPhotoPath == null) {
      final resp = await http.put(uri,
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'skck_number': skckNumber,
            'skck_name': skckName,
            'skck_expiry_date': skckExpiryDate,
          }));

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final body = json.decode(resp.body);
        if (body is Map && body['success'] == true) {
          return Map<String, dynamic>.from(body);
        }
        throw Exception(
            body['message'] ?? 'Failed to update SKCK verification');
      }

      final body = json.decode(resp.body);
      throw Exception(body['message'] ??
          'Failed to update SKCK verification: ${resp.statusCode}');
    }

    final request = http.MultipartRequest('PUT', uri);
    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';
    request.fields['skck_number'] = skckNumber;
    request.fields['skck_name'] = skckName;
    request.fields['skck_expiry_date'] = skckExpiryDate;

    final file = await http.MultipartFile.fromPath('skck_photo', skckPhotoPath);
    request.files.add(file);

    final streamedResp = await request.send();
    final resp = await http.Response.fromStream(streamedResp);

    if (resp.statusCode == 200 || resp.statusCode == 201) {
      final body = json.decode(resp.body);
      if (body is Map && body['success'] == true) {
        return Map<String, dynamic>.from(body);
      }
      throw Exception(body['message'] ?? 'Failed to update SKCK verification');
    }

    final body = json.decode(resp.body);
    throw Exception(body['message'] ??
        'Failed to update SKCK verification: ${resp.statusCode}');
  }

  /// Submit Bank verification
  static Future<Map<String, dynamic>> submitBankVerification({
    required String token,
    required String bankAccountNumber,
    required String bankAccountName,
    required String bankName,
    required String bankPhotoPath,
  }) async {
    final uri =
        Uri.parse('${ApiConfig.baseUrl}/api/v1/mitra/verification/bank');
    final request = http.MultipartRequest('POST', uri);

    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';

    request.fields['bank_account_number'] = bankAccountNumber;
    request.fields['bank_account_name'] = bankAccountName;
    request.fields['bank_name'] = bankName;

    final file =
        await http.MultipartFile.fromPath('bank_account_photo', bankPhotoPath);
    request.files.add(file);

    final streamedResp = await request.send();
    final resp = await http.Response.fromStream(streamedResp);

    if (resp.statusCode == 201 || resp.statusCode == 200) {
      final body = json.decode(resp.body);
      if (body is Map && body['success'] == true) {
        return Map<String, dynamic>.from(body);
      }
      throw Exception(body['message'] ?? 'Failed to submit bank verification');
    }

    final body = json.decode(resp.body);
    throw Exception(body['message'] ??
        'Failed to submit bank verification: ${resp.statusCode}');
  }

  /// Update Bank verification (uses PUT)
  static Future<Map<String, dynamic>> updateBankVerification({
    required String token,
    required String bankAccountNumber,
    required String bankAccountName,
    required String bankName,
    String? bankPhotoPath,
  }) async {
    final uri =
        Uri.parse('${ApiConfig.baseUrl}/api/v1/mitra/verification/bank');

    if (bankPhotoPath == null) {
      final resp = await http.put(uri,
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'bank_account_number': bankAccountNumber,
            'bank_account_name': bankAccountName,
            'bank_name': bankName,
          }));

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final body = json.decode(resp.body);
        if (body is Map && body['success'] == true) {
          return Map<String, dynamic>.from(body);
        }
        throw Exception(
            body['message'] ?? 'Failed to update bank verification');
      }

      final body = json.decode(resp.body);
      throw Exception(body['message'] ??
          'Failed to update bank verification: ${resp.statusCode}');
    }

    final request = http.MultipartRequest('PUT', uri);

    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';

    request.fields['bank_account_number'] = bankAccountNumber;
    request.fields['bank_account_name'] = bankAccountName;
    request.fields['bank_name'] = bankName;

    final file =
        await http.MultipartFile.fromPath('bank_account_photo', bankPhotoPath);
    request.files.add(file);

    final streamedResp = await request.send();
    final resp = await http.Response.fromStream(streamedResp);

    if (resp.statusCode == 200 || resp.statusCode == 201) {
      final body = json.decode(resp.body);
      if (body is Map && body['success'] == true) {
        return Map<String, dynamic>.from(body);
      }
      throw Exception(body['message'] ?? 'Failed to update bank verification');
    }

    final body = json.decode(resp.body);
    throw Exception(body['message'] ??
        'Failed to update bank verification: ${resp.statusCode}');
  }

  /// Link all mitra verifications to mitra_verifikasi table
  static Future<Map<String, dynamic>> linkMitraVerifications(
      String token) async {
    final uri =
        Uri.parse('${ApiConfig.baseUrl}/api/v1/mitra/verification/link');
    final request = http.Request('POST', uri);

    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';

    final streamedResp = await request.send();
    final resp = await http.Response.fromStream(streamedResp);

    if (resp.statusCode == 200) {
      final body = json.decode(resp.body);
      if (body is Map && body['success'] == true) {
        return Map<String, dynamic>.from(body);
      }
      throw Exception(body['message'] ?? 'Failed to link mitra verifications');
    }

    final body = json.decode(resp.body);
    throw Exception(body['message'] ??
        'Failed to link mitra verifications: ${resp.statusCode}');
  }

  /// Get mitra verification status
  static Future<Map<String, dynamic>> getMitraVerificationStatus(
      String token) async {
    final uri =
        Uri.parse('${ApiConfig.baseUrl}/api/v1/mitra/verification/status');
    final resp = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (resp.statusCode == 200) {
      final body = json.decode(resp.body);
      if (body is Map && body['success'] == true) {
        return Map<String, dynamic>.from(body);
      }
      throw Exception(body['message'] ?? 'Failed to get verification status');
    }

    final body = json.decode(resp.body);
    throw Exception(body['message'] ??
        'Failed to get verification status: ${resp.statusCode}');
  }
}
