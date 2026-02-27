import '../services/shared/chat_service.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Helper untuk create conversation (untuk testing atau dipanggil dari booking flow)
class ChatHelper {
  static final ChatService _chatService = ChatService();

  /// Ensure photo URL is absolute
  static String? _getFullPhotoUrl(String? photo) {
    if (photo == null || photo.isEmpty) return null;

    // If already full URL, return as is
    if (photo.startsWith('http://') || photo.startsWith('https://')) {
      return photo;
    }

    // Build full URL
    final baseUrl = ApiService.baseUrl;
    final cleanPhoto = photo.startsWith('/') ? photo : '/$photo';
    return '$baseUrl$cleanPhoto';
  }

  /// Create conversation antara customer dan mitra setelah booking
  /// Dipanggil dari BookingController atau setelah booking sukses
  static Future<String?> createConversationAfterBooking({
    required int rideId,
    required String bookingType, // 'motor', 'mobil', 'barang', 'titip'
    required Map<String, dynamic> customerData, // {id, name, photo, phone}
    required Map<String, dynamic> mitraData, // {id, name, photo, phone}
  }) async {
    try {
      // Fetch fresh user photos from backend to ensure they're up-to-date
      String? customerPhotoUrl = _getFullPhotoUrl(customerData['photo']);
      String? mitraPhotoUrl = _getFullPhotoUrl(mitraData['photo']);

      // Try to fetch from backend if photo is missing or incomplete
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('api_token');

        if (token != null) {
          // Fetch customer photo from backend
          if (customerPhotoUrl == null || customerPhotoUrl.isEmpty) {
            try {
              final customerFromApi =
                  await ApiService.getUserById(customerData['id'], token);
              final photoFromApi = customerFromApi['photo_url'] as String?;
              if (photoFromApi != null && photoFromApi.isNotEmpty) {
                customerPhotoUrl = _getFullPhotoUrl(photoFromApi);
                print(
                    '✅ Fetched customer photo from backend: $customerPhotoUrl');
              }
            } catch (e) {
              print('⚠️ Could not fetch customer photo: $e');
            }
          }

          // Fetch mitra photo from backend
          if (mitraPhotoUrl == null || mitraPhotoUrl.isEmpty) {
            try {
              final mitraFromApi =
                  await ApiService.getUserById(mitraData['id'], token);
              final photoFromApi = mitraFromApi['photo_url'] as String?;
              if (photoFromApi != null && photoFromApi.isNotEmpty) {
                mitraPhotoUrl = _getFullPhotoUrl(photoFromApi);
                print('✅ Fetched mitra photo from backend: $mitraPhotoUrl');
              }
            } catch (e) {
              print('⚠️ Could not fetch mitra photo: $e');
            }
          }
        }
      } catch (e) {
        print('⚠️ Error fetching photos from backend: $e');
      }

      final conversationId = await _chatService.createConversation(
        rideId: rideId,
        bookingType: bookingType,
        customerId: customerData['id'],
        customerName: customerData['name'] ?? 'Customer',
        customerPhoto: customerPhotoUrl,
        customerPhone: customerData['phone'],
        mitraId: mitraData['id'],
        mitraName: mitraData['name'] ?? 'Mitra',
        mitraPhoto: mitraPhotoUrl,
        mitraPhone: mitraData['phone'],
      );

      print('✅ Conversation created: $conversationId');
      print('   Customer photo: $customerPhotoUrl');
      print('   Mitra photo: $mitraPhotoUrl');
      return conversationId;
    } catch (e) {
      print('❌ Error creating conversation: $e');
      return null;
    }
  }

  /// Test function - Create dummy conversation untuk testing
  /// Panggil ini dari UI untuk testing chat
  static Future<String?> createTestConversation({
    required int currentUserId,
    required String currentUserName,
    required String currentUserRole,
  }) async {
    try {
      final conversationId = await _chatService.createConversation(
        rideId: 999, // Dummy ride ID
        bookingType: 'motor',
        customerId: currentUserRole == 'customer' ? currentUserId : 100,
        customerName:
            currentUserRole == 'customer' ? currentUserName : 'Test Customer',
        customerPhoto: null,
        customerPhone:
            currentUserRole == 'customer' ? '081234567890' : '081111111111',
        mitraId: currentUserRole == 'mitra' ? currentUserId : 200,
        mitraName: currentUserRole == 'mitra' ? currentUserName : 'Test Mitra',
        mitraPhoto: null,
        mitraPhone:
            currentUserRole == 'mitra' ? '081234567890' : '082222222222',
      );

      print('✅ Test conversation created: $conversationId');
      return conversationId;
    } catch (e) {
      print('❌ Error creating test conversation: $e');
      return null;
    }
  }
}
