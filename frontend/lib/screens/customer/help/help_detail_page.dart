import 'package:flutter/material.dart';

class HelpDetailPage extends StatefulWidget {
  final String title;
  final String type;

  const HelpDetailPage({
    Key? key,
    required this.title,
    required this.type,
  }) : super(key: key);

  @override
  State<HelpDetailPage> createState() => _HelpDetailPageState();
}

class _HelpDetailPageState extends State<HelpDetailPage> {
  bool? _isHelpful;

  String _getContent() {
    switch (widget.type) {
      case 'accident':
        return '''Jika kamu sedang berada pada kondisi darurat, pastikan bahwa kamu sudah berada di tempat yang aman. Cabalah untuk menghubungi segera minta pertolongan setempat.

Setelah itu kamu bisa menelepon atau membuat laporan kepada kami dengan klik tombol di bawah "Masih memerlukan bantuan?". Jika diperlukan, kamu juga bisa hubungi "Nama-nama Kontak Darurat" berikut:

• 110 untuk menghubungi Polisi

• 118 atau 119 untuk menghubungi bantuan Tenaga Media (Ambulans)

• 112 untuk nomor darurat

Kami memohon maaf sebesar-besarnya apabila kamu mengalami kecelakaan pada saat berkendara. menggunakan layanan Nebeng. Kami selalu berusaha sebaik mungkin untuk menjaga keamanan dan kenyamanan kamu yang merupakan prioritas utama kami.''';

      case 'left_item_motor':
        return '''Kamu turun menyesal jika ada barang yang tertinggal setelah menggunakan layanan Nebeng Motor. Kami memohon kelengkapanmu.

Agar barang yang tertinggal lebih cepat terlaGak, kami sarankan untuk langsung klik 'Chat dengan CS' di bawah artikel ini untuk mendapatkan informasi kontak driver.

Perlu diingat, Nebeng maupun mitra driver tidak bertanggung jawab atas barang yang tertinggal di kendaraan. Namun, kami akan berusaha sebaik mungkin untuk menemukan kembali barang tersebut.''';

      case 'left_item_car':
        return '''Kamu turun menyesal jika ada barang yang tertinggal setelah menggunakan layanan Nebeng Mobil. Kami memohon kelengkapanmu.

Agar barang yang tertinggal lebih cepat terlaGak, kami sarankan untuk langsung klik 'Chat dengan CS' di bawah artikel ini untuk mendapatkan informasi kontak driver.

Perlu diingat, Nebeng maupun mitra driver tidak bertanggung jawab atas barang yang tertinggal di kendaraan. Namun, kami akan berusaha sebaik mungkin untuk menemukan kembali barang tersebut.''';

      case 'fraud':
        return '''Saya mengalami penipuan

Segera laporkan dengan klik tombol yang tersedia di bawah "Masih memerlukan bantuan?" jika kamu mengalami penipuan yang menyebabkan kehilangan saldo eWay. Laporan yang sangat berlaku sangat berharga untuk mencegah kegiatan merugikan yang terus berlanjut.

Salam melapor ke kami, kamu juga bisa melaporkan penipu melalui platform yang mereka gunakan untuk memburu (contoh: sosial media, aplikasi).

Bukti yang dibutuhkan untuk pelaporan

• Bukti screenshot/foto percakapan

• Detail kontak penipu (nomor telepon/WhatsApp, nama akun media sosial, dll)

• Surat laporan dari kepolisian (jika ada)

Catatan: Pelaporan tidak menjamin pengembalian saldo. Permintaan pengembalian saldo dianggap bila kasus memenuhi syarat dan ketentuan program Jaminan Saldo Kembali.''';

      case 'harassment':
        return '''Kami mohon maaf atas ketidaknyamanan yang kamu alami karena driver berperilaku tidak menyenangkan. Segera laporkan kepada kami dengan menekan tombol "Chat dengan CS" di bawah ini untuk memastikan detail kepadanya.

Perlu diketahui bahwa Nebeng tidak menerima tindakan pelecehan dalam bentuk apapun yang terkait, merendah, atau merendahkan mitra yang bersangkutan akan mendapatkan sanksi sesuai kebijakan kami.''';

      case 'change_profile':
        return '''Berikut cara ubah data akunmu:

1. Buka halaman 'Profil/u'

2. Klik ikon pensil dan ubah data yang kamu inginkan

3. Klik 'Ganti foto' untuk mengganti foto profilmu. Kalau belum upload foto, klik 'Unggah foto'

Penting!
• Pastikan email dan nomor handphone baru belum pernah terdaftar di Nebeng

Setelah perubahan data berhasil dilakukan, maka akan ada waktu tunggu untuk bisa memperbarui kembali.''';

      case 'delete_account':
        return '''Saya ingin menghapus akun ini karena saya punya akun lain

Kamu, bisa mengganti nomor telepon di akun ini dengan nomor Nebeng yang ingin kamu gunakan. Anda tidak bisa dikembalikan lagi. Namun jika kamu yakin untuk tetap menghapus akunmu, silakan ikuti salah satu dari langkah berikut ini:

• buka menu Profil. Atur akun Hapus akun

Penting!

Sebelum menghapus akun, kamu perlu memperhatikan hal-hal berikut ini:

• Pastikan tidak ada lagi transaksi atau tanggungán yang sedang berjalan di akun yang ingin kamu hapus, seperti Order Nebeng. Jika ada, mohon selesaikan transaksi terlebih dahulu agar bermohonan kamu dapat kami proses.''';

      case 'change_language':
        return '''Kamu dapat mengganti bahasa di aplikasi Nebeng kamu dengan melakukan langkah berikut:

Pilih 'Profil' pada beranda aplikasi

• Pilih 'Pilihan Bahasa'

Bahasa
[Dropdown menu showing Bahasa]

• Pilih bahasa yang kamu inginkan.

Bahasa
[Dropdown menu showing:
English
Indonesia]

• Pilih bahasa yang kamu inginkan.''';

      case 'blocked_account':
        return '''Nebeng berdedikasi untuk menciptakan lingkungan yang aman dan nyaman untuk seluruh Pengguna dan Mitra Nebeng. Oleh karena itu, apabila akun Nebeng yang terindikasi adanya aktivitas kecurangan atau penyalahgunaan aplikasi Nebeng akan dibatutkan. Hal ini termasuk namun tidak terbatas pada:

• Pelecehan dalam bentuk apapun

• Pembatalan akun lebih dari satu.

• Berbagi akun dengan orang lain. dan/atau

• Pembatalan pesanan yang tidak wajar.

Apabila kamu mendapatkan notifikasi bahwa ada masalah pada akunmu, dan kamu merasa tidak melakukan aktivitas seperti yang disebutkan di atas, laporkan kepada kami dengan menekan tombol 'Kirim laporan' lalu isi form yang tersedia.''';

      case 'refund_process':
        return '''• Jika pesanan dibatalkan oleh mitra dana akan otomatis dikembalikan ke rekening Anda.

• Proses refund akan memakan waktu 1-3 hari kerja setelah permintaan refund diterima.

• Anda akan menerima notifikasi ketika refund sedang diproses dan setelah dana dikembalikan.''';

      case 'refund_policy':
        return '''Refund tidak berlaku dalam situasi berikut:

• Pesanan sudah selesai sesuai kesepakatan dan layanan telah diberikan.

• Anda mengajukan refund sebelum perjalanan dimulai.

• Kesalahan pada pihak customer, seperti memberikan alamat yang salah.''';

      default:
        return 'Konten tidak tersedia.';
    }
  }

