-- Create Database
CREATE DATABASE IF NOT EXISTS `nebeng-bro`;
USE `nebeng-bro`;

-- Users Table
CREATE TABLE IF NOT EXISTS users (
  id INT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255) UNIQUE NOT NULL,
  phone VARCHAR(20),
  password VARCHAR(255),
  role ENUM('admin', 'mitra', 'customer') NOT NULL,
  status ENUM('active', 'inactive', 'blocked') DEFAULT 'active',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_role (role),
  INDEX idx_status (status)
);

-- Admin Table
CREATE TABLE IF NOT EXISTS admin (
  id INT PRIMARY KEY AUTO_INCREMENT,
  user_id INT NOT NULL,
  nama_lengkap VARCHAR(255),
  email VARCHAR(255),
  tempat_lahir VARCHAR(255),
  tanggal_lahir DATE,
  jenis_kelamin ENUM('Laki-Laki', 'Perempuan'),
  no_tlp VARCHAR(20),
  layanan VARCHAR(255),
  foto VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Kendaraan Mitra Table
CREATE TABLE IF NOT EXISTS kendaraan_mitra (
  id INT PRIMARY KEY AUTO_INCREMENT,
  mitra_id INT NOT NULL,
  jenis_kendaraan VARCHAR(50),
  merek_kendaraan VARCHAR(100),
  plat_nomor VARCHAR(20) UNIQUE,
  warna VARCHAR(50),
  tahun_produksi INT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (mitra_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_mitra_id (mitra_id)
);

-- Verifikasi KTP Mitra Table
CREATE TABLE IF NOT EXISTS verifikasi_ktp_mitras (
  id INT PRIMARY KEY AUTO_INCREMENT,
  mitra_id INT NOT NULL,
  nik VARCHAR(20) UNIQUE NOT NULL,
  nama_lengkap VARCHAR(255) NOT NULL,
  tanggal_lahir DATE,
  foto_ktp VARCHAR(255),
  status ENUM('pending', 'approved', 'rejected') DEFAULT 'pending',
  catatan TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (mitra_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_status (status)
);

-- Verifikasi KTP Customer Table
CREATE TABLE IF NOT EXISTS verifikasi_ktp_customers (
  id INT PRIMARY KEY AUTO_INCREMENT,
  user_id INT NOT NULL,
  nik VARCHAR(20) UNIQUE NOT NULL,
  nama_lengkap VARCHAR(255) NOT NULL,
  tanggal_lahir DATE,
  foto_ktp VARCHAR(255),
  status ENUM('pending', 'approved', 'rejected') DEFAULT 'pending',
  catatan TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_status (status)
);

-- Pesanan Table
CREATE TABLE IF NOT EXISTS pesanan (
  id INT PRIMARY KEY AUTO_INCREMENT,
  customer_id INT NOT NULL,
  mitra_id INT NOT NULL,
  kendaraan_id INT,
  pickup_location VARCHAR(255) NOT NULL,
  dropoff_location VARCHAR(255) NOT NULL,
  pickup_time DATETIME NOT NULL,
  dropoff_time DATETIME,
  status ENUM('pending', 'accepted', 'in_transit', 'completed', 'cancelled') DEFAULT 'pending',
  total_price DECIMAL(10, 2),
  payment_status ENUM('pending', 'paid', 'cancelled') DEFAULT 'pending',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (customer_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (mitra_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (kendaraan_id) REFERENCES kendaraan_mitra(id) ON DELETE SET NULL,
  INDEX idx_status (status),
  INDEX idx_customer_id (customer_id),
  INDEX idx_mitra_id (mitra_id)
);

-- Laporan Table
CREATE TABLE IF NOT EXISTS laporan (
  id INT PRIMARY KEY AUTO_INCREMENT,
  pesanan_id INT NOT NULL,
  customer_id INT NOT NULL,
  mitra_id INT NOT NULL,
  judul VARCHAR(255) NOT NULL,
  deskripsi TEXT NOT NULL,
  kategori VARCHAR(100),
  bukti_foto VARCHAR(255),
  status ENUM('pending', 'reviewed', 'resolved', 'rejected') DEFAULT 'pending',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (pesanan_id) REFERENCES pesanan(id) ON DELETE CASCADE,
  FOREIGN KEY (customer_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (mitra_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_status (status)
);

-- Refund Table
CREATE TABLE IF NOT EXISTS refund (
  id INT PRIMARY KEY AUTO_INCREMENT,
  pesanan_id INT NOT NULL,
  customer_id INT NOT NULL,
  mitra_id INT NOT NULL,
  alasan VARCHAR(255) NOT NULL,
  deskripsi TEXT,
  jumlah DECIMAL(10, 2) NOT NULL,
  status ENUM('pending', 'approved', 'rejected', 'completed') DEFAULT 'pending',
  bukti_pembayaran VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (pesanan_id) REFERENCES pesanan(id) ON DELETE CASCADE,
  FOREIGN KEY (customer_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (mitra_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_status (status)
);

-- Insert sample data
INSERT INTO users (name, email, phone, password, role, status) VALUES
('Admin User', 'admin@nebeng.com', '081234567890', 'hashed_password_here', 'admin', 'active'),
('Muhammad Abdul', 'abdul@nebeng.com', '082345678901', 'hashed_password_here', 'mitra', 'active'),
('Siti Aminah', 'siti@nebeng.com', '083456789012', 'hashed_password_here', 'customer', 'active');

-- Insert admin profile
INSERT INTO admin (user_id, nama_lengkap, email, no_tlp, layanan) VALUES
(1, 'Admin Nebeng', 'admin@nebeng.com', '081234567890', 'Admin System');

-- Insert sample kendaraan
INSERT INTO kendaraan_mitra (mitra_id, jenis_kendaraan, merek_kendaraan, plat_nomor, warna, tahun_produksi) VALUES
(2, 'Motor', 'Honda', 'B 1234 ABC', 'Putih', 2023),
(2, 'Mobil', 'Toyota', 'B 5678 XYZ', 'Hitam', 2022);

-- Insert sample verifikasi
INSERT INTO verifikasi_ktp_mitras (mitra_id, nik, nama_lengkap, status) VALUES
(2, '1234567890123456', 'Muhammad Abdul', 'approved');

INSERT INTO verifikasi_ktp_customers (user_id, nik, nama_lengkap, status) VALUES
(3, '9876543210123456', 'Siti Aminah', 'approved');
