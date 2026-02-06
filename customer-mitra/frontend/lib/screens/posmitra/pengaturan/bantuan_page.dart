import 'package:flutter/material.dart';

class BantuanPage extends StatefulWidget {
  const BantuanPage({Key? key}) : super(key: key);

  @override
  State<BantuanPage> createState() => _BantuanPageState();
}

class _BantuanPageState extends State<BantuanPage> {
  int? expandedIndex;

  final List<Map<String, dynamic>> faqList = [
    {
      'question': 'Bagaimana cara menambah tebengan untuk motor?',
      'answer':
          'Silahkan Anda pilih ikon motor, selanjutnya Anda akan diarahkan menuju halaman tambah tebengan motor. Silahkan Anda isikan formulir yang ada dengan data tebengan Anda seperti:',
      'details': [
        'Lokasi Awal',
        'Lokasi Tujuan',
        'Tanggal Keberangkatan',
        'Jam Keberangkatan',
      ],
      'footer':
          'Setelah itu Anda pilih Selanjutnya. Anda akan diarahkan menuju halaman detail informas tebengan yang telah dibuat. Silahkan pilih Buat tebengan untuk membuat tebengan motor, selanjutnya tunggu waktu tebengan untuk mulai mengantarkan si penebeng.',
    },
    {
      'question': 'Bagaimana cara menambah tebengan untuk mobil?',
      'answer':
          'Silahkan Anda pilih ikon mobil, selanjutnya Anda akan diarahkan menuju halaman tambah tebengan mobil. Silahkan Anda isikan formulir yang ada dengan data tebengan Anda seperti:',
      'details': [
        'Lokasi Awal',
        'Lokasi Tujuan',
        'Tanggal Keberangkatan',
        'Jam Keberangkatan',
      ],
      'footer':
          'Setelah itu Anda pilih Selanjutnya. Anda akan diarahkan menuju halaman detail informas tebengan yang telah dibuat. Silahkan pilih Buat tebengan untuk membuat tebengan mobil, selanjutnya tunggu waktu tebengan untuk mulai mengantarkan si penebeng.',
    },
    {
      'question': 'Bagaimana cara menambah tebengan untuk barang?',
      'answer':
          'Silahkan Anda pilih ikon barang, selanjutnya Anda akan diarahkan menuju halaman tambah tebengan barang. Silahkan Anda isikan formulir yang ada dengan data tebengan Anda seperti:',
      'details': [
        'Lokasi Awal',
        'Lokasi Tujuan',
        'Tanggal Keberangkatan',
        'Jam Keberangkatan',
      ],
      'footer':
          'Setelah itu Anda pilih Selanjutnya. Anda akan diarahkan menuju halaman detail informas tebengan yang telah dibuat. Silahkan pilih Buat tebengan untuk membuat tebengan barang, selanjutnya tunggu waktu tebengan untuk mulai mengantarkan barang.',
    },
    {
      'question': 'Bagaimana cara melakukan penarikan saldo?',
      'answer':
          'Menarik saldo dari aplikasi Nebeng kini semakin mudah. Hanya dengan beberapa langkah sederhana, Anda bisa menyelesaikan pencairan. Anda langsung ke rekening bank. Cara Menarik Saldo di Aplikasi Nebeng dengan Mudah:',
      'details': [
        'Buka tarik saldo',
        'Masukkan jumlah yang diinginkan',
        'Masukan pilih "lanjut"',
        'terakhir  masukan pin anda dan penarikan saldo anda berhasil',
      ],
      'footer': '',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF212121)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Bantuan',
          style: TextStyle(
            color: Color(0xFF212121),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: faqList.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final faq = faqList[index];
          final isExpanded = expandedIndex == index;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE0E0E0),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                InkWell(
                  onTap: () {
                    setState(() {
                      expandedIndex = isExpanded ? null : index;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            faq['question'],
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF212121),
                            ),
                          ),
                        ),
                        Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_up
                              : Icons.chevron_right,
                          color: const Color(0xFF9E9E9E),
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                ),
                if (isExpanded) ...[
                  const Divider(height: 1, color: Color(0xFFE0E0E0)),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          faq['answer'],
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF424242),
                            height: 1.5,
                          ),
                        ),
                        if (faq['details'] != null &&
                            (faq['details'] as List).isNotEmpty) ...[
                          const SizedBox(height: 12),
                          ...List.generate(
                            (faq['details'] as List).length,
                            (detailIndex) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '• ',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF424242),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      faq['details'][detailIndex],
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF424242),
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        if (faq['footer'] != null &&
                            (faq['footer'] as String).isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            faq['footer'],
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF424242),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}