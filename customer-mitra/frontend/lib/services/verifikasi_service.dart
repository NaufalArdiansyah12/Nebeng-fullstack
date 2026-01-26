import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/verifikasi_model.dart';
import 'api_service.dart';

class VerifikasiService {
  /// Get verification status
  static Future<Map<String, dynamic>> getVerificationStatus(
      String token) async {
    final uri =
        Uri.parse('${ApiService.baseUrl}/api/v1/customer/verification/status');
    final resp = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (resp.statusCode == 200) {
      final body = json.decode(resp.body) as Map<String, dynamic>;
      if (body['success'] == true) {
        return body;
      }
      throw Exception('Unexpected response format');
    }
    throw Exception('Failed to get verification status: ${resp.statusCode}');
  }

  /// Get verification details
  static Future<VerifikasiCustomer> getVerification(String token) async {
    final uri = Uri.parse('${ApiService.baseUrl}/api/v1/customer/verification');
    final resp = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (resp.statusCode == 200) {
      final body = json.decode(resp.body);
      if (body is Map && body['success'] == true) {
        return VerifikasiCustomer.fromJson(body['data']);
      }
      throw Exception('Unexpected response format');
    }
    throw Exception('Failed to get verification: ${resp.statusCode}');
  }

  /// Upload face photo
  static Future<Map<String, dynamic>> uploadFacePhoto({
    required String token,
    required File photo,
  }) async {
    final uri = Uri.parse(
        '${ApiService.baseUrl}/api/v1/customer/verification/upload-face');

    var request = http.MultipartRequest('POST', uri);
    request.headers.addAll({
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    });

    request.files.add(await http.MultipartFile.fromPath('photo', photo.path));

    final streamedResponse = await request.send();
    final resp = await http.Response.fromStream(streamedResponse);

    if (resp.statusCode == 200) {
      final body = json.decode(resp.body) as Map<String, dynamic>;
      if (body['success'] == true) {
        return body;
      }
      throw Exception(body['message'] ?? 'Unexpected response format');
    }

    final body = json.decode(resp.body) as Map<String, dynamic>;
    throw Exception(
        body['message'] ?? 'Failed to upload face photo: ${resp.statusCode}');
  }

  /// Upload KTP photo
  static Future<Map<String, dynamic>> uploadKtpPhoto({
    required String token,
    required File photo,
    required String namaLengkap,
    required String nik,
    required String tanggalLahir,
    required String alamat,
  }) async {
    final uri = Uri.parse(
        '${ApiService.baseUrl}/api/v1/customer/verification/upload-ktp');

    var request = http.MultipartRequest('POST', uri);
    request.headers.addAll({
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    });

    request.files.add(await http.MultipartFile.fromPath('photo', photo.path));
    request.fields['nama_lengkap'] = namaLengkap;
    request.fields['nik'] = nik;
    request.fields['tanggal_lahir'] = tanggalLahir;
    request.fields['alamat'] = alamat;

    final streamedResponse = await request.send();
    final resp = await http.Response.fromStream(streamedResponse);

    if (resp.statusCode == 200) {
      final body = json.decode(resp.body) as Map<String, dynamic>;
      if (body['success'] == true) {
        return body;
      }
      throw Exception(body['message'] ?? 'Unexpected response format');
    }

    final body = json.decode(resp.body) as Map<String, dynamic>;
    throw Exception(
        body['message'] ?? 'Failed to upload KTP photo: ${resp.statusCode}');
  }

  /// Upload face and KTP photo (selfie with KTP)
  static Future<Map<String, dynamic>> uploadFaceKtpPhoto({
    required String token,
    required File photo,
    required String namaLengkap,
    required String nik,
    required String tanggalLahir,
    required String alamat,
  }) async {
    final uri = Uri.parse(
        '${ApiService.baseUrl}/api/v1/customer/verification/upload-face-ktp');

    var request = http.MultipartRequest('POST', uri);
    request.headers.addAll({
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    });

    request.files.add(await http.MultipartFile.fromPath('photo', photo.path));
    request.fields['nama_lengkap'] = namaLengkap;
    request.fields['nik'] = nik;
    request.fields['tanggal_lahir'] = tanggalLahir;
    request.fields['alamat'] = alamat;

    final streamedResponse = await request.send();
    final resp = await http.Response.fromStream(streamedResponse);

    if (resp.statusCode == 200) {
      final body = json.decode(resp.body) as Map<String, dynamic>;
      if (body['success'] == true) {
        return body;
      }
      throw Exception(body['message'] ?? 'Unexpected response format');
    }

    final body = json.decode(resp.body) as Map<String, dynamic>;
    throw Exception(body['message'] ??
        'Failed to upload face and KTP photo: ${resp.statusCode}');
  }

  /// Submit verification
  static Future<Map<String, dynamic>> submitVerification(String token) async {
    final uri =
        Uri.parse('${ApiService.baseUrl}/api/v1/customer/verification/submit');
    final resp = await http.post(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (resp.statusCode == 200) {
      final body = json.decode(resp.body) as Map<String, dynamic>;
      if (body['success'] == true) {
        return body;
      }
      throw Exception('Unexpected response format');
    }

    final body = json.decode(resp.body) as Map<String, dynamic>;
    throw Exception(
        body['message'] ?? 'Failed to submit verification: ${resp.statusCode}');
  }
}
