class VerifikasiCustomer {
  final int? id;
  final String? namaLengkap;
  final String? nik;
  final String? tanggalLahir;
  final String? alamat;
  final String? photoWajah;
  final String? photoKtp;
  final String? photoKtpWajah;
  final String status;
  final String? reviewedAt;
  final String? createdAt;
  final String? updatedAt;

  VerifikasiCustomer({
    this.id,
    this.namaLengkap,
    this.nik,
    this.tanggalLahir,
    this.alamat,
    this.photoWajah,
    this.photoKtp,
    this.photoKtpWajah,
    required this.status,
    this.reviewedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory VerifikasiCustomer.fromJson(Map<String, dynamic> json) {
    return VerifikasiCustomer(
      id: json['id'],
      namaLengkap: json['nama_lengkap'],
      nik: json['nik'],
      tanggalLahir: json['tanggal_lahir'],
      alamat: json['alamat'],
      photoWajah: json['photo_wajah'],
      photoKtp: json['photo_ktp'],
      photoKtpWajah: json['photo_ktp_wajah'],
      status: json['status'] ?? 'pending',
      reviewedAt: json['reviewed_at'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama_lengkap': namaLengkap,
      'nik': nik,
      'tanggal_lahir': tanggalLahir,
      'alamat': alamat,
      'photo_wajah': photoWajah,
      'photo_ktp': photoKtp,
      'photo_ktp_wajah': photoKtpWajah,
      'status': status,
      'reviewed_at': reviewedAt,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

class VerifikasiStatus {
  final bool hasVerification;
  final String? status;
  final bool verifikasiWajah;
  final bool verifikasiKtp;
  final bool verifikasiWajahKtp;

  VerifikasiStatus({
    required this.hasVerification,
    this.status,
    required this.verifikasiWajah,
    required this.verifikasiKtp,
    required this.verifikasiWajahKtp,
  });

  factory VerifikasiStatus.fromJson(Map<String, dynamic> json) {
    return VerifikasiStatus(
      hasVerification: json['has_verification'] ?? false,
      status: json['status'],
      verifikasiWajah: json['verifikasi_wajah'] ?? false,
      verifikasiKtp: json['verifikasi_ktp'] ?? false,
      verifikasiWajahKtp: json['verifikasi_wajah_ktp'] ?? false,
    );
  }
}