  bool _hasReportButton() {
    return [
      'accident',
      'fraud',
      'harassment',
      'blocked_account',
      'refund_process'
    ].contains(widget.type);
  }

  bool _hasChatButton() {
    return ['left_item_motor', 'left_item_car', 'harassment', 'fraud']
        .contains(widget.type);
  }

  void _handleReport() {
    // TODO: Implement report functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fitur kirim laporan akan segera tersedia')),
    );
  }

  void _handleChat() {
    // TODO: Implement chat with CS functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Fitur chat dengan CS akan segera tersedia')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getContent(),
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Masih memerlukan bantuan?',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (_hasReportButton()) ...[
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _handleReport,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E3A8A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Kirim Laporan',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                      if (_hasReportButton() && _hasChatButton())
                        const SizedBox(width: 12),
                      if (_hasChatButton()) ...[
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _handleChat,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E3A8A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Chat dengan CS',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                      if (!_hasReportButton() && !_hasChatButton()) ...[
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _handleReport,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E3A8A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Kirim Laporan',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(
                top: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Apakah artikel ini membantu?',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _isHelpful = true;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Terima kasih atas feedback Anda!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: Icon(
                        _isHelpful == true
                            ? Icons.thumb_up
                            : Icons.thumb_up_outlined,
                        color: _isHelpful == true
                            ? const Color(0xFF1E3A8A)
                            : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _isHelpful = false;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Terima kasih atas feedback Anda!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: Icon(
                        _isHelpful == false
                            ? Icons.thumb_down
                            : Icons.thumb_down_outlined,
                        color: _isHelpful == false
                            ? const Color(0xFF1E3A8A)
                            : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
