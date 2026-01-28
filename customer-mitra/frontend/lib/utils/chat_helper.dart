import '../services/chat_service.dart';

/// Helper untuk create conversation (untuk testing atau dipanggil dari booking flow)
class ChatHelper {
  static final ChatService _chatService = ChatService();

  /// Create conversation antara customer dan mitra setelah booking
  /// Dipanggil dari BookingController atau setelah booking sukses
  static Future<String?> createConversationAfterBooking({
    required int rideId,
    required String bookingType, // 'motor', 'mobil', 'barang', 'titip'
    required Map<String, dynamic> customerData, // {id, name, photo}
    required Map<String, dynamic> mitraData, // {id, name, photo}
  }) async {
    try {
      final conversationId = await _chatService.createConversation(
        rideId: rideId,
        bookingType: bookingType,
        customerId: customerData['id'],
        customerName: customerData['name'] ?? 'Customer',
        customerPhoto: customerData['photo'],
        mitraId: mitraData['id'],
        mitraName: mitraData['name'] ?? 'Mitra',
        mitraPhoto: mitraData['photo'],
      );

      print('✅ Conversation created: $conversationId');
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
        mitraId: currentUserRole == 'mitra' ? currentUserId : 200,
        mitraName: currentUserRole == 'mitra' ? currentUserName : 'Test Mitra',
        mitraPhoto: null,
      );

      print('✅ Test conversation created: $conversationId');
      return conversationId;
    } catch (e) {
      print('❌ Error creating test conversation: $e');
      return null;
    }
  }
}
