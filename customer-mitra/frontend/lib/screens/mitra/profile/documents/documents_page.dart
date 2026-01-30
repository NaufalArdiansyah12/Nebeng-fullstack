import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../services/api_service.dart';
import 'edit_ktp_page.dart';
import 'edit_sim_page.dart';
import 'edit_skck_page.dart';
import 'edit_bank_page.dart';

class DocumentsPage extends StatefulWidget {
  const DocumentsPage({Key? key}) : super(key: key);

  @override
  State<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends State<DocumentsPage> {
  bool isLoading = true;
  Map<String, dynamic>? verificationStatus;

  @override
  void initState() {
    super.initState();
    _loadVerificationStatus();
  }

  Future<void> _loadVerificationStatus() async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');

      if (token != null) {
        final result = await ApiService.getMitraVerificationStatus(token);
        print('=== Verification Status Response ===');
        print('Full result: $result');
        if (result['success'] == true) {
          print('Data: ${result['data']}');
          print('KTP Status: ${result['data']?['ktp']?['status']}');
          print('KTP Photo: ${result['data']?['ktp']?['photo']}');
          print('SIM Status: ${result['data']?['sim']?['status']}');
          print('SKCK Status: ${result['data']?['skck']?['status']}');
          print('Bank Status: ${result['data']?['bank']?['status']}');
          setState(() {
            verificationStatus = result['data'];
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading verification status: $e');
      setState(() => isLoading = false);
    }
  }

  String _getDocumentStatus(String? status) {
    print('Document status value: "$status"'); // Debug
    // Handle null value that comes as string "null" from API
    if (status == null || status.isEmpty || status == 'null') {
      return 'Belum di-upload';
    }
    switch (status.toLowerCase()) {
      case 'approved':
        return 'Sudah di-upload';
      case 'pending':
        return 'Menunggu verifikasi';
      case 'rejected':
        return 'Ditolak';
      default:
        return 'Belum di-upload';
    }
  }

  Color _getStatusColor(String? status) {
    // Handle null value that comes as string "null" from API
    if (status == null || status.isEmpty || status == 'null') {
      return Colors.grey;
    }
    switch (status.toLowerCase()) {
      case 'approved':
        return const Color(0xFF00D4AA);
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  bool _canEdit(String? status) {
    // Can only edit if approved (document has been verified)
    // Cannot edit if pending (waiting for verification) or rejected
    // Handle null value that comes as string "null" from API
    return status != null &&
        status.isNotEmpty &&
        status != 'null' &&
        status.toLowerCase() == 'approved';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Dokumen',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadVerificationStatus,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildDocumentItem(
                    context,
                    'KTP',
                    verificationStatus?['ktp']?['status'],
                    verificationStatus?['ktp']?['photo'],
                    () => _navigateToEdit(context, 'ktp'),
                  ),
                  const SizedBox(height: 16),
                  _buildDocumentItem(
                    context,
                    'SIM',
                    verificationStatus?['sim']?['status'],
                    verificationStatus?['sim']?['photo'],
                    () => _navigateToEdit(context, 'sim'),
                  ),
                  const SizedBox(height: 16),
                  _buildDocumentItem(
                    context,
                    'SKCK',
                    verificationStatus?['skck']?['status'],
                    verificationStatus?['skck']?['photo'],
                    () => _navigateToEdit(context, 'skck'),
                  ),
                  const SizedBox(height: 16),
                  _buildDocumentItem(
                    context,
                    'Rekening Bank',
                    verificationStatus?['bank']?['status'],
                    verificationStatus?['bank']?['photo'],
                    () => _navigateToEdit(context, 'bank'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDocumentItem(
    BuildContext context,
    String title,
    String? status,
    String? photoUrl,
    VoidCallback onEdit,
  ) {
    final statusText = _getDocumentStatus(status);
    final statusColor = _getStatusColor(status);
    final canEdit = _canEdit(status);

    // Fix photo URL to include /storage/ prefix if needed
    String? fullPhotoUrl;
    if (photoUrl != null && photoUrl.isNotEmpty) {
      if (photoUrl.startsWith('http')) {
        fullPhotoUrl = photoUrl;
      } else if (photoUrl.startsWith('/')) {
        fullPhotoUrl = '${ApiService.baseUrl}$photoUrl';
      } else {
        // Add /storage/ prefix for relative paths
        fullPhotoUrl = '${ApiService.baseUrl}/storage/$photoUrl';
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Document thumbnail
          Container(
            width: 80,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.shade100,
              image: fullPhotoUrl != null
                  ? DecorationImage(
                      image: NetworkImage(fullPhotoUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: fullPhotoUrl == null
                ? Icon(Icons.image, color: Colors.grey.shade400)
                : null,
          ),
          const SizedBox(width: 16),
          // Document info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 14,
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Edit button or status badge
          if (canEdit)
            OutlinedButton(
              onPressed: onEdit,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1A43BF),
                side: const BorderSide(color: Color(0xFF1A43BF)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              ),
              child: const Text(
                'Ubah',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else if (status == null || status.isEmpty || status == 'null')
            OutlinedButton(
              onPressed: onEdit,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1A43BF),
                side: const BorderSide(color: Color(0xFF1A43BF)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              ),
              child: const Text(
                'Upload',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status.toLowerCase() == 'pending'
                    ? 'Proses'
                    : status.toLowerCase() == 'rejected'
                        ? 'Ditolak'
                        : 'Belum Upload',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _navigateToEdit(BuildContext context, String docType) async {
    // Prepare data based on document type from the nested structure
    Map<String, dynamic>? documentData;

    if (verificationStatus != null) {
      switch (docType) {
        case 'ktp':
          documentData = {
            'ktp_photo': verificationStatus?['ktp']?['photo'],
            'ktp_status': verificationStatus?['ktp']?['status'],
            // Add other fields if needed from user profile or other source
          };
          break;
        case 'sim':
          documentData = {
            'sim_photo': verificationStatus?['sim']?['photo'],
            'sim_status': verificationStatus?['sim']?['status'],
          };
          break;
        case 'skck':
          documentData = {
            'skck_photo': verificationStatus?['skck']?['photo'],
            'skck_status': verificationStatus?['skck']?['status'],
          };
          break;
        case 'bank':
          documentData = {
            'bank_account_photo': verificationStatus?['bank']?['photo'],
            'bank_status': verificationStatus?['bank']?['status'],
          };
          break;
      }
    }

    Widget page;
    switch (docType) {
      case 'ktp':
        page = EditKtpPage(existingData: documentData);
        break;
      case 'sim':
        page = EditSimPage(existingData: documentData);
        break;
      case 'skck':
        page = EditSkckPage(existingData: documentData);
        break;
      case 'bank':
        page = EditBankPage(existingData: documentData);
        break;
      default:
        return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );

    if (result == true) {
      _loadVerificationStatus();
    }
  }
}
